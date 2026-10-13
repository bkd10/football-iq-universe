-- Storage RLS + ajustements liés aux réactions (likes/masterclass) et aux
-- vues vidéo, introduits par la Semaine 3-4 (upload, feed, interactions).

-- =========================================================================
-- storage.objects — lecture publique, écriture restreinte au dossier
-- <user_id>/... de l'utilisateur (convention utilisée par
-- lib/core/services/storage_service.dart)
-- =========================================================================

create policy "Public read access to app buckets"
on storage.objects for select
using (bucket_id = any (array['videos', 'thumbnails', 'avatars']));

create policy "Users can upload to their own folder"
on storage.objects for insert
with check (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

create policy "Users can update their own files"
on storage.objects for update
using (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

create policy "Users can delete their own files"
on storage.objects for delete
using (
  bucket_id = any (array['videos', 'thumbnails', 'avatars'])
  and (storage.foldername(name)) [1] = auth.uid()::text
);

-- =========================================================================
-- Un utilisateur n'a qu'UNE réaction par vidéo (UNIQUE(user_id, video_id)),
-- basculée via `upsert` côté client (like <-> masterclass). Le trigger
-- `handle_new_like`/`handle_remove_like` ne couvre que INSERT/DELETE : ce
-- trigger complète pour le cas UPDATE (changement de type sur upsert), afin
-- que likes_count/masterclass_count restent exacts.
-- =========================================================================
create or replace function handle_like_type_change()
returns trigger as $$
begin
  if new.type = old.type then
    return new;
  end if;

  if old.type = 'masterclass' then
    update videos set masterclass_count = greatest(masterclass_count - 1, 0)
    where id = old.video_id;
  else
    update videos set likes_count = greatest(likes_count - 1, 0)
    where id = old.video_id;
  end if;

  if new.type = 'masterclass' then
    update videos set masterclass_count = masterclass_count + 1
    where id = new.video_id;
  else
    update videos set likes_count = likes_count + 1
    where id = new.video_id;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_like_type_change
after update of type on likes
for each row
execute function handle_like_type_change();

-- =========================================================================
-- Comptage des vues + attribution de Stars au créateur (1 Star / 100 vues
-- — PARTIE 4.2/6). Fonction SECURITY DEFINER : le client appelle
-- exclusivement `increment_video_views`, jamais un UPDATE direct sur
-- `videos.views_count` ou `profiles.stars`. Sert de version SQL du futur
-- Edge Function `handle-video-view` tant que celui-ci n'est pas développé.
-- =========================================================================
create or replace function increment_video_views(p_video_id uuid)
returns void as $$
declare
  v_creator_id uuid;
  v_new_views integer;
begin
  update videos
  set views_count = views_count + 1
  where id = p_video_id
  returning user_id, views_count into v_creator_id, v_new_views;

  if v_creator_id is null then
    return;
  end if;

  if v_new_views % 100 = 0 then
    update profiles set stars = stars + 1 where id = v_creator_id;

    insert into transactions (
      user_id, type, amount, currency, reason, reference_type, reference_id
    ) values (
      v_creator_id, 'earn', 1, 'stars', 'video_views_milestone', 'video', p_video_id
    );
  end if;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function increment_video_views(uuid) to authenticated;
