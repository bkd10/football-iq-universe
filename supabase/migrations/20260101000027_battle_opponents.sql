-- Battle : choisir son adversaire parmi les joueurs qu'on suit ou qui nous
-- suivent, ou laisser le hasard choisir.
--
-- Corrige aussi l'erreur « column "is_banned" does not exist » : les RPC
-- de la migration 0024 (create_battle, vote_for_participant) filtrent les
-- comptes bannis, mais la base de production n'avait pas reçu la colonne
-- (migration 0022 non appliquée). On l'ajoute ici si elle manque.

alter table profiles add column if not exists is_banned boolean not null default false;
alter table profiles add column if not exists banned_at timestamptz;
alter table profiles add column if not exists ban_reason text;

-- -------------------------------------------------------------------------
-- 1. Suggestions d'adversaires : abonnés et abonnements du joueur
-- -------------------------------------------------------------------------
create or replace function battle_opponent_suggestions(p_query text default null)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  i_follow boolean,
  follows_me boolean
) as $$
declare
  v_user_id uuid := auth.uid();
  v_query text := nullif(lower(trim(both '@ ' from coalesce(p_query, ''))), '');
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  return query
  with related as (
    select f.following_id as pid, true as i_follow, false as follows_me
    from follows f where f.follower_id = v_user_id
    union all
    select f.follower_id, false, true
    from follows f where f.following_id = v_user_id
  ), merged as (
    select pid, bool_or(r.i_follow) as i_follow, bool_or(r.follows_me) as follows_me
    from related r group by pid
  )
  select p.id, p.username, p.display_name, p.avatar_url, m.i_follow, m.follows_me
  from merged m
  join profiles p on p.id = m.pid
  where p.id != v_user_id
    and not p.is_banned
    and (
      v_query is null
      or lower(p.username) like '%' || v_query || '%'
      or lower(coalesce(p.display_name, '')) like '%' || v_query || '%'
    )
  order by (m.i_follow and m.follows_me) desc, p.username
  limit 50;
end;
$$ language plpgsql stable security definer set search_path = public;

revoke execute on function battle_opponent_suggestions(text) from public, anon;
grant execute on function battle_opponent_suggestions(text) to authenticated;

-- -------------------------------------------------------------------------
-- 2. create_battle : nouvelle option « adversaire aléatoire »
-- -------------------------------------------------------------------------
drop function if exists create_battle(text, text, integer, uuid, timestamptz, text);

create or replace function create_battle(
  p_title text,
  p_rules text,
  p_stake integer,
  p_video_id uuid,
  p_end_date timestamptz,
  p_opponent_username text default null,
  p_random_opponent boolean default false
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

  if p_random_opponent then
    -- Adversaire aléatoire : un vrai joueur (non banni) qui a au moins une
    -- vidéo publiée, pour qu'il puisse relever la Battle.
    select p.id into v_opponent_id
    from profiles p
    where p.id != v_user_id
      and p.role = 'player'
      and not p.is_banned
      and exists (select 1 from videos v where v.user_id = p.id and v.status = 'active')
    order by random()
    limit 1;

    if v_opponent_id is null then
      raise exception 'Aucun adversaire disponible pour le moment.' using errcode = 'P0001';
    end if;
  elsif p_opponent_username is not null and trim(p_opponent_username) != '' then
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

revoke execute on function create_battle(text, text, integer, uuid, timestamptz, text, boolean) from public, anon;
grant execute on function create_battle(text, text, integer, uuid, timestamptz, text, boolean) to authenticated;
