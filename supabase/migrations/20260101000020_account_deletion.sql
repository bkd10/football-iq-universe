-- =========================================================================
-- Suppression réelle de compte (obligation légale — RGPD, exigence
-- App Store/Play Store). "Supprimer réellement, pas marquer supprimé" :
-- une colonne `deleted_at`/`is_deleted` laisserait la ligne `auth.users`
-- (et donc l'adresse e-mail) définitivement prise, empêchant la personne
-- de jamais recréer un compte avec la même adresse, et laissant ses
-- données réellement en base malgré la demande de suppression.
--
-- Choix d'implémentation : une fonction Postgres SECURITY DEFINER qui fait
-- `delete from auth.users where id = auth.uid()`, plutôt qu'un appel à
-- l'API d'administration Supabase (`auth.admin.deleteUser`, qui nécessite
-- la clé service-role et donc une Edge Function). Ce choix suit le même
-- principe que le reste du projet (RPC Postgres SECURITY DEFINER plutôt
-- que Deno, voir README) et s'appuie sur une contrainte déjà en place :
-- `profiles.id references auth.users(id) on delete cascade`
-- (20260101000000_initial_schema.sql). Supprimer la ligne `auth.users`
-- cascade donc automatiquement vers `profiles`, puis vers tout ce qui a
-- été mis en cascade sur `profiles.id` (vidéos, likes, commentaires,
-- participations, badges, missions, notifications...), et détache (SET
-- NULL) tout ce qui doit survivre comme trace (transactions, votes,
-- défis créés/gagnés — voir 20260101000015_hardening.sql).
--
-- Limite connue, à documenter pour le développeur qui reprend le projet :
-- le rôle propriétaire de cette fonction doit avoir le droit de DELETE sur
-- `auth.users` — c'est le cas par défaut pour le rôle `postgres` sur la
-- plupart des projets Supabase actuels, mais si ce n'est pas le cas sur le
-- projet de production (permissions Supabase parfois durcies), l'appel
-- échouera avec une erreur de permission explicite plutôt que de
-- supprimer partiellement le compte (tout se passe dans une seule
-- transaction : soit tout est supprimé, soit rien ne l'est). Solution de
-- repli documentée si besoin : Edge Function côté serveur appelant
-- `auth.admin.deleteUser` avec la clé service-role.
--
-- Nettoyage du Storage : les fichiers (vidéos, miniatures, avatars) sont
-- rangés sous `<bucket>/<user_id>/...` (convention déjà utilisée par les
-- policies RLS de storage.objects, voir
-- 20260101000004_storage_and_reactions.sql). On supprime ici les lignes
-- `storage.objects` correspondantes avant de supprimer le compte, pour
-- qu'aucune vidéo ou avatar d'un compte supprimé ne reste accessible par
-- URL publique ou signée.
-- =========================================================================
create or replace function delete_my_account()
returns void as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  delete from storage.objects
  where bucket_id = any (array['videos', 'thumbnails', 'avatars'])
    and (storage.foldername(name)) [1] = v_user_id::text;

  delete from auth.users where id = v_user_id;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function delete_my_account() to authenticated;
