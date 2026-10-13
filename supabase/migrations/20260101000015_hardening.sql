-- =========================================================================
-- Durcissement : règles de suppression de compte, anti-triche vote, et
-- signalement de contenu.
--
-- Contexte : la suppression de compte (RGPD/App Store/Play Store) doit
-- réellement fonctionner. Or toute ligne dont la contrainte de clé
-- étrangère vers profiles(id) n'a pas de règle ON DELETE explicite bloque
-- la suppression avec une erreur Postgres peu lisible pour l'utilisateur
-- final. Ce fichier applique la distinction :
--   - "appartient au compte" (vidéo, like, commentaire...) -> déjà en
--     cascade depuis la migration initiale, rien à changer ici.
--   - "trace d'un événement passé" (qui a voté, qui a gagné, qui a créé
--     un défi, l'auteur d'une transaction...) -> on garde la ligne mais on
--     détache la référence à la personne (ON DELETE SET NULL). L'écriture
--     comptable ou l'historique de vote survit à la personne qui l'a
--     produite.
-- =========================================================================

-- -------------------------------------------------------------------------
-- challenges.creator_id — actuellement "not null ... on delete cascade" :
-- si le créateur supprime son compte, supprimer tout le défi effacerait
-- aussi les participations et votes des AUTRES joueurs, qui n'ont rien
-- demandé. On garde le défi (creator_id devient null, l'UI doit savoir
-- afficher "Créateur supprimé") et on détache seulement la référence.
-- -------------------------------------------------------------------------
alter table challenges alter column creator_id drop not null;
alter table challenges drop constraint challenges_creator_id_fkey;
alter table challenges
  add constraint challenges_creator_id_fkey
  foreign key (creator_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- challenge_votes.voter_id / participant_id — actuellement
-- "not null ... on delete cascade" : supprimer un vote parce que
-- l'électeur ou le participant a supprimé son compte fausserait
-- votes_count (déjà incrémenté ailleurs) pour tout le monde. On détache la
-- référence, le vote lui-même (et son effet sur le compteur) reste.
-- -------------------------------------------------------------------------
alter table challenge_votes alter column voter_id drop not null;
alter table challenge_votes drop constraint challenge_votes_voter_id_fkey;
alter table challenge_votes
  add constraint challenge_votes_voter_id_fkey
  foreign key (voter_id) references profiles (id) on delete set null;

alter table challenge_votes alter column participant_id drop not null;
alter table challenge_votes drop constraint challenge_votes_participant_id_fkey;
alter table challenge_votes
  add constraint challenge_votes_participant_id_fkey
  foreign key (participant_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- transactions.user_id — actuellement "not null ... on delete cascade" :
-- une transaction est une écriture comptable. Elle doit survivre à la
-- personne pour que le grand livre (somme des transactions == solde
-- affiché avant suppression) reste vérifiable après coup, et pour toute
-- obligation comptable/anti-fraude. Supprimer les transactions d'un compte
-- supprimé reviendrait à effacer une preuve d'audit.
-- -------------------------------------------------------------------------
alter table transactions alter column user_id drop not null;
alter table transactions drop constraint transactions_user_id_fkey;
alter table transactions
  add constraint transactions_user_id_fkey
  foreign key (user_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- challenges.opponent_id / record_holder_id / winner_id / sponsor_id —
-- déjà nullables mais sans règle de suppression explicite (donc "no
-- action" par défaut : Postgres refuserait la suppression du compte tant
-- qu'une de ces colonnes le référence). Même raisonnement que winner_id :
-- ce sont des résultats/rôles ponctuels sur un défi qui doit rester
-- consultable même si la personne concernée n'existe plus.
-- -------------------------------------------------------------------------
alter table challenges drop constraint challenges_opponent_id_fkey;
alter table challenges
  add constraint challenges_opponent_id_fkey
  foreign key (opponent_id) references profiles (id) on delete set null;

alter table challenges drop constraint challenges_record_holder_id_fkey;
alter table challenges
  add constraint challenges_record_holder_id_fkey
  foreign key (record_holder_id) references profiles (id) on delete set null;

alter table challenges drop constraint challenges_winner_id_fkey;
alter table challenges
  add constraint challenges_winner_id_fkey
  foreign key (winner_id) references profiles (id) on delete set null;

alter table challenges drop constraint challenges_sponsor_id_fkey;
alter table challenges
  add constraint challenges_sponsor_id_fkey
  foreign key (sponsor_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- notifications.actor_id — qui a déclenché la notif (ex : "X a aimé ta
-- vidéo"). Si X supprime son compte, la notification elle-même doit rester
-- lisible ("Quelqu'un a aimé ta vidéo" plutôt qu'une notif cassée), donc
-- SET NULL et pas CASCADE — ce n'est pas la notif du destinataire qui doit
-- disparaître.
-- -------------------------------------------------------------------------
alter table notifications drop constraint notifications_actor_id_fkey;
alter table notifications
  add constraint notifications_actor_id_fkey
  foreign key (actor_id) references profiles (id) on delete set null;

-- -------------------------------------------------------------------------
-- organizations.owner_id / messages.sender_id — actuellement "not null"
-- sans règle de suppression (bloquerait la suppression du compte). Ces
-- tables ne sont pas encore exposées dans l'app (organizations : aucune UI
-- ; messages : cascade déjà via conversations dans la grande majorité des
-- cas), mais on corrige quand même pour que la suppression de compte ne
-- puisse jamais échouer avec une erreur Postgres imprévisible plus tard.
-- -------------------------------------------------------------------------
alter table organizations alter column owner_id drop not null;
alter table organizations drop constraint organizations_owner_id_fkey;
alter table organizations
  add constraint organizations_owner_id_fkey
  foreign key (owner_id) references profiles (id) on delete set null;

alter table messages alter column sender_id drop not null;
alter table messages drop constraint messages_sender_id_fkey;
alter table messages
  add constraint messages_sender_id_fkey
  foreign key (sender_id) references profiles (id) on delete set null;

-- =========================================================================
-- Anti-triche : empêcher qu'un joueur vote pour lui-même.
--
-- Une policy RLS `with check (voter_id != participant_id)` existe déjà sur
-- l'insert direct (20260101000001_rls_policies.sql), mais elle ne protège
-- que l'écriture directe via PostgREST. Le vote passe en réalité par la
-- fonction SECURITY DEFINER `vote_for_participant`, qui insère elle-même
-- dans challenge_votes et n'est PAS soumise au `with check` de la table
-- (SECURITY DEFINER exécute avec les droits du propriétaire de la
-- fonction). Rien n'empêchait donc aujourd'hui d'appeler
-- vote_for_participant(défi, soi-même). On corrige à deux niveaux :
-- une contrainte CHECK au niveau table (dernière ligne de défense, vraie
-- même si un futur code contourne la fonction), et un rejet explicite dans
-- la fonction elle-même (message clair pour l'utilisateur au lieu d'une
-- violation de contrainte brute).
-- =========================================================================
alter table challenge_votes
  add constraint challenge_votes_no_self_vote
  check (voter_id is null or participant_id is null or voter_id != participant_id);

create or replace function vote_for_participant(p_challenge_id uuid, p_participant_id uuid)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if v_user_id = p_participant_id then
    raise exception 'Tu ne peux pas voter pour toi-même.' using errcode = 'P0001';
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

-- -------------------------------------------------------------------------
-- Décision documentée : un créateur PEUT participer à et remporter son
-- propre défi (Battle/Challenge/King). C'est un choix délibéré, pas un
-- oubli : join_challenge() ne l'a jamais interdit, et le code existant
-- (ex. écran de création) ne présuppose pas le contraire. Économiquement
-- ce n'est pas exploitable pour se créer de l'argent : le créateur paie
-- son propre droit d'entrée comme les autres, qui alimente la cagnotte
-- commune, et il ne peut gagner que ce que la cagnotte contient réellement
-- (voir resolve_expired_challenges). Au pire, un créateur seul participant
-- récupère exactement ce qu'il a lui-même mis, sans gain. Si ce choix
-- devait changer, il faudrait l'appliquer dans join_challenge() (rejeter
-- p_challenge_id dont creator_id = auth.uid()), pas seulement côté UI.
-- -------------------------------------------------------------------------

-- =========================================================================
-- content_reports — modération : signalement de vidéo, commentaire ou
-- profil par un utilisateur, traité ensuite par un compte role = 'admin'.
-- =========================================================================
create table content_reports (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('video', 'comment', 'profile')),
  target_id uuid not null,
  -- Trace, pas appartenance : si le signaleur supprime son compte, le
  -- signalement doit rester pour la modération, seule l'identité s'efface.
  reporter_id uuid references profiles (id) on delete set null,
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'actioned', 'dismissed')),
  resolved_by uuid references profiles (id) on delete set null,
  resolution_note text,
  created_at timestamptz default now(),
  resolved_at timestamptz
);

create index idx_content_reports_status on content_reports (status);
create index idx_content_reports_target on content_reports (target_type, target_id);
create index idx_content_reports_reporter on content_reports (reporter_id);

alter table content_reports enable row level security;

create policy "Users can report content as themselves"
on content_reports for insert
with check (auth.uid() = reporter_id);

create policy "Users can view own reports"
on content_reports for select
using (auth.uid() = reporter_id);

create policy "Admins can view all reports"
on content_reports for select
using (
  exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);

create policy "Admins can resolve reports"
on content_reports for update
using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'))
with check (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
