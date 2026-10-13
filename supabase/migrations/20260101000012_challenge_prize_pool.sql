-- Cagnotte réelle pour les Battles/Défis/King créés par un joueur, et
-- correction d'un bug d'étiquetage dans l'historique du portefeuille.
--
-- Avant ce correctif, `prize_pool` restait à 0 pour tout défi créé par un
-- joueur (aucun champ dans l'écran de création ne permet de le fixer) :
-- le gagnant ne touchait donc jamais les Ballons des perdants, qui étaient
-- simplement perdus. Désormais, chaque droit d'entrée payé via
-- `join_challenge` alimente `prize_pool`, qui est intégralement reversé au
-- vainqueur par `resolve_expired_challenges` (logique déjà existante,
-- inchangée). Le coût de création (200 Ballons, payé une fois par le
-- créateur) n'entre jamais dans la cagnotte — seuls les droits d'entrée des
-- participants la constituent.
--
-- Corrige aussi : la transaction générée par `join_challenge` utilisait
-- toujours la raison `join_challenge`, même pour un défi de type `battle`,
-- alors que `join_battle` existe déjà comme raison distincte (libellé
-- "Participation à une Battle" côté Wallet) mais n'était jamais produite.
create or replace function join_challenge(p_challenge_id uuid, p_video_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_type text;
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

  select type, entry_cost, status, end_date, max_participants, participants_count
    into v_type, v_entry_cost, v_status, v_end_date, v_max_participants, v_participants_count
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
      v_user_id, 'spend', -v_entry_cost, 'coins', v_new_balance,
      case when v_type = 'battle' then 'join_battle' else 'join_challenge' end,
      'challenge', p_challenge_id
    );

    -- Le droit d'entrée rejoint la cagnotte : c'est ce qui sera reversé en
    -- intégralité au vainqueur par `resolve_expired_challenges`.
    update challenges set prize_pool = prize_pool + v_entry_cost
    where id = p_challenge_id;
  end if;

  insert into challenge_participations (challenge_id, user_id, video_id)
  values (p_challenge_id, v_user_id, p_video_id);

  update challenges set participants_count = participants_count + 1
  where id = p_challenge_id;

  return jsonb_build_object('joined', true);
end;
$$ language plpgsql security definer set search_path = public;
