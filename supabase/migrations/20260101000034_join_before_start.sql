-- Inscriptions ouvertes dès la création du Challenge (demande de Tom,
-- 11/11/2026) : un joueur notifié peut participer tout de suite, sans
-- attendre la date de début. Les votes, eux, restent bloqués jusqu'à la
-- date de début (vote_for_participant inchangé).
-- Seul changement par rapport à 0024 : le contrôle « pas encore commencé »
-- est retiré de join_challenge.
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

revoke execute on function join_challenge(uuid, uuid) from public, anon;
grant execute on function join_challenge(uuid, uuid) to authenticated;
