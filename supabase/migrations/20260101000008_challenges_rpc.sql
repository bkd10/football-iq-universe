-- Défis (Battle/Challenge/King/World/Sponsored) — PARTIE 4.2/8.3.
-- Comme pour l'économie et les missions, les Edge Functions décrites par
-- la spec (`resolve-challenge`) sont implémentées en fonctions Postgres
-- SECURITY DEFINER : même garantie anti-triche, sans dépendre d'un
-- runtime Deno qu'on ne peut pas exécuter/tester ici.

-- =========================================================================
-- join_challenge — débite l'entrée et inscrit une vidéo du joueur
-- =========================================================================
create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_entry_cost integer;
  v_status text;
  v_end_date timestamptz;
  v_max_participants integer;
  v_participants_count integer;
  v_video_owner uuid;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select entry_cost, status, end_date, max_participants, participants_count
    into v_entry_cost, v_status, v_end_date, v_max_participants, v_participants_count
  from challenges where id = p_challenge_id
  for update;

  if v_status is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_status != 'active' or now() > v_end_date then
    raise exception 'Ce défi n''accepte plus de participations.' using errcode = 'P0001';
  end if;

  if v_max_participants is not null and v_participants_count >= v_max_participants then
    raise exception 'Ce défi est complet.' using errcode = 'P0001';
  end if;

  select user_id into v_video_owner from videos where id = p_video_id;
  if v_video_owner is null or v_video_owner != v_user_id then
    raise exception 'Tu ne peux participer qu''avec l''une de tes propres vidéos.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = v_user_id
  ) then
    raise exception 'Tu participes déjà à ce défi.' using errcode = 'P0001';
  end if;

  if v_entry_cost > 0 then
    update profiles set coins = coins - v_entry_cost
    where id = v_user_id and coins >= v_entry_cost
    returning coins into v_new_balance;

    if v_new_balance is null then
      raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
    end if;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_user_id, 'spend', -v_entry_cost, 'coins', v_new_balance, 'join_challenge',
      'challenge', p_challenge_id
    );
  end if;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (p_challenge_id, v_user_id, p_video_id);

  update challenges set participants_count = participants_count + 1
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function join_challenge(uuid, uuid) to authenticated;

-- =========================================================================
-- create_challenge — débite le coût de création et crée le défi
-- =========================================================================
create or replace function create_challenge(
  p_title text,
  p_description text,
  p_type text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_pool integer default 0,
  p_max_participants integer default null,
  p_record_unit text default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_create_cost integer;
  v_entry_cost integer;
  v_new_balance integer;
  v_challenge_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  -- World (hebdomadaire officiel) et Sponsored (marques) ne sont pas
  -- créables par les joueurs — voir PARTIE 8.3.
  if p_type not in ('battle', 'challenge', 'king') then
    raise exception
      'Seuls les défis Battle, Challenge et King peuvent être créés par les joueurs.'
      using errcode = 'P0001';
  end if;

  if p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_create_cost := coalesce((v_economy ->> 'create_challenge_cost')::integer, 200);
  v_entry_cost := case p_type
    when 'battle' then coalesce((v_economy ->> 'join_battle_min_cost')::integer, 50)
    else coalesce((v_economy ->> 'join_challenge_cost')::integer, 20)
  end;

  update profiles set coins = coins - v_create_cost
  where id = v_user_id and coins >= v_create_cost
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    max_participants, record_unit, end_date, status
  ) values (
    v_user_id, p_title, p_description, p_type, p_category, v_entry_cost, p_prize_pool,
    p_max_participants, p_record_unit, p_end_date, 'active'
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

grant execute on function create_challenge(
  text, text, text, timestamptz, text, integer, integer, text
) to authenticated;

-- =========================================================================
-- vote_for_participant — un vote par défi et par utilisateur
-- =========================================================================
create or replace function vote_for_participant(p_challenge_id uuid, p_participant_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select status into v_status from challenges where id = p_challenge_id;
  if v_status is null then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;

  if v_status not in ('active', 'voting') then
    raise exception 'Ce défi n''accepte plus de votes.' using errcode = 'P0001';
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

grant execute on function vote_for_participant(uuid, uuid) to authenticated;

-- =========================================================================
-- resolve_expired_challenges — détermine le(s) gagnant(s), distribue le
-- prize_pool, attribue les Stars, notifie. PAS de grant à `authenticated` :
-- opération système, appelée par pg_cron ou manuellement en service_role.
-- =========================================================================
create or replace function resolve_expired_challenges()
returns integer as $$
declare
  v_challenge record;
  v_winner_user_id uuid;
  v_new_balance integer;
  v_resolved_count integer := 0;
  v_rank integer;
  v_participation record;
begin
  for v_challenge in
    select * from challenges
    where status = 'active' and end_date < now()
  loop
    v_winner_user_id := null;

    if v_challenge.type = 'king' then
      v_winner_user_id := v_challenge.record_holder_id;
    else
      select user_id into v_winner_user_id
      from challenge_participations
      where challenge_id = v_challenge.id
      order by votes_count desc, created_at asc
      limit 1;

      v_rank := 1;
      for v_participation in
        select id from challenge_participations
        where challenge_id = v_challenge.id
        order by votes_count desc, created_at asc
      loop
        update challenge_participations set rank = v_rank where id = v_participation.id;
        v_rank := v_rank + 1;
      end loop;
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
      where id = v_winner_user_id;

      insert into notifications (user_id, type, title, body, reference_type, reference_id)
      values (
        v_winner_user_id, 'challenge_won', 'Défi remporté !',
        'Tu as remporté "' || v_challenge.title || '" 🏆',
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

-- Planification automatique (nécessite l'extension pg_cron — Database >
-- Extensions dans le dashboard Supabase) :
--   select cron.schedule('resolve-expired-challenges', '*/15 * * * *',
--     'select resolve_expired_challenges();');
-- En attendant, un admin peut l'appeler manuellement depuis le SQL Editor.

-- =========================================================================
-- Durcissement RLS : `join_challenge`/`create_challenge` gèrent maintenant
-- le débit de Ballons de façon atomique. Les anciennes policies INSERT
-- directes (20260101000001_rls_policies.sql) permettaient de créer un défi
-- ou de rejoindre une participation sans payer — elles sont supprimées ;
-- seules les fonctions SECURITY DEFINER ci-dessus peuvent désormais écrire
-- dans `challenges`/`challenge_participations`.
drop policy if exists "Users can create challenges as themselves" on challenges;
drop policy if exists "Users can join a challenge as themselves" on challenge_participations;
