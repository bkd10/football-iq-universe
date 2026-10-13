-- =========================================================================
-- Fuseau horaire local pour tout ce qui touche à "aujourd'hui" : série de
-- connexion (streak_days), missions quotidiennes, plafonds journaliers
-- (vidéos postées, publicités regardées).
--
-- Jusqu'ici `current_date` était évalué côté serveur Postgres (fuseau du
-- serveur, en pratique UTC). Un joueur qui se connecte à 23h50 heure de
-- Paris (été, UTC+2) le voit déjà comme le lendemain en UTC ; à l'inverse
-- quelqu'un à Los Angeles (UTC-7/-8) voit encore "hier" bien après minuit
-- chez lui. Résultat concret : une série de connexions peut se casser à
-- tort, ou un plafond quotidien peut se réinitialiser au mauvais moment —
-- "Une série perdue à tort est la façon la plus sûre de perdre un
-- utilisateur fidèle."
--
-- Correctif : chaque RPC concernée accepte maintenant un paramètre
-- optionnel `p_local_date`, la date calendaire calculée côté client à
-- partir de l'heure locale de l'appareil (`DateTime.now()`, pas `.toUtc()`)
-- plutôt que côté serveur. Si absent (rétrocompatibilité, ancien client),
-- on retombe sur `current_date` — comportement identique à avant, jamais
-- pire.
--
-- Pour les plafonds quotidiens (vidéos postées, publicités regardées), on
-- ne compte plus les lignes de `transactions` depuis "minuit" (ce qui
-- recastait de toute façon la date en timestamptz à minuit *serveur*,
-- réintroduisant le même bug même avec la bonne date) : on utilise un
-- compteur dédié sur la ligne `daily_missions` du jour local concerné, qui
-- est déjà la bonne unité de "jour" une fois `p_local_date` en place.
-- =========================================================================

alter table daily_missions add column if not exists posts_count integer default 0;
alter table daily_missions add column if not exists ads_watched_count integer default 0;

-- `create or replace function` ne remplace une fonction que si sa signature
-- (types de paramètres) est identique. Ajouter un 3e paramètre change la
-- signature : sans ce `drop`, l'ancienne version à 2 paramètres resterait
-- appelable en parallèle (et un vieux client mis en cache la trouverait
-- toujours), avec `current_date` serveur jamais corrigé.
drop function if exists award_coins(text, uuid);
drop function if exists increment_videos_watched();

create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date := coalesce(p_local_date, current_date);
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
  v_streak_bonus integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days into v_last_login, v_streak
    from profiles where id = v_user_id for update;

    if v_last_login = v_today then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    v_amount := coalesce((v_economy ->> 'daily_login_max')::integer, 20);

    v_streak_bonus := case
      when v_streak = 7 then coalesce((v_economy ->> 'streak_7_days_bonus')::integer, 50)
      when v_streak = 30 then coalesce((v_economy ->> 'streak_30_days_bonus')::integer, 200)
      else 0
    end;
    v_amount := v_amount + v_streak_bonus;

    update profiles
    set coins = coins + v_amount,
        last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, login_completed, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set login_completed = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

  elsif p_reason = 'post_video' then
    select coalesce(posts_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned, posts_count)
    values (v_user_id, v_today, true, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount,
                  posts_count = daily_missions.posts_count + 1;

  elsif p_reason = 'ad_watched' then
    select coalesce(ads_watched_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_ad_watched_per_day')::integer, 5) then
      raise exception 'Limite quotidienne de publicités atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'ad_watched')::integer, 30);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, coins_earned, ads_watched_count)
    values (v_user_id, v_today, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set coins_earned = daily_missions.coins_earned + v_amount,
                  ads_watched_count = daily_missions.ads_watched_count + 1;

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function award_coins(text, uuid, date) to authenticated;

create or replace function increment_videos_watched(p_local_date date default null)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := coalesce(p_local_date, current_date);
  v_watched integer;
  v_bonus_awarded boolean := false;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  if v_watched = 3 then
    update profiles set coins = coins + 5
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions set coins_earned = coins_earned + 5
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', 5, 'coins', v_new_balance, 'daily_videos_watched');

    v_bonus_awarded := true;
  end if;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', v_bonus_awarded);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function increment_videos_watched(date) to authenticated;
