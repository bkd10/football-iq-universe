-- =========================================================================
-- Audit de sécurité (octobre 2026) — corrections vérifiées sur une vraie
-- instance Supabase locale (`supabase start` + appels HTTP réels comme le
-- ferait un client malveillant), pas seulement relues.
--
-- Chaque bloc ci-dessous corrige un problème reproduit avant correctif :
--   1. Follow / like / commentaire / publication de vidéo échouaient tous
--      ("permission denied for table profiles") : les triggers de
--      compteurs s'exécutaient avec les droits du client, privé de UPDATE
--      sur ces colonnes depuis 20260101000009.
--   2. `p_local_date` libre : réclamer le bonus de connexion / publicité
--      avec 10 dates inventées a crédité +550 Ballons en une seconde.
--   3. `create_challenge(p_prize_pool => 1000000)` créait une cagnotte de
--      1 000 000 de Ballons sans rien débiter.
--   4. N'importe qui (même non connecté) lisait la date de naissance
--      exacte de tous les joueurs, mineurs compris.
--   5. Un recruteur lisait `guardian_approval_token` dans ses propres
--      conversations et approuvait lui-même le contact avec un mineur.
--   6. `increment_video_views` appelable en boucle : 100 appels = 1 Star.
--  13. Les classements mélangeaient joueurs, recruteurs et marques
--      (corrigé côté app : filtre role = 'player').
--   7. Insertion de vidéo avec views_count/likes_count/talent_score/
--      is_boosted/status choisis par le client.
--   8. Mise à jour libre des notifications, commentaires (likes_count,
--      status), messages reçus (body) par leurs destinataires.
--   9. `delete_my_account` échouait toujours : Supabase interdit le DELETE
--      direct dans storage.objects (les fichiers sont supprimés par l'app
--      via l'API Storage avant l'appel, voir AuthRemoteDataSource).
--  10. `resolve_expired_challenges` exécutable par anon/authenticated
--      (droit EXECUTE par défaut sur PUBLIC).
--  11. Modération : "Agir" sur un signalement ne retirait jamais le
--      contenu (seul le statut du signalement changeait).
--  12. Basculer un like en Masterclass échouait (aucune policy UPDATE).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Triggers de compteurs : SECURITY DEFINER (ils touchent les lignes
--    d'AUTRES utilisateurs, ce que RLS et les droits colonnes interdisent
--    à juste titre au client).
-- -------------------------------------------------------------------------
alter function handle_new_follow() security definer set search_path = public;
alter function handle_unfollow() security definer set search_path = public;
alter function handle_new_like() security definer set search_path = public;
alter function handle_remove_like() security definer set search_path = public;
alter function handle_like_type_change() security definer set search_path = public;
alter function handle_new_comment() security definer set search_path = public;

-- Le compteur de commentaires ne redescendait jamais à la suppression.
create or replace function handle_remove_comment()
returns trigger as $$
begin
  update videos set comments_count = greatest(comments_count - 1, 0)
  where id = old.video_id;
  return old;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trigger_remove_comment on comments;
create trigger trigger_remove_comment
after delete on comments
for each row
execute function handle_remove_comment();

-- Idem pour le compteur de vidéos du profil.
create or replace function handle_remove_video()
returns trigger as $$
begin
  update profiles set videos_count = greatest(videos_count - 1, 0)
  where id = old.user_id;
  if old.is_move then
    update profiles set moves_created_count = greatest(moves_created_count - 1, 0)
    where id = old.user_id;
  end if;
  return old;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trigger_remove_video on videos;
create trigger trigger_remove_video
after delete on videos
for each row
execute function handle_remove_video();

-- Nouvelle vidéo : la récompense "Move reproduit" n'est versée que si la
-- vidéo d'origine est réellement un Move, et une seule fois par couple
-- (reproducteur, Move) — sinon un ami pouvait publier 1 000 "reproductions"
-- du même Move pour créditer 1 000 Ballons à l'inventeur.
create or replace function handle_new_video()
returns trigger as $$
declare
  v_original_creator_id uuid;
  v_original_is_move boolean;
  v_new_balance integer;
  v_already_reproduced boolean;
begin
  update profiles set videos_count = videos_count + 1
  where id = new.user_id;

  if new.is_move then
    update profiles set moves_created_count = moves_created_count + 1
    where id = new.user_id;
  end if;

  if new.original_move_id is not null then
    select user_id, coalesce(is_move, false)
      into v_original_creator_id, v_original_is_move
    from videos where id = new.original_move_id;

    if not coalesce(v_original_is_move, false) then
      return new;
    end if;

    update videos set reproductions_count = reproductions_count + 1
    where id = new.original_move_id;

    select exists (
      select 1 from videos
      where user_id = new.user_id
        and original_move_id = new.original_move_id
        and id != new.id
    ) into v_already_reproduced;

    if v_original_creator_id is not null
       and v_original_creator_id != new.user_id
       and not v_already_reproduced then
      update profiles set coins = coins + 1
      where id = v_original_creator_id
      returning coins into v_new_balance;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_original_creator_id, 'earn', 1, 'coins', v_new_balance, 'move_reproduced',
        'video', new.id
      );
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 2. Dates locales bornées. Les fuseaux réels vont de UTC-12 à UTC+14 : la
--    date locale d'un appareil honnête est donc toujours la date UTC du
--    jour, la veille ou le lendemain. Toute autre valeur est rejetée. Le
--    bonus de connexion exige en plus une date strictement postérieure à
--    la dernière réclamée (on ne peut plus "revenir" à une date passée).
-- -------------------------------------------------------------------------
create or replace function resolve_local_date(p_local_date date)
returns date as $$
declare
  v_utc_today date := (now() at time zone 'utc')::date;
begin
  if p_local_date is null then
    return v_utc_today;
  end if;
  if p_local_date < v_utc_today - 1 or p_local_date > v_utc_today + 1 then
    raise exception 'Date de l''appareil invalide. Vérifie la date et l''heure de ton téléphone.'
      using errcode = 'P0001';
  end if;
  return p_local_date;
end;
$$ language plpgsql stable set search_path = public;

create or replace function award_coins(
  p_reason text,
  p_reference_id uuid default null,
  p_local_date date default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_economy jsonb;
  v_amount integer;
  v_today date;
  v_last_login date;
  v_streak integer;
  v_count_today integer;
  v_new_balance integer;
  v_streak_bonus integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  select value into v_economy from app_config where key = 'economy';

  if p_reason = 'daily_login' then
    select last_login_date, streak_days into v_last_login, v_streak
    from profiles where id = v_user_id for update;

    if v_last_login is not null and v_today <= v_last_login then
      raise exception 'Connexion quotidienne déjà réclamée aujourd''hui.' using errcode = 'P0001';
    end if;

    if v_last_login = v_today - 1 then
      v_streak := coalesce(v_streak, 0) + 1;
    else
      v_streak := 1;
    end if;

    v_amount := coalesce((v_economy ->> 'daily_login_max')::integer, 20);

    v_streak_bonus := case
      when v_streak = 7 then coalesce((v_economy ->> 'streak_7_days_bonus')::integer, 50)
      when v_streak = 30 then coalesce((v_economy ->> 'streak_30_days_bonus')::integer, 200)
      else 0
    end;
    v_amount := v_amount + v_streak_bonus;

    update profiles
    set coins = coins + v_amount,
        last_login_date = v_today,
        streak_days = v_streak
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, login_completed, coins_earned)
    values (v_user_id, v_today, true, v_amount)
    on conflict (user_id, mission_date)
    do update set login_completed = true,
                  coins_earned = daily_missions.coins_earned + v_amount;

    if v_streak = 7 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_7'
      on conflict (user_id, badge_id) do nothing;
    elsif v_streak = 30 then
      insert into user_badges (user_id, badge_id)
      select v_user_id, id from badges where code = 'assidu_30'
      on conflict (user_id, badge_id) do nothing;
    end if;

  elsif p_reason = 'post_video' then
    -- La récompense doit désigner une vraie vidéo du joueur, publiée dans
    -- les dernières 24 h, et jamais déjà récompensée.
    if p_reference_id is null or not exists (
      select 1 from videos
      where id = p_reference_id
        and user_id = v_user_id
        and created_at > now() - interval '24 hours'
    ) then
      raise exception 'Vidéo introuvable pour cette récompense.' using errcode = 'P0001';
    end if;

    if exists (
      select 1 from transactions
      where user_id = v_user_id and reason = 'post_video' and reference_id = p_reference_id
    ) then
      raise exception 'Récompense déjà reçue pour cette vidéo.' using errcode = 'P0001';
    end if;

    select coalesce(posts_count, 0) into v_count_today
    from daily_missions
    where user_id = v_user_id and mission_date = v_today;

    if coalesce(v_count_today, 0) >= coalesce((v_economy ->> 'max_post_video_per_day')::integer, 3) then
      raise exception 'Limite quotidienne de récompenses vidéo atteinte.' using errcode = 'P0001';
    end if;

    v_amount := coalesce((v_economy ->> 'post_video')::integer, 5);

    update profiles set coins = coins + v_amount
    where id = v_user_id
    returning coins into v_new_balance;

    insert into daily_missions (user_id, mission_date, video_posted, coins_earned, posts_count)
    values (v_user_id, v_today, true, v_amount, 1)
    on conflict (user_id, mission_date)
    do update set video_posted = true,
                  coins_earned = daily_missions.coins_earned + v_amount,
                  posts_count = daily_missions.posts_count + 1;

  elsif p_reason = 'ad_watched' then
    -- Aucune régie publicitaire n'est branchée : rien ne prouve qu'une pub
    -- a été vue. Désactivé tant qu'une vérification serveur (callback de la
    -- régie) n'existe pas — sinon 150 Ballons gratuits par jour et par
    -- compte via un simple appel HTTP.
    raise exception 'Les récompenses publicitaires ne sont pas encore disponibles.'
      using errcode = 'P0001';

  else
    raise exception 'Raison de récompense non prise en charge : %', p_reason using errcode = 'P0001';
  end if;

  insert into transactions (user_id, type, amount, currency, balance_after, reason, reference_id)
  values (v_user_id, 'earn', v_amount, 'coins', v_new_balance, p_reason, p_reference_id);

  return jsonb_build_object('new_balance', v_new_balance, 'amount_awarded', v_amount);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function increment_videos_watched(p_local_date date default null)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date;
  v_watched integer;
  v_bonus_awarded boolean := false;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  v_today := resolve_local_date(p_local_date);

  insert into daily_missions (user_id, mission_date, videos_watched)
  values (v_user_id, v_today, 1)
  on conflict (user_id, mission_date)
  do update set videos_watched = daily_missions.videos_watched + 1
  returning videos_watched into v_watched;

  if v_watched = 3 then
    update profiles set coins = coins + 5
    where id = v_user_id
    returning coins into v_new_balance;

    update daily_missions set coins_earned = coins_earned + 5
    where user_id = v_user_id and mission_date = v_today;

    insert into transactions (user_id, type, amount, currency, balance_after, reason)
    values (v_user_id, 'earn', 5, 'coins', v_new_balance, 'daily_videos_watched');

    v_bonus_awarded := true;
  end if;

  return jsonb_build_object('videos_watched', v_watched, 'bonus_awarded', v_bonus_awarded);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 3. create_challenge : la cagnotte d'un défi joueur part TOUJOURS de 0 et
--    n'est alimentée que par les droits d'entrée (join_challenge). Le
--    paramètre `p_prize_pool` est conservé pour ne pas casser la signature
--    appelée par l'app, mais ignoré. Ajout de bornes sur les champs libres.
-- -------------------------------------------------------------------------
create or replace function create_challenge(
  p_title text,
  p_description text,
  p_type text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_pool integer default 0,
  p_max_participants integer default null,
  p_record_unit text default null,
  p_prize_description text default null
)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_is_verified boolean;
  v_economy jsonb;
  v_create_cost integer;
  v_entry_cost integer;
  v_new_balance integer;
  v_challenge_id uuid;
  v_sponsor_name text;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_description, '')) > 1000 then
    raise exception 'La description est trop longue (1000 caractères max).' using errcode = 'P0001';
  end if;

  if p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
  end if;

  if p_end_date > now() + interval '60 days' then
    raise exception 'Un défi ne peut pas durer plus de 60 jours.' using errcode = 'P0001';
  end if;

  if p_max_participants is not null and (p_max_participants < 2 or p_max_participants > 10000) then
    raise exception 'Nombre de participants invalide.' using errcode = 'P0001';
  end if;

  select role, is_verified, coalesce(display_name, username)
    into v_role, v_is_verified, v_sponsor_name
  from profiles where id = v_user_id;

  if p_type = 'sponsored' then
    if v_role != 'brand' then
      raise exception 'Seul un compte marque peut créer un défi sponsorisé.'
        using errcode = 'P0001';
    end if;
    if not coalesce(v_is_verified, false) then
      raise exception
        'Ton compte marque doit être vérifié avant de pouvoir publier un défi sponsorisé.'
        using errcode = 'P0001';
    end if;
    if p_prize_description is null or trim(p_prize_description) = '' then
      raise exception 'La description du prix est requise pour un défi sponsorisé.'
        using errcode = 'P0001';
    end if;

    insert into challenges (
      creator_id, title, description, type, category, entry_cost, prize_pool,
      prize_currency, prize_description, sponsor_id, sponsor_name,
      max_participants, end_date, status
    ) values (
      v_user_id, trim(p_title), p_description, 'sponsored', p_category, 0, 0,
      'real', left(p_prize_description, 500), v_user_id, v_sponsor_name,
      p_max_participants, p_end_date, 'active'
    )
    returning id into v_challenge_id;

    return jsonb_build_object('challenge_id', v_challenge_id);
  end if;

  if p_type not in ('battle', 'challenge', 'king') then
    raise exception
      'Seuls les défis Battle, Challenge et King peuvent être créés par les joueurs.'
      using errcode = 'P0001';
  end if;

  select value into v_economy from app_config where key = 'economy';
  v_create_cost := coalesce((v_economy ->> 'create_challenge_cost')::integer, 200);
  v_entry_cost := case p_type
    when 'battle' then coalesce((v_economy ->> 'join_battle_min_cost')::integer, 50)
    else coalesce((v_economy ->> 'join_challenge_cost')::integer, 20)
  end;

  update profiles set coins = coins - v_create_cost
  where id = v_user_id and coins >= v_create_cost
  returning coins into v_new_balance;

  if v_new_balance is null then
    raise exception 'Solde de Ballons insuffisant.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    max_participants, record_unit, end_date, status
  ) values (
    v_user_id, trim(p_title), p_description, p_type, p_category, v_entry_cost, 0,
    p_max_participants, left(p_record_unit, 30), p_end_date, 'active'
  )
  returning id into v_challenge_id;

  insert into transactions (
    user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
  ) values (
    v_user_id, 'spend', -v_create_cost, 'coins', v_new_balance, 'create_challenge',
    'challenge', v_challenge_id
  );

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 4. Date de naissance : plus jamais lisible par les autres. Les droits
--    SELECT sont accordés colonne par colonne, sans `birth_date`. Le joueur
--    lit son propre profil complet via `get_my_profile()`.
-- -------------------------------------------------------------------------
revoke select on profiles from anon, authenticated;
grant select (
  id, username, display_name, avatar_url, bio, country, city, position,
  preferred_foot, height_cm, weight_kg, role, is_verified, verification_type,
  coins, stars, level, iq_technique, iq_creativity, iq_popularity,
  iq_consistency, iq_tactical, streak_days, last_login_date, followers_count,
  following_count, videos_count, moves_created_count, likes_received_count,
  challenges_won_count, created_at, updated_at
) on profiles to anon, authenticated;

create or replace function get_my_profile()
returns setof profiles as $$
  select * from profiles where id = auth.uid();
$$ language sql stable security definer set search_path = public;

revoke execute on function get_my_profile() from public, anon;
grant execute on function get_my_profile() to authenticated;

-- -------------------------------------------------------------------------
-- 5. Le jeton d'approbation tuteur n'est plus lisible via la table : seul
--    `get_guardian_approval_token()` (réservée au joueur) le renvoie.
-- -------------------------------------------------------------------------
revoke select on conversations from anon, authenticated;
grant select (
  id, player_id, scout_id, status, requested_at, approved_at, last_message_at
) on conversations to authenticated;
revoke insert, update, delete on conversations from anon, authenticated;

-- -------------------------------------------------------------------------
-- 6. Vues dédupliquées : une vue compte au plus une fois par spectateur,
--    par vidéo et par jour, et jamais sur sa propre vidéo.
-- -------------------------------------------------------------------------
-- Rangée dans un schéma `private` non exposé par l'API : une table
-- reliant videos et profiles dans `public` rendrait ambiguës les jointures
-- `creator:profiles(...)` de l'app (erreur PGRST201).
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.video_views (
  video_id uuid not null references public.videos (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  view_date date not null default ((now() at time zone 'utc')::date),
  primary key (video_id, viewer_id, view_date)
);

alter table private.video_views enable row level security;

create or replace function increment_video_views(p_video_id uuid)
returns void as $$
declare
  v_viewer_id uuid := auth.uid();
  v_creator_id uuid;
  v_new_views integer;
  v_inserted integer;
begin
  if v_viewer_id is null then
    return;
  end if;

  select user_id into v_creator_id
  from videos where id = p_video_id and status = 'active';

  if v_creator_id is null or v_creator_id = v_viewer_id then
    return;
  end if;

  insert into private.video_views (video_id, viewer_id)
  values (p_video_id, v_viewer_id)
  on conflict do nothing;
  get diagnostics v_inserted = row_count;

  if v_inserted = 0 then
    return;
  end if;

  update videos
  set views_count = views_count + 1
  where id = p_video_id
  returning views_count into v_new_views;

  if v_new_views % 100 = 0 then
    update profiles set stars = stars + 1 where id = v_creator_id
    returning stars into v_new_views;

    insert into transactions (
      user_id, type, amount, currency, balance_after, reason, reference_type, reference_id
    ) values (
      v_creator_id, 'earn', 1, 'stars', v_new_views, 'video_views_milestone', 'video', p_video_id
    );
  end if;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 7/8. Droits colonne par colonne en écriture : le client ne peut écrire
--      que les champs "éditoriaux", jamais les compteurs, scores, statuts
--      de modération ou champs de vérification.
-- -------------------------------------------------------------------------
revoke insert on videos from anon, authenticated;
grant insert (
  user_id, video_url, thumbnail_url, duration_seconds, caption, category,
  is_move, move_name, move_slug, original_move_id
) on videos to authenticated;

-- Une vidéo doit pointer vers le dossier Storage de son auteur (pas vers
-- un site externe arbitraire).
create or replace function check_video_urls()
returns trigger as $$
begin
  if new.video_url not like '%/storage/v1/object/public/videos/' || new.user_id::text || '/%' then
    raise exception 'URL de vidéo invalide.' using errcode = 'P0001';
  end if;
  if new.thumbnail_url is not null
     and new.thumbnail_url not like '%/storage/v1/object/public/thumbnails/' || new.user_id::text || '/%' then
    raise exception 'URL de miniature invalide.' using errcode = 'P0001';
  end if;
  return new;
end;
$$ language plpgsql set search_path = public;

drop trigger if exists trigger_check_video_urls on videos;
create trigger trigger_check_video_urls
before insert on videos
for each row
execute function check_video_urls();

revoke insert, update on comments from anon, authenticated;
grant insert (user_id, video_id, parent_id, content) on comments to authenticated;
grant update (content) on comments to authenticated;

revoke update on notifications from anon, authenticated;
grant update (is_read) on notifications to authenticated;
revoke insert, delete on notifications from anon, authenticated;

revoke update on messages from anon, authenticated;
grant update (read_at) on messages to authenticated;
revoke insert, delete on messages from anon, authenticated;

revoke insert, update on likes from anon, authenticated;
grant insert (user_id, video_id, type) on likes to authenticated;
grant update (type) on likes to authenticated;

-- 12. Basculer like <-> Masterclass (upsert côté app) nécessite une policy
--     UPDATE, absente jusqu'ici.
drop policy if exists "Users can change their own reaction" on likes;
create policy "Users can change their own reaction"
on likes for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

revoke insert, update on organizations from anon, authenticated;
grant insert (owner_id, name, type, country, logo_url) on organizations to authenticated;
grant update (name, country, logo_url) on organizations to authenticated;

revoke insert, update on content_reports from anon, authenticated;
grant insert (target_type, target_id, reporter_id, reason) on content_reports to authenticated;

-- Tables entièrement serveur : aucun droit d'écriture client (RLS les
-- bloquait déjà faute de policy ; on retire aussi le privilège, en
-- défense en profondeur).
revoke insert, update, delete on
  transactions, user_badges, daily_missions, badges, app_config,
  scout_subscriptions, challenge_participations, challenge_votes
from anon, authenticated;

-- Défis : uniquement via les RPC. La policy "brouillon modifiable" ne sert
-- à rien (aucun défi n'est créé en brouillon) et permettait en théorie de
-- modifier prize_pool/entry_cost.
drop policy if exists "Creators can edit own draft challenges" on challenges;
drop policy if exists "Users can vote as themselves" on challenge_votes;
revoke insert, update, delete on challenges from anon, authenticated;

-- Profil : le client n'insère jamais de ligne (trigger handle_new_user).
revoke insert, delete on profiles from anon, authenticated;

-- Longueurs maximales (anti-spam / anti-abus de stockage).
alter table profiles
  add constraint profiles_username_format
  check (username ~ '^[A-Za-z0-9_.]{3,30}$') not valid;
alter table profiles
  add constraint profiles_bio_length check (char_length(coalesce(bio, '')) <= 300) not valid;
alter table profiles
  add constraint profiles_display_name_length
  check (char_length(coalesce(display_name, '')) <= 50) not valid;
alter table videos
  add constraint videos_caption_length check (char_length(coalesce(caption, '')) <= 500) not valid;
alter table videos
  add constraint videos_move_name_length check (char_length(coalesce(move_name, '')) <= 60) not valid;
alter table comments
  add constraint comments_content_length
  check (char_length(content) between 1 and 500) not valid;
alter table messages
  add constraint messages_body_length check (char_length(body) between 1 and 2000) not valid;
alter table content_reports
  add constraint content_reports_reason_length check (char_length(reason) <= 500) not valid;

-- -------------------------------------------------------------------------
-- 9. Suppression de compte : plus de DELETE direct dans storage.objects
--    (refusé par Supabase). Les fichiers sont supprimés par l'app via
--    l'API Storage juste avant cet appel.
-- -------------------------------------------------------------------------
create or replace function delete_my_account()
returns void as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  delete from auth.users where id = v_user_id;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 10. Fonctions réservées au système : plus exécutables par les clients.
-- -------------------------------------------------------------------------
revoke execute on function resolve_expired_challenges() from public, anon, authenticated;
revoke execute on function resolve_local_date(date) from public, anon, authenticated;
revoke execute on function handle_new_user() from public, anon, authenticated;
revoke execute on function handle_user_email_confirmed() from public, anon, authenticated;
revoke execute on function delete_my_account() from public, anon;
revoke execute on function award_coins(text, uuid, date) from public, anon;
revoke execute on function spend_coins(text, uuid, integer) from public, anon;
revoke execute on function increment_videos_watched(date) from public, anon;
revoke execute on function increment_video_views(uuid) from public, anon;
revoke execute on function find_ledger_drift() from public, anon;

-- -------------------------------------------------------------------------
-- 11. Modération effective : un admin qui "agit" sur un signalement retire
--     réellement la vidéo ou le commentaire visé.
-- -------------------------------------------------------------------------
create or replace function admin_resolve_report(
  p_report_id uuid,
  p_status text,
  p_note text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := auth.uid();
  v_report content_reports%rowtype;
begin
  if not exists (select 1 from profiles where id = v_admin_id and role = 'admin') then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  if p_status not in ('reviewed', 'actioned', 'dismissed') then
    raise exception 'Statut invalide.' using errcode = 'P0001';
  end if;

  select * into v_report from content_reports where id = p_report_id for update;
  if v_report.id is null then
    raise exception 'Signalement introuvable.' using errcode = 'P0001';
  end if;

  if p_status = 'actioned' then
    if v_report.target_type = 'video' then
      update videos set status = 'removed' where id = v_report.target_id;
    elsif v_report.target_type = 'comment' then
      update comments set status = 'removed' where id = v_report.target_id;
    end if;
    -- Profil : aucune suppression automatique (décision humaine, via le
    -- dashboard Supabase), seul le signalement est marqué traité.
  end if;

  update content_reports
  set status = p_status,
      resolved_by = v_admin_id,
      resolution_note = p_note,
      resolved_at = now()
  where id = p_report_id;

  return jsonb_build_object('resolved', true);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function admin_resolve_report(uuid, text, text) from public, anon;
grant execute on function admin_resolve_report(uuid, text, text) to authenticated;

-- -------------------------------------------------------------------------
-- Buckets Storage en production : `config.toml` ne sert qu'en local. Sans
-- ce bloc, un projet Supabase hébergé n'aurait ni les buckets ni leurs
-- limites de taille / types de fichiers.
-- -------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('videos', 'videos', true, 209715200, array['video/mp4', 'video/quicktime', 'video/webm']),
  ('thumbnails', 'thumbnails', true, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('avatars', 'avatars', true, 5242880, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- -------------------------------------------------------------------------
-- find_ledger_drift plantait à chaque appel ("column reference currency is
-- ambiguous" : les colonnes de RETURNS TABLE masquent celles de la table).
-- Même logique, colonnes qualifiées.
-- -------------------------------------------------------------------------
create or replace function find_ledger_drift()
returns table (
  user_id uuid,
  currency text,
  stored_balance integer,
  ledger_sum bigint,
  drift bigint
) as $$
begin
  if not exists (
    select 1 from profiles pr where pr.id = auth.uid() and pr.role = 'admin'
  ) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  return query
  with sums as (
    select tx.user_id as uid, tx.currency as cur, sum(tx.amount)::bigint as total
    from transactions tx
    where tx.user_id is not null
    group by tx.user_id, tx.currency
  ),
  balances as (
    select p.id as uid, 'coins'::text as cur, p.coins as bal from profiles p
    union all
    select p.id, 'stars'::text, p.stars from profiles p
  )
  select b.uid, b.cur, b.bal, coalesce(s.total, 0::bigint),
         b.bal::bigint - coalesce(s.total, 0::bigint)
  from balances b
  left join sums s on s.uid = b.uid and s.cur = b.cur
  where b.bal::bigint != coalesce(s.total, 0::bigint);
end;
$$ language plpgsql security definer set search_path = public;

revoke execute on function find_ledger_drift() from public, anon;
grant execute on function find_ledger_drift() to authenticated;
