-- Déclencheurs manquants pour peupler `notifications` (PARTIE 3.2) — seul
-- `challenge_won` était déjà émis (dans `resolve_expired_challenges`).
-- Sans ceux-ci, la table restait vide en pratique et l'écran
-- "Notifications" (PARTIE 9.2, écran 31) n'aurait jamais eu de contenu.

-- =========================================================================
-- new_follower
-- =========================================================================
create or replace function notify_new_follower()
returns trigger as $$
begin
  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  select
    new.following_id, 'new_follower', 'Nouvel abonné',
    '@' || p.username || ' a commencé à te suivre.',
    new.follower_id, 'profile', new.follower_id
  from profiles p where p.id = new.follower_id;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_new_follower
after insert on follows
for each row
execute function notify_new_follower();

-- =========================================================================
-- like / masterclass — notifie le créateur de la vidéo (sauf auto-like)
-- =========================================================================
create or replace function notify_new_like()
returns trigger as $$
declare
  v_video_owner uuid;
  v_actor_username text;
begin
  select user_id into v_video_owner from videos where id = new.video_id;
  if v_video_owner is null or v_video_owner = new.user_id then
    return new;
  end if;

  select username into v_actor_username from profiles where id = new.user_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    v_video_owner,
    case when new.type = 'masterclass' then 'masterclass' else 'like' end,
    case when new.type = 'masterclass' then 'Nouveau vote Masterclass' else 'Nouveau like' end,
    '@' || coalesce(v_actor_username, 'un joueur') ||
      case when new.type = 'masterclass' then ' a voté Masterclass pour ta vidéo.' else ' a aimé ta vidéo.' end,
    new.user_id, 'video', new.video_id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_new_like
after insert on likes
for each row
execute function notify_new_like();

-- =========================================================================
-- comment
-- =========================================================================
create or replace function notify_new_comment()
returns trigger as $$
declare
  v_video_owner uuid;
  v_actor_username text;
begin
  select user_id into v_video_owner from videos where id = new.video_id;
  if v_video_owner is null or v_video_owner = new.user_id then
    return new;
  end if;

  select username into v_actor_username from profiles where id = new.user_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    v_video_owner, 'comment', 'Nouveau commentaire',
    '@' || coalesce(v_actor_username, 'un joueur') || ' a commenté ta vidéo.',
    new.user_id, 'video', new.video_id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_new_comment
after insert on comments
for each row
execute function notify_new_comment();

-- =========================================================================
-- move_reproduced — crédite l'inventeur du Move (voir PARTIE 8.2 : "reste
-- l'inventeur affiché À VIE")
-- =========================================================================
create or replace function notify_move_reproduced()
returns trigger as $$
declare
  v_move_owner uuid;
  v_move_name text;
  v_actor_username text;
begin
  if new.original_move_id is null then
    return new;
  end if;

  select user_id, move_name into v_move_owner, v_move_name
  from videos where id = new.original_move_id;

  if v_move_owner is null or v_move_owner = new.user_id then
    return new;
  end if;

  select username into v_actor_username from profiles where id = new.user_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    v_move_owner, 'move_reproduced', 'Ton Move a été reproduit !',
    '@' || coalesce(v_actor_username, 'un joueur') || ' a reproduit "' ||
      coalesce(v_move_name, 'ton Move') || '".',
    new.user_id, 'video', new.id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_move_reproduced
after insert on videos
for each row
execute function notify_move_reproduced();

-- =========================================================================
-- badge_earned
-- =========================================================================
create or replace function notify_badge_earned()
returns trigger as $$
declare
  v_badge_name text;
begin
  select name into v_badge_name from badges where id = new.badge_id;

  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    new.user_id, 'badge_earned', 'Nouveau badge débloqué',
    coalesce(v_badge_name, 'Un nouveau badge') || ' rejoint ton Football Passport 🏅',
    'badge', new.badge_id
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trigger_notify_badge_earned
after insert on user_badges
for each row
execute function notify_badge_earned();
