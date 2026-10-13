-- Triggers et fonctions PostgreSQL — PARTIE 3.4 de la spécification.

-- =========================================================================
-- Mise à jour automatique du niveau selon les Stars (Rookie/Rising
-- Star/Prodigy/Legend — PARTIE 6.2). Ne dépend d'aucun appel client :
-- se déclenche dès que `stars` est modifié par une Edge Function.
-- =========================================================================
create or replace function update_user_level()
returns trigger as $$
begin
  new.level := case
    when new.stars >= 25000 then 'legend'
    when new.stars >= 5000 then 'prodigy'
    when new.stars >= 500 then 'rising_star'
    else 'rookie'
  end;
  return new;
end;
$$ language plpgsql;

create trigger trigger_update_level
before update of stars on profiles
for each row
execute function update_user_level();

-- =========================================================================
-- Compteurs de follows dénormalisés
-- =========================================================================
create or replace function handle_new_follow()
returns trigger as $$
begin
  update profiles set following_count = following_count + 1
  where id = new.follower_id;

  update profiles set followers_count = followers_count + 1
  where id = new.following_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_new_follow
after insert on follows
for each row
execute function handle_new_follow();

create or replace function handle_unfollow()
returns trigger as $$
begin
  update profiles set following_count = greatest(following_count - 1, 0)
  where id = old.follower_id;

  update profiles set followers_count = greatest(followers_count - 1, 0)
  where id = old.following_id;

  return old;
end;
$$ language plpgsql;

create trigger trigger_unfollow
after delete on follows
for each row
execute function handle_unfollow();

-- =========================================================================
-- Compteurs de likes dénormalisés sur videos
-- =========================================================================
create or replace function handle_new_like()
returns trigger as $$
begin
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

create trigger trigger_new_like
after insert on likes
for each row
execute function handle_new_like();

create or replace function handle_remove_like()
returns trigger as $$
begin
  if old.type = 'masterclass' then
    update videos set masterclass_count = greatest(masterclass_count - 1, 0)
    where id = old.video_id;
  else
    update videos set likes_count = greatest(likes_count - 1, 0)
    where id = old.video_id;
  end if;
  return old;
end;
$$ language plpgsql;

create trigger trigger_remove_like
after delete on likes
for each row
execute function handle_remove_like();

-- =========================================================================
-- Compteur de commentaires dénormalisé
-- =========================================================================
create or replace function handle_new_comment()
returns trigger as $$
begin
  update videos set comments_count = comments_count + 1
  where id = new.video_id;
  return new;
end;
$$ language plpgsql;

create trigger trigger_new_comment
after insert on comments
for each row
execute function handle_new_comment();

-- =========================================================================
-- Compteur de vidéos et de Moves créés par profil
-- =========================================================================
create or replace function handle_new_video()
returns trigger as $$
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    update videos set reproductions_count = reproductions_count + 1
    where id = new.original_move_id;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_new_video
after insert on videos
for each row
execute function handle_new_video();

-- =========================================================================
-- Provisionnement automatique du profil à la création d'un compte
-- (auth.users -> profiles). Les infos d'inscription (username, pays,
-- poste, pied fort) sont transmises via `data:` dans `supabase.auth.signUp`
-- et lues ici depuis raw_user_meta_data. Le bonus de bienvenue (Ballons)
-- est appliqué directement à la création : ce n'est pas une "récompense"
-- soumise à triche, juste le solde de départ d'un nouveau compte.
-- =========================================================================
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (
    id,
    username,
    display_name,
    country,
    position,
    preferred_foot,
    birth_date,
    coins
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'player_' || substr(new.id::text, 1, 8)),
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'country',
    new.raw_user_meta_data ->> 'position',
    coalesce(new.raw_user_meta_data ->> 'preferred_foot', 'droit'),
    nullif(new.raw_user_meta_data ->> 'birth_date', '')::date,
    500
  );

  insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
  values (new.id, 'earn', 500, 'coins', 500, 'welcome_bonus');

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function handle_new_user();

-- =========================================================================
-- Maintenance générique de `updated_at`
-- =========================================================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger trigger_profiles_updated_at
before update on profiles
for each row
execute function set_updated_at();

create trigger trigger_videos_updated_at
before update on videos
for each row
execute function set_updated_at();
