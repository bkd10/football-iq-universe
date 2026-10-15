-- =========================================================================
-- Règles v2 (décidées par Tom le 15/10/2026)
--
-- Jetons (Ballons) :
--   - plus aucun Ballon pour la simple connexion quotidienne (ni bonus de
--     série) : se connecter sans jouer ne doit rien rapporter. La série de
--     jours et ses badges restent suivis ;
--   - plus de Ballon quand un Move est reproduit (des millions de
--     reproductions = des millions de Ballons gratuits) ;
--   - « regarder 3 vidéos » ne rapporte plus rien ;
--   - nouveau : regarder 20 vidéos EN ENTIER dans la journée = 30 Ballons,
--     une fois par jour. Le temps de visionnage est contrôlé par le serveur
--     (un robot ne peut pas aller plus vite que les vidéos).
--
-- Défis :
--   - Challenge : ouvert à tous, avec une date de début et une date de fin ;
--     on ne peut participer qu'entre les deux ;
--   - Battle : un contre un. Le créateur fixe les règles, la mise (en
--     Ballons) et éventuellement son adversaire. Les deux joueurs misent la
--     même somme, les autres utilisateurs votent, le gagnant remporte les
--     deux mises. Égalité ou adversaire absent : chacun est remboursé ;
--   - Monde (admin) et Sponsorisé (marque vérifiée) : inchangés, aucun
--     joueur ne peut en créer ;
--   - King : plus créable (aucun moyen de saisir un record).
--
-- Anti-triche des votes : pas de vote pour soi, pas de vote dans une
-- Battle à laquelle on participe, et seuls les comptes « réels » votent
-- (au moins une vidéo publiée, ou compte de plus de 24 h).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Connexion quotidienne : suivi de la série, sans Ballons
-- -------------------------------------------------------------------------
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
  v_today date;
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days, coins into v_last_login, v_streak, v_new_balance
    from profiles where id = v_user_id for update;

    if v_last_login is not null and v_today <= v_last_login then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    update profiles
    set last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id;

    insert into daily_missions (user_id, mission_date, login_completed)
    values (v_user_id, v_today, true)
    on conflict (user_id, mission_date)
    do update set login_completed = true;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

    return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', 0);

  elsif p_reason = 'post_video' then
    if p_reference_id is null or not exists (
      select 1 from videos
      where id = p_reference_id
        and user_id = v_user_id
        and created_at > now() - interval '24 hours'
    ) then
      raise exception 'Vidéo introuvable pour cette récompense.' using errcode = 'P0001';
    end if;

    if exists (
      select 1 from transactions
      where user_id = v_user_id and reason = 'post_video' and reference_id = p_reference_id
    ) then
      raise exception 'Récompense déjà reçue pour cette vidéo.' using errcode = 'P0001';
    end if;

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
    raise exception 'Les récompenses publicitaires ne sont pas encore disponibles.'
      using errcode = 'P0001';

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 2. Move reproduit : on garde le compteur, plus de Ballon
-- -------------------------------------------------------------------------
create or replace function handle_new_video()
returns trigger as $$
declare
  v_original_is_move boolean;
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    select coalesce(is_move, false) into v_original_is_move
    from videos where id = new.original_move_id;

    if coalesce(v_original_is_move, false) then
      update videos set reproductions_count = reproductions_count + 1
      where id = new.original_move_id;
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 3. « Regarder 3 vidéos » : compteur seulement, plus de Ballons
-- -------------------------------------------------------------------------
create or replace function increment_videos_watched(p_local_date date default null)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
  v_watched integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', false);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 4. 20 vidéos regardées en entier = 30 Ballons (une fois par jour)
--
-- L'app appelle `start_video_watch` quand une vidéo commence, puis
-- `complete_video_watch` quand elle arrive au bout. Le serveur exige que le
-- temps réellement écoulé couvre la durée de la vidéo, et que les
-- visionnages se suivent (on ne peut pas « regarder » 20 vidéos en même
-- temps) : 20 vidéos de 30 s demandent au moins 10 minutes réelles.
-- -------------------------------------------------------------------------
alter table daily_missions add column if not exists full_videos_watched integer not null default 0;
alter table daily_missions add column if not exists full_watch_rewarded boolean not null default false;
alter table daily_missions add column if not exists last_full_watch_at timestamptz;

-- Dans le schéma `private` : jamais exposé par l'API, et surtout pas vu
-- par PostgREST comme un second lien entre `videos` et `profiles` (ce qui
-- casserait la requête du feed).
create schema if not exists private;

create table if not exists private.video_watch_sessions (
  user_id uuid not null references profiles (id) on delete cascade,
  video_id uuid not null references videos (id) on delete cascade,
  watch_date date not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  primary key (user_id, video_id, watch_date)
);

revoke all on private.video_watch_sessions from public, anon, authenticated;

update app_config
set value = value || '{"full_watch_target": 20, "full_watch_reward": 30}'::jsonb
where key = 'economy';

create or replace function start_video_watch(p_video_id uuid, p_local_date date default null)
returns void as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  if not exists (
    select 1 from videos
    where id = p_video_id and status = 'active' and user_id != v_user_id
  ) then
    return;
  end if;

  -- Un visionnage pas encore terminé repart de zéro (l'utilisateur est
  -- revenu sur la vidéo) ; un visionnage terminé ne compte qu'une fois.
  insert into private.video_watch_sessions (user_id, video_id, watch_date, started_at)
  values (v_user_id, p_video_id, v_today, now())
  on conflict (user_id, video_id, watch_date)
  do update set started_at = now()
  where private.video_watch_sessions.completed_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function complete_video_watch(
  p_video_id uuid,
  p_duration_seconds numeric default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
  v_economy jsonb;
  v_target integer;
  v_reward integer;
  v_started_at timestamptz;
  v_video_duration integer;
  v_required numeric;
  v_last_full timestamptz;
  v_rewarded boolean;
  v_count integer;
  v_new_balance integer;
  v_awarded boolean := false;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);
  select value into v_economy from app_config where key = 'economy';
  v_target := coalesce((v_economy ->> 'full_watch_target')::integer, 20);
  v_reward := coalesce((v_economy ->> 'full_watch_reward')::integer, 30);

  select s.started_at, v.duration_seconds
    into v_started_at, v_video_duration
  from private.video_watch_sessions s
  join videos v on v.id = s.video_id
  where s.user_id = v_user_id
    and s.video_id = p_video_id
    and s.watch_date = v_today
    and s.completed_at is null
    and v.status = 'active';

  if v_started_at is null then
    return jsonb_build_object('counted', false, 'reason', 'no_session');
  end if;

  -- Durée de référence : celle enregistrée à la publication, sinon celle
  -- vue par l'appareil, toujours entre 5 et 60 secondes.
  v_required := least(greatest(coalesce(v_video_duration, p_duration_seconds, 5), 5), 60);

  insert into daily_missions (user_id, mission_date)
  values (v_user_id, v_today)
  on conflict (user_id, mission_date) do nothing;

  select last_full_watch_at, full_watch_rewarded
    into v_last_full, v_rewarded
  from daily_missions
  where user_id = v_user_id and mission_date = v_today
  for update;

  -- 1 seconde de tolérance pour les arrondis de l'appareil.
  if now() - greatest(v_started_at, coalesce(v_last_full, v_started_at))
     < make_interval(secs => v_required - 1) then
    return jsonb_build_object('counted', false, 'reason', 'too_fast');
  end if;

  update private.video_watch_sessions
  set completed_at = now()
  where user_id = v_user_id and video_id = p_video_id and watch_date = v_today;

  update daily_missions
  set full_videos_watched = full_videos_watched + 1,
      last_full_watch_at = now()
  where user_id = v_user_id and mission_date = v_today
  returning full_videos_watched into v_count;

  if v_count >= v_target and not v_rewarded then
    update profiles set coins = coins + v_reward
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions
    set full_watch_rewarded = true,
        coins_earned = coins_earned + v_reward
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', v_reward, 'coins', v_new_balance, 'daily_full_watch');

    v_awarded := true;
  end if;

  return jsonb_build_object(
    'counted', true,
    'full_videos_watched', v_count,
    'target', v_target,
    'reward_awarded', v_awarded,
    'reward', v_reward
  );
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function start_video_watch(uuid, date) from public, anon;
revoke execute on function complete_video_watch(uuid, numeric, date) from public, anon;
grant execute on function start_video_watch(uuid, date) to authenticated;
grant execute on function complete_video_watch(uuid, numeric, date) to authenticated;

-- -------------------------------------------------------------------------
-- 5. Challenge : date de début + date de fin. Seul « challenge » est
--    créable par un joueur ici (la Battle a sa propre fonction).
-- -------------------------------------------------------------------------
drop function if exists create_challenge(text, text, text, timestamptz, text, integer, integer, text, text);

create or replace function create_challenge(
  p_title text,
  p_description text,
  p_type text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_pool integer default 0,
  p_max_participants integer default null,
  p_record_unit text default null,
  p_prize_description text default null,
  p_start_date timestamptz default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_is_verified boolean;
  v_economy jsonb;
  v_create_cost integer;
  v_entry_cost integer;
  v_new_balance integer;
  v_challenge_id uuid;
  v_sponsor_name text;
  v_start timestamptz := greatest(coalesce(p_start_date, now()), now());
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_description, '')) > 1000 then
    raise exception 'La description est trop longue (1000 caractères max).' using errcode = 'P0001';
  end if;

  if v_start > now() + interval '30 days' then
    raise exception 'Un défi doit commencer dans les 30 prochains jours.' using errcode = 'P0001';
  end if;

  if p_end_date <= v_start + interval '1 hour' then
    raise exception 'La date de fin doit être au moins 1 heure après le début.' using errcode = 'P0001';
  end if;

  if p_end_date > v_start + interval '60 days' then
    raise exception 'Un défi ne peut pas durer plus de 60 jours.' using errcode = 'P0001';
  end if;

  if p_max_participants is not null and (p_max_participants < 2 or p_max_participants > 10000) then
    raise exception 'Nombre de participants invalide.' using errcode = 'P0001';
  end if;

  select role, is_verified, coalesce(display_name, username)
    into v_role, v_is_verified, v_sponsor_name
  from profiles where id = v_user_id;

  if p_type = 'sponsored' then
    if v_role != 'brand' then
      raise exception 'Seul un compte marque peut créer un défi sponsorisé.'
        using errcode = 'P0001';
    end if;
    if not coalesce(v_is_verified, false) then
      raise exception
        'Ton compte marque doit être vérifié avant de pouvoir publier un défi sponsorisé.'
        using errcode = 'P0001';
    end if;
    if p_prize_description is null or trim(p_prize_description) = '' then
      raise exception 'La description du prix est requise pour un défi sponsorisé.'
        using errcode = 'P0001';
    end if;

    insert into challenges (
      creator_id, title, description, type, category, entry_cost, prize_pool,
      prize_currency, prize_description, sponsor_id, sponsor_name,
      max_participants, start_date, end_date, status
    ) values (
      v_user_id, trim(p_title), p_description, 'sponsored', p_category, 0, 0,
      'real', left(p_prize_description, 500), v_user_id, v_sponsor_name,
      p_max_participants, v_start, p_end_date, 'active'
    )
    returning id into v_challenge_id;

    return jsonb_build_object('challenge_id', v_challenge_id);
  end if;

  if p_type = 'battle' then
    raise exception 'Une Battle se crée depuis l''écran Battle (1 contre 1).'
      using errcode = 'P0001';
  end if;

  if p_type != 'challenge' then
    raise exception 'Les défis Monde sont réservés à Football IQ.'
      using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_create_cost := coalesce((v_economy ->> 'create_challenge_cost')::integer, 200);
  v_entry_cost := coalesce((v_economy ->> 'join_challenge_cost')::integer, 20);

  update profiles set coins = coins - v_create_cost
  where id = v_user_id and coins >= v_create_cost
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    max_participants, start_date, end_date, status
  ) values (
    v_user_id, trim(p_title), p_description, 'challenge', p_category, v_entry_cost, 0,
    p_max_participants, v_start, p_end_date, 'active'
  )
  returning id into v_challenge_id;

  insert into transactions (
    user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
  ) values (
    v_user_id, 'spend', -v_create_cost, 'coins', v_new_balance, 'create_challenge',
    'challenge', v_challenge_id
  );

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function create_challenge(text, text, text, timestamptz, text, integer, integer, text, text, timestamptz) from public, anon;
grant execute on function create_challenge(text, text, text, timestamptz, text, integer, integer, text, text, timestamptz) to authenticated;

-- -------------------------------------------------------------------------
-- 6. Battle : 1 contre 1, mise libre, règles libres
-- -------------------------------------------------------------------------
alter table notifications drop constraint if exists notifications_type_check;
alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved',
    'moderation', 'battle_invite', 'battle_result'
  ));

update app_config
set value = value || '{"battle_min_stake": 10, "battle_max_stake": 10000}'::jsonb
where key = 'economy';

create or replace function create_battle(
  p_title text,
  p_rules text,
  p_stake integer,
  p_video_id uuid,
  p_end_date timestamptz,
  p_opponent_username text default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_min_stake integer;
  v_max_stake integer;
  v_opponent_id uuid;
  v_new_balance integer;
  v_challenge_id uuid;
  v_creator_name text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_rules, '')) > 1000 then
    raise exception 'Les règles sont trop longues (1000 caractères max).' using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_min_stake := coalesce((v_economy ->> 'battle_min_stake')::integer, 10);
  v_max_stake := coalesce((v_economy ->> 'battle_max_stake')::integer, 10000);

  if p_stake is null or p_stake < v_min_stake or p_stake > v_max_stake then
    raise exception 'La mise doit être entre % et % Ballons.', v_min_stake, v_max_stake
      using errcode = 'P0001';
  end if;

  if p_end_date < now() + interval '1 hour' or p_end_date > now() + interval '14 days' then
    raise exception 'Une Battle dure entre 1 heure et 14 jours.' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from videos
    where id = p_video_id and user_id = v_user_id and status = 'active'
  ) then
    raise exception 'Choisis une de tes propres vidéos.' using errcode = 'P0001';
  end if;

  if p_opponent_username is not null and trim(p_opponent_username) != '' then
    select id into v_opponent_id
    from profiles
    where lower(username) = lower(trim(both '@ ' from p_opponent_username))
      and not is_banned;

    if v_opponent_id is null then
      raise exception 'Joueur introuvable : %', p_opponent_username using errcode = 'P0001';
    end if;
    if v_opponent_id = v_user_id then
      raise exception 'Tu ne peux pas te défier toi-même.' using errcode = 'P0001';
    end if;
  end if;

  update profiles set coins = coins - p_stake
  where id = v_user_id and coins >= p_stake
  returning coins, coalesce(display_name, username) into v_new_balance, v_creator_name;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, entry_cost, prize_pool,
    opponent_id, max_participants, participants_count, start_date, end_date, status
  ) values (
    v_user_id, trim(p_title), coalesce(p_rules, ''), 'battle', p_stake, p_stake,
    v_opponent_id, 2, 1, now(), p_end_date, 'active'
  )
  returning id into v_challenge_id;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (v_challenge_id, v_user_id, p_video_id);

  insert into transactions (
    user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
  ) values (
    v_user_id, 'spend', -p_stake, 'coins', v_new_balance, 'join_battle',
    'challenge', v_challenge_id
  );

  if v_opponent_id is not null then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_opponent_id, 'battle_invite', 'On te défie ! ⚔️',
      v_creator_name || ' te lance une Battle : « ' || trim(p_title) || ' » (mise : '
        || p_stake || ' Ballons).',
      'challenge', v_challenge_id
    );
  end if;

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function create_battle(text, text, integer, uuid, timestamptz, text) from public, anon;
grant execute on function create_battle(text, text, integer, uuid, timestamptz, text) to authenticated;

-- -------------------------------------------------------------------------
-- 7. Participer : entre la date de début et la date de fin ; Battle
--    réservée à l'adversaire désigné (ou au premier venu s'il n'y en a pas)
-- -------------------------------------------------------------------------
create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_challenge record;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select * into v_challenge from challenges where id = p_challenge_id for update;

  if v_challenge.id is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_challenge.status != 'active' or now() > v_challenge.end_date then
    raise exception 'Ce défi n''accepte plus de participations.' using errcode = 'P0001';
  end if;

  if now() < v_challenge.start_date then
    raise exception 'Ce défi n''a pas encore commencé.' using errcode = 'P0001';
  end if;

  if v_challenge.max_participants is not null
     and v_challenge.participants_count >= v_challenge.max_participants then
    raise exception 'Ce défi est complet.' using errcode = 'P0001';
  end if;

  if v_challenge.type = 'battle'
     and v_challenge.opponent_id is not null
     and v_challenge.opponent_id != v_user_id then
    raise exception 'Cette Battle est réservée au joueur défié.' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from videos
    where id = p_video_id and user_id = v_user_id and status = 'active'
  ) then
    raise exception 'Tu ne peux participer qu''avec l''une de tes propres vidéos.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = v_user_id
  ) then
    raise exception 'Tu participes déjà à ce défi.' using errcode = 'P0001';
  end if;

  if v_challenge.entry_cost > 0 then
    update profiles set coins = coins - v_challenge.entry_cost
    where id = v_user_id and coins >= v_challenge.entry_cost
    returning coins into v_new_balance;

    if v_new_balance is null then
      raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_user_id, 'spend', -v_challenge.entry_cost, 'coins', v_new_balance,
      case when v_challenge.type = 'battle' then 'join_battle' else 'join_challenge' end,
      'challenge', p_challenge_id
    );

    update challenges set prize_pool = prize_pool + v_challenge.entry_cost
    where id = p_challenge_id;
  end if;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (p_challenge_id, v_user_id, p_video_id);

  update challenges
  set participants_count = participants_count + 1,
      opponent_id = case when type = 'battle' then coalesce(opponent_id, v_user_id) else opponent_id end
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 8. Votes protégés
-- -------------------------------------------------------------------------
create or replace function vote_for_participant(p_challenge_id uuid, p_participant_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_challenge record;
  v_account_age interval;
  v_has_video boolean;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if v_user_id = p_participant_id then
    raise exception 'Tu ne peux pas voter pour toi-même.' using errcode = 'P0001';
  end if;

  select * into v_challenge from challenges where id = p_challenge_id;
  if v_challenge.id is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_challenge.status not in ('active', 'voting') or now() > v_challenge.end_date then
    raise exception 'Ce défi n''accepte plus de votes.' using errcode = 'P0001';
  end if;

  if now() < v_challenge.start_date then
    raise exception 'Ce défi n''a pas encore commencé.' using errcode = 'P0001';
  end if;

  if v_challenge.type = 'battle' then
    if v_challenge.participants_count < 2 then
      raise exception 'Les votes ouvrent quand l''adversaire a relevé la Battle.'
        using errcode = 'P0001';
    end if;
    if exists (
      select 1 from challenge_participations
      where challenge_id = p_challenge_id and user_id = v_user_id
    ) then
      raise exception 'Les joueurs de la Battle ne votent pas.' using errcode = 'P0001';
    end if;
  end if;

  -- Seuls les vrais joueurs votent : au moins une vidéo publiée, ou un
  -- compte de plus de 24 h. Bloque les comptes créés à la chaîne pour
  -- truquer un vote.
  select now() - p.created_at,
         exists (select 1 from videos v where v.user_id = p.id and v.status = 'active')
    into v_account_age, v_has_video
  from profiles p
  where p.id = v_user_id and not p.is_banned;

  if v_account_age is null then
    raise exception 'Compte introuvable.' using errcode = 'P0001';
  end if;

  if not v_has_video and v_account_age < interval '24 hours' then
    raise exception 'Publie d''abord une vidéo pour pouvoir voter (ou attends 24 h).'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = p_participant_id
  ) then
    raise exception 'Ce participant n''existe pas dans ce défi.' using errcode = 'P0001';
  end if;

  insert into challenge_votes (challenge_id, voter_id, participant_id)
  values (p_challenge_id, v_user_id, p_participant_id);

  update challenge_participations
  set votes_count = votes_count + 1
  where challenge_id = p_challenge_id and user_id = p_participant_id;

  return jsonb_build_object('voted', true);
exception
  when unique_violation then
    raise exception 'Tu as déjà voté dans ce défi.' using errcode = 'P0001';
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 9. Fin des défis
--   - aucun vote : personne ne gagne, chacun récupère son droit d'entrée ;
--   - Battle sans adversaire, ou égalité : chacun récupère sa mise ;
--   - sinon le plus de votes gagne toute la cagnotte + 100 Stars.
-- -------------------------------------------------------------------------
create or replace function private.refund_participants(p_challenge_id uuid, p_reason text)
returns void as $$
declare
  v_challenge record;
  v_participation record;
  v_new_balance integer;
begin
  select * into v_challenge from challenges where id = p_challenge_id;
  if v_challenge.entry_cost <= 0 or v_challenge.prize_currency != 'coins' then
    return;
  end if;

  for v_participation in
    select user_id from challenge_participations where challenge_id = p_challenge_id
  loop
    update profiles set coins = coins + v_challenge.entry_cost
    where id = v_participation.user_id
    returning coins into v_new_balance;

    if v_new_balance is null then
      continue;
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_participation.user_id, 'earn', v_challenge.entry_cost, 'coins', v_new_balance,
      p_reason, 'challenge', p_challenge_id
    );

    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_participation.user_id,
      case when v_challenge.type = 'battle' then 'battle_result' else 'challenge_won' end,
      'Mise remboursée',
      '« ' || v_challenge.title || ' » se termine sans vainqueur : tes '
        || v_challenge.entry_cost || ' Ballons te sont rendus.',
      'challenge', p_challenge_id
    );
  end loop;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function private.refund_participants(uuid, text) from public, anon, authenticated;

create or replace function resolve_expired_challenges()
returns integer as $$
declare
  v_challenge record;
  v_winner_user_id uuid;
  v_top_votes integer;
  v_second_votes integer;
  v_new_balance integer;
  v_new_stars integer;
  v_resolved_count integer := 0;
  v_rank integer;
  v_participation record;
begin
  for v_challenge in
    select * from challenges
    where status = 'active' and end_date < now()
    for update
  loop
    v_winner_user_id := null;
    v_top_votes := null;
    v_second_votes := null;

    v_rank := 1;
    for v_participation in
      select id, user_id, votes_count from challenge_participations
      where challenge_id = v_challenge.id
      order by votes_count desc, created_at asc
    loop
      update challenge_participations set rank = v_rank where id = v_participation.id;
      if v_rank = 1 then
        v_winner_user_id := v_participation.user_id;
        v_top_votes := v_participation.votes_count;
      elsif v_rank = 2 then
        v_second_votes := v_participation.votes_count;
      end if;
      v_rank := v_rank + 1;
    end loop;

    if v_challenge.type = 'king' then
      v_winner_user_id := v_challenge.record_holder_id;
    elsif coalesce(v_top_votes, 0) = 0 then
      -- Aucun vote (ou aucun participant) : pas de vainqueur.
      v_winner_user_id := null;
    elsif v_challenge.type = 'battle'
          and (v_challenge.participants_count < 2 or v_top_votes = v_second_votes) then
      v_winner_user_id := null;
    end if;

    if v_winner_user_id is null and v_challenge.type != 'king' then
      perform private.refund_participants(v_challenge.id, 'challenge_refund');

      update challenges
      set status = case when v_challenge.type = 'battle' and v_challenge.participants_count < 2
                        then 'cancelled' else 'completed' end,
          winner_id = null,
          prize_pool = 0
      where id = v_challenge.id;

      v_resolved_count := v_resolved_count + 1;
      continue;
    end if;

    if v_winner_user_id is not null then
      if v_challenge.prize_pool > 0 and v_challenge.prize_currency = 'coins' then
        update profiles set coins = coins + v_challenge.prize_pool
        where id = v_winner_user_id
        returning coins into v_new_balance;

        insert into transactions (
          user_id, type, amount, currency, balance_after, reason,
          reference_type, reference_id
        ) values (
          v_winner_user_id, 'earn', v_challenge.prize_pool, 'coins', v_new_balance,
          'win_challenge', 'challenge', v_challenge.id
        );
      end if;

      update profiles
      set stars = stars + 100, challenges_won_count = challenges_won_count + 1
      where id = v_winner_user_id
      returning stars into v_new_stars;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_winner_user_id, 'earn', 100, 'stars', v_new_stars,
        'win_challenge', 'challenge', v_challenge.id
      );

      insert into notifications (user_id, type, title, body, reference_type, reference_id)
      values (
        v_winner_user_id,
        case when v_challenge.type = 'battle' then 'battle_result' else 'challenge_won' end,
        case when v_challenge.type = 'battle' then 'Battle gagnée ! ⚔️' else 'Défi remporté !' end,
        'Tu as remporté « ' || v_challenge.title || ' » 🏆',
        'challenge', v_challenge.id
      );
    end if;

    update challenges
    set status = 'completed', winner_id = v_winner_user_id
    where id = v_challenge.id;

    v_resolved_count := v_resolved_count + 1;
  end loop;

  return v_resolved_count;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function resolve_expired_challenges() from public, anon, authenticated;
