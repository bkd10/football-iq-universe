-- =========================================================================
-- Vérification sécurité en 25 points (novembre 2026)
--
-- 1. Limite de requêtes : un compte ne peut plus envoyer des centaines de
--    commentaires, messages, likes, abonnements, vidéos ou signalements en
--    quelques secondes (spam, robot). Les limites sont larges : un joueur
--    normal ne les atteint jamais.
-- 2. Fichiers : plus personne ne peut lister le contenu des dossiers des
--    autres joueurs (avant : n'importe qui pouvait obtenir la liste de tous
--    les fichiers envoyés). Les vidéos restent visibles par leur lien.
-- 3. Liens de vidéos et d'avatars : ils doivent pointer vers le stockage
--    Supabase du jeu, pas vers un site extérieur qui imiterait le chemin.
-- =========================================================================

create schema if not exists private;

-- -------------------------------------------------------------------------
-- 1. Limite de requêtes
-- -------------------------------------------------------------------------
create table if not exists private.rate_limit_hits (
  user_id uuid not null,
  action text not null,
  bucket timestamptz not null,
  hits integer not null default 0,
  primary key (user_id, action, bucket)
);

-- Compteur par minute et par jour, par compte et par action. Paramètres du
-- trigger : action, maximum par minute, maximum par jour. Les appels sans
-- compte (cron, admin SQL, service_role) ne sont pas limités.
create or replace function private.enforce_rate_limit()
returns trigger as $$
declare
  v_uid uuid := auth.uid();
  v_action text := tg_argv[0];
  v_per_minute integer := tg_argv[1]::integer;
  v_per_day integer := tg_argv[2]::integer;
  v_minute integer;
  v_day integer;
begin
  if v_uid is null then
    return new;
  end if;

  insert into private.rate_limit_hits as h (user_id, action, bucket, hits)
  values (v_uid, v_action || ':min', date_trunc('minute', now()), 1)
  on conflict (user_id, action, bucket) do update set hits = h.hits + 1
  returning hits into v_minute;

  if v_minute > v_per_minute then
    raise exception 'Trop d''actions en peu de temps. Réessaie dans une minute.'
      using errcode = 'P0001';
  end if;

  insert into private.rate_limit_hits as h (user_id, action, bucket, hits)
  values (v_uid, v_action || ':day', date_trunc('day', now()), 1)
  on conflict (user_id, action, bucket) do update set hits = h.hits + 1
  returning hits into v_day;

  if v_day > v_per_day then
    raise exception 'Limite du jour atteinte. Réessaie demain.'
      using errcode = 'P0001';
  end if;

  -- Ménage : à la première action d'une nouvelle minute, on efface les
  -- compteurs de ce joueur vieux de plus de 2 jours.
  if v_minute = 1 then
    delete from private.rate_limit_hits
    where user_id = v_uid and bucket < now() - interval '2 days';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public, private;

revoke all on function private.enforce_rate_limit() from public, anon, authenticated;

-- action, max par minute, max par jour
drop trigger if exists rate_limit_comments on comments;
create trigger rate_limit_comments before insert on comments
for each row execute function private.enforce_rate_limit('comment', '10', '300');

drop trigger if exists rate_limit_messages on messages;
create trigger rate_limit_messages before insert on messages
for each row execute function private.enforce_rate_limit('message', '20', '500');

drop trigger if exists rate_limit_likes on likes;
create trigger rate_limit_likes before insert on likes
for each row execute function private.enforce_rate_limit('like', '60', '2000');

drop trigger if exists rate_limit_follows on follows;
create trigger rate_limit_follows before insert on follows
for each row execute function private.enforce_rate_limit('follow', '30', '500');

drop trigger if exists rate_limit_videos on videos;
create trigger rate_limit_videos before insert on videos
for each row execute function private.enforce_rate_limit('video', '5', '30');

drop trigger if exists rate_limit_reports on content_reports;
create trigger rate_limit_reports before insert on content_reports
for each row execute function private.enforce_rate_limit('report', '5', '50');

drop trigger if exists rate_limit_scout_interests on scout_interests;
create trigger rate_limit_scout_interests before insert on scout_interests
for each row execute function private.enforce_rate_limit('scout_interest', '20', '200');

drop trigger if exists rate_limit_challenges on challenges;
create trigger rate_limit_challenges before insert on challenges
for each row execute function private.enforce_rate_limit('challenge', '3', '20');

-- -------------------------------------------------------------------------
-- 2. Fichiers : chacun ne liste que son propre dossier
-- -------------------------------------------------------------------------
-- Les buckets sont « publics » : les vidéos et avatars restent lisibles par
-- leur lien direct sans cette règle. Elle ne servait qu'à LISTER les
-- fichiers, ce qui permettait à n'importe qui d'obtenir la liste complète
-- des fichiers de tous les joueurs (y compris ceux retirés par la
-- modération). L'app ne liste que le dossier du joueur connecté
-- (suppression de compte).
drop policy if exists "Public read access to app buckets" on storage.objects;
drop policy if exists "Users can list their own files" on storage.objects;
create policy "Users can list their own files"
on storage.objects for select
using (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

-- -------------------------------------------------------------------------
-- 3. Liens vers le stockage du jeu uniquement
-- -------------------------------------------------------------------------
-- Avant : '%/storage/v1/object/public/videos/<id>/%' acceptait aussi
-- https://site-pirate.com/storage/v1/object/public/videos/<id>/... .
-- Le lien doit maintenant commencer par l'adresse d'un projet Supabase
-- (ou l'instance locale de développement).
create or replace function private.is_app_storage_url(p_url text, p_bucket text, p_user_id uuid)
returns boolean as $$
  select p_url ~ (
    '^(https://[a-z0-9]+\.supabase\.co|http://(127\.0\.0\.1|localhost):54321)'
    || '/storage/v1/object/public/' || p_bucket || '/' || p_user_id::text || '/[^/?#]+$'
  );
$$ language sql immutable set search_path = public;

create or replace function check_video_urls()
returns trigger as $$
begin
  if not private.is_app_storage_url(new.video_url, 'videos', new.user_id) then
    raise exception 'URL de vidéo invalide.' using errcode = 'P0001';
  end if;
  if new.thumbnail_url is not null
     and not private.is_app_storage_url(new.thumbnail_url, 'thumbnails', new.user_id) then
    raise exception 'URL de miniature invalide.' using errcode = 'P0001';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public, private;

create or replace function check_avatar_url()
returns trigger as $$
begin
  if new.avatar_url is not null
     and new.avatar_url is distinct from old.avatar_url
     and not private.is_app_storage_url(new.avatar_url, 'avatars', new.id) then
    raise exception 'URL d''avatar invalide.' using errcode = 'P0001';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public, private;

drop trigger if exists trigger_check_avatar_url on profiles;
create trigger trigger_check_avatar_url
before update of avatar_url on profiles
for each row
execute function check_avatar_url();
