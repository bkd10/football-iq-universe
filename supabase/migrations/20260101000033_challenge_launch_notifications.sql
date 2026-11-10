-- Notification « Nouveau challenge » envoyée à TOUS les inscrits
-- (demande de Tom, 10/11/2026).
--
-- Dès qu'un Challenge est créé (Challenge joueur, défi officiel « Monde »
-- créé depuis le panneau admin, ou défi Sponsorisé), chaque compte inscrit
-- reçoit une notification dans l'appli (cloche du feed), sauf le créateur
-- et les comptes bannis. Les Battles (1 contre 1) ne notifient que
-- l'adversaire, comme avant.
--
-- admin_notify_challenge(id) permet à un admin de renvoyer la notification
-- pour un défi déjà créé (ex : créé avant l'installation de ce script).
-- Idempotent : peut être exécuté plusieurs fois.

alter table notifications drop constraint if exists notifications_type_check;
alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved',
    'moderation', 'battle_invite', 'battle_result', 'challenge_launched'
  ));

create or replace function private.broadcast_challenge_launch(p_challenge_id uuid)
returns integer as $$
declare
  v_challenge challenges%rowtype;
  v_count integer;
begin
  select * into v_challenge from challenges where id = p_challenge_id;
  if not found or v_challenge.type = 'battle' then
    return 0;
  end if;

  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  select
    p.id,
    'challenge_launched',
    'Nouveau challenge ! 🏆',
    '« ' || v_challenge.title || ' » est lancé : à toi de jouer !',
    'challenge',
    v_challenge.id
  from profiles p
  where p.id is distinct from v_challenge.creator_id
    and not coalesce(p.is_banned, false)
    -- pas de doublon si un admin renvoie la notification
    and not exists (
      select 1 from notifications n
      where n.user_id = p.id
        and n.type = 'challenge_launched'
        and n.reference_id = v_challenge.id
    );

  get diagnostics v_count = row_count;
  return v_count;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function private.broadcast_challenge_launch(uuid) from public, anon, authenticated;

create or replace function private.notify_challenge_launch()
returns trigger as $$
begin
  if new.type <> 'battle' then
    perform private.broadcast_challenge_launch(new.id);
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function private.notify_challenge_launch() from public, anon, authenticated;

drop trigger if exists trigger_notify_challenge_launch on challenges;
create trigger trigger_notify_challenge_launch
after insert on challenges
for each row execute function private.notify_challenge_launch();

-- Renvoi manuel par un admin (ne crée pas de doublon).
create or replace function admin_notify_challenge(p_challenge_id uuid)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
begin
  if not exists (select 1 from challenges where id = p_challenge_id) then
    raise exception 'Défi introuvable.' using errcode = 'P0001';
  end if;
  return jsonb_build_object('notified', private.broadcast_challenge_launch(p_challenge_id));
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function admin_notify_challenge(uuid) from public, anon;
grant execute on function admin_notify_challenge(uuid) to authenticated;

-- -------------------------------------------------------------------------
-- Fin automatique des défis : sans cette tâche planifiée, un Challenge
-- arrivé à sa date de fin n'est jamais clôturé (pas de gagnant, pas de
-- remboursement). Toutes les 15 minutes, comme prévu dans la migration
-- 0008 où elle n'était qu'en commentaire.
-- -------------------------------------------------------------------------
create extension if not exists pg_cron;
select cron.unschedule('resolve-expired-challenges')
where exists (select 1 from cron.job where jobname = 'resolve-expired-challenges');
select cron.schedule('resolve-expired-challenges', '*/15 * * * *', 'select public.resolve_expired_challenges()');
