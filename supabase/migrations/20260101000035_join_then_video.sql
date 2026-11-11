-- Participer d'abord, envoyer sa vidéo ensuite (demande de Tom, 11/11/2026).
--
-- Challenge (pas Battle) : le joueur valide sa participation sans vidéo,
-- l'entrée est débitée, et il a 48 h (au plus tard la fin du défi) pour
-- envoyer sa vidéo avec submit_challenge_video. Une notification lui
-- rappelle de l'envoyer. Tant qu'il n'a pas de vidéo, on ne peut pas voter
-- pour lui. Les Battles gardent la vidéo obligatoire à l'entrée.
-- Idempotent.

alter table challenge_participations alter column video_id drop not null;
alter table challenge_participations add column if not exists video_deadline timestamptz;

alter table notifications drop constraint if exists notifications_type_check;
alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved',
    'moderation', 'battle_invite', 'battle_result', 'challenge_launched',
    'challenge_video_due'
  ));

create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid default null)
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

  if v_challenge.max_participants is not null
     and v_challenge.participants_count >= v_challenge.max_participants then
    raise exception 'Ce défi est complet.' using errcode = 'P0001';
  end if;

  if v_challenge.type = 'battle'
     and v_challenge.opponent_id is not null
     and v_challenge.opponent_id != v_user_id then
    raise exception 'Cette Battle est réservée au joueur défié.' using errcode = 'P0001';
  end if;

  if p_video_id is null and v_challenge.type = 'battle' then
    raise exception 'Choisis une de tes propres vidéos.' using errcode = 'P0001';
  end if;

  if p_video_id is not null and not exists (
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

  insert into challenge_participations (challenge_id, user_id, video_id, video_deadline)
  values (
    p_challenge_id, v_user_id, p_video_id,
    case when p_video_id is null
      then least(now() + interval '48 hours', v_challenge.end_date) end
  );

  if p_video_id is null then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_user_id, 'challenge_video_due', 'Participation validée ✅',
      'Envoie ta vidéo pour « ' || v_challenge.title || ' » avant la date limite (48 h maximum).',
      'challenge', p_challenge_id
    );
  end if;

  update challenges
  set participants_count = participants_count + 1,
      opponent_id = case when type = 'battle' then coalesce(opponent_id, v_user_id) else opponent_id end
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function join_challenge(uuid, uuid) from public, anon;
grant execute on function join_challenge(uuid, uuid) to authenticated;

-- Envoi de la vidéo après l'inscription.
create or replace function submit_challenge_video(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_part record;
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select cp.id, cp.video_id, cp.video_deadline, c.status
    into v_part
  from challenge_participations cp
  join challenges c on c.id = cp.challenge_id
  where cp.challenge_id = p_challenge_id and cp.user_id = v_user_id
  for update of cp;

  if v_part.id is null then
    raise exception 'Tu ne participes pas à ce défi.' using errcode = 'P0001';
  end if;
  if v_part.video_id is not null then
    raise exception 'Ta vidéo est déjà envoyée.' using errcode = 'P0001';
  end if;
  if v_part.status <> 'active' or now() > v_part.video_deadline then
    raise exception 'Le délai pour envoyer ta vidéo est dépassé.' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from videos
    where id = p_video_id and user_id = v_user_id and status = 'active'
  ) then
    raise exception 'Tu ne peux participer qu''avec l''une de tes propres vidéos.'
      using errcode = 'P0001';
  end if;

  update challenge_participations set video_id = p_video_id where id = v_part.id;
  return jsonb_build_object('submitted', true);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function submit_challenge_video(uuid, uuid) from public, anon;
grant execute on function submit_challenge_video(uuid, uuid) to authenticated;

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

  if exists (
    select 1 from challenge_participations
    where challenge_id = p_challenge_id and user_id = p_participant_id and video_id is null
  ) then
    raise exception 'Ce joueur n''a pas encore envoyé sa vidéo.' using errcode = 'P0001';
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


revoke execute on function vote_for_participant(uuid, uuid) from public, anon;
grant execute on function vote_for_participant(uuid, uuid) to authenticated;
