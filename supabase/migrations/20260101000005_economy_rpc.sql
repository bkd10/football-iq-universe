-- Économie (Ballons) — PARTIE 4.2 / 7 de la spécification.
--
-- Choix d'implémentation : la spec décrit des Edge Functions TypeScript/Deno
-- (`award-coins`, `spend-coins`). Elles sont implémentées ici comme des
-- fonctions Postgres SECURITY DEFINER, appelées directement via
-- `supabase.rpc(...)` — même garantie anti-triche (le solde et les
-- transactions ne sont modifiables que côté serveur, et `auth.uid()` est lu
-- depuis le JWT vérifié par PostgREST, jamais fourni par le client), sans
-- dépendre d'un runtime Deno qu'on ne peut ni exécuter ni tester ici. À
-- migrer vers de vraies Edge Functions si une logique plus riche devient
-- nécessaire (appel à une régie pub externe, rate limiting applicatif...).

-- =========================================================================
-- award_coins — attribue des Ballons pour une action gratuite validée
-- =========================================================================
create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date := current_date;
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
    select count(*) into v_count_today
    from transactions
    where user_id = v_user_id and reason = 'post_video' and created_at >= v_today;

    if v_count_today >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

  elsif p_reason = 'ad_watched' then
    select count(*) into v_count_today
    from transactions
    where user_id = v_user_id and reason = 'ad_watched' and created_at >= v_today;

    if v_count_today >= coalesce((v_economy ->> 'max_ad_watched_per_day')::integer, 5) then
      raise exception 'Limite quotidienne de publicités atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'ad_watched')::integer, 30);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function award_coins(text, uuid) to authenticated;

-- =========================================================================
-- spend_coins — débite des Ballons pour une action payante, montant
-- toujours dérivé de app_config.economy (jamais du client)
-- =========================================================================
create or replace function spend_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_amount integer default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_expected_amount integer;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select value into v_economy from app_config where key = 'economy';

  v_expected_amount := case p_reason
    when 'join_challenge' then coalesce((v_economy ->> 'join_challenge_cost')::integer, 20)
    when 'join_battle' then coalesce((v_economy ->> 'join_battle_min_cost')::integer, 50)
    when 'create_challenge' then coalesce((v_economy ->> 'create_challenge_cost')::integer, 200)
    when 'boost_video' then coalesce((v_economy ->> 'boost_video_cost')::integer, 100)
    when 'custom_badge' then coalesce((v_economy ->> 'custom_badge_cost')::integer, 300)
    when 'special_effect' then coalesce((v_economy ->> 'special_effect_cost')::integer, 50)
    else null
  end;

  if v_expected_amount is null then
    raise exception 'Raison de dépense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  -- `p_amount` n'est accepté qu'à titre défensif : s'il est fourni, il doit
  -- correspondre au tarif serveur, sous peine de rejet.
  if p_amount is not null and p_amount <> v_expected_amount then
    raise exception 'Montant invalide pour cette action.' using errcode = 'P0001';
  end if;

  update profiles
  set coins = coins - v_expected_amount
  where id = v_user_id and coins >= v_expected_amount
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'spend', -v_expected_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_spent', v_expected_amount);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function spend_coins(text, uuid, integer) to authenticated;
