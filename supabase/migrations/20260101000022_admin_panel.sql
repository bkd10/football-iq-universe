-- =========================================================================
-- Panneau administrateur
--
-- Tout passe par des RPC SECURITY DEFINER qui vérifient elles-mêmes
-- `profiles.role = 'admin'` : l'app n'a aucun droit direct en plus, un
-- non-admin qui appelle ces fonctions reçoit "Réservé aux administrateurs."
--
--   1. Notifications de modération (type 'moderation').
--   2. Bannissement : profil marqué, connexion bloquée côté Auth, sessions
--      coupées, vidéos masquées (statut 'flagged') — réversible.
--   3. Signalements : liste avec aperçu du contenu, décision (retirer ou
--      garder) avec message pré-écrit à l'auteur et aux signaleurs ; tous
--      les signalements en attente sur le même contenu sont clos ensemble.
--   4. Statistiques du tableau de bord.
--   5. Liste des joueurs (recherche).
--   6. Défis officiels (type 'world', gratuits, sans coût de création).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. Type de notification 'moderation'
-- -------------------------------------------------------------------------
alter table notifications drop constraint if exists notifications_type_check;
alter table notifications
  add constraint notifications_type_check
  check (type in (
    'new_follower', 'like', 'masterclass', 'comment', 'move_reproduced',
    'badge_earned', 'challenge_won', 'scout_interest', 'contact_approved',
    'moderation'
  ));

-- -------------------------------------------------------------------------
-- 2. Bannissement
-- -------------------------------------------------------------------------
alter table profiles add column if not exists is_banned boolean not null default false;
alter table profiles add column if not exists banned_at timestamptz;
alter table profiles add column if not exists ban_reason text;

-- Les colonnes de bannissement ne sont jamais lisibles ni modifiables via
-- l'API (les droits SELECT/UPDATE sur profiles sont colonne par colonne
-- depuis la migration 0021) : seul un admin les voit, via les RPC.

create schema if not exists private;

create or replace function private.require_admin()
returns uuid as $$
declare
  v_admin_id uuid := auth.uid();
begin
  if v_admin_id is null
     or not exists (select 1 from public.profiles where id = v_admin_id and role = 'admin') then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;
  return v_admin_id;
end;
$$ language plpgsql stable security definer set search_path = public;

create or replace function private.apply_ban(
  p_user_id uuid,
  p_banned boolean,
  p_reason text,
  p_admin_id uuid
)
returns void as $$
declare
  v_role text;
begin
  select role into v_role from public.profiles where id = p_user_id;
  if v_role is null then
    raise exception 'Joueur introuvable.' using errcode = 'P0001';
  end if;
  if p_user_id = p_admin_id then
    raise exception 'Tu ne peux pas te bannir toi-même.' using errcode = 'P0001';
  end if;
  if v_role = 'admin' then
    raise exception 'Impossible de bannir un administrateur.' using errcode = 'P0001';
  end if;

  if p_banned then
    update public.profiles
    set is_banned = true, banned_at = now(), ban_reason = left(p_reason, 500)
    where id = p_user_id;

    -- Connexion refusée par Supabase Auth, sessions en cours coupées.
    update auth.users set banned_until = now() + interval '100 years' where id = p_user_id;
    delete from auth.sessions where user_id = p_user_id;

    -- Vidéos masquées (pas supprimées : un débannissement les remet).
    update public.videos set status = 'flagged' where user_id = p_user_id and status = 'active';
  else
    update public.profiles
    set is_banned = false, banned_at = null, ban_reason = null
    where id = p_user_id;

    update auth.users set banned_until = null where id = p_user_id;
    update public.videos set status = 'active' where user_id = p_user_id and status = 'flagged';
  end if;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function private.require_admin() from public, anon, authenticated;
revoke all on function private.apply_ban(uuid, boolean, text, uuid) from public, anon, authenticated;

create or replace function admin_set_ban(
  p_user_id uuid,
  p_banned boolean,
  p_reason text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
begin
  if p_banned and (p_reason is null or trim(p_reason) = '') then
    raise exception 'Indique la raison du bannissement.' using errcode = 'P0001';
  end if;
  perform private.apply_ban(p_user_id, p_banned, p_reason, v_admin_id);
  return jsonb_build_object('banned', p_banned);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 3. Signalements
-- -------------------------------------------------------------------------

-- Liste des signalements en attente, regroupés par contenu signalé, avec
-- de quoi décider sans quitter l'écran (aperçu, auteur, nombre de
-- signalements, raisons).
create or replace function admin_list_reports()
returns table (
  report_id uuid,
  target_type text,
  target_id uuid,
  reason text,
  reasons text[],
  reports_count integer,
  reporter_username text,
  created_at timestamptz,
  author_id uuid,
  author_username text,
  preview_text text,
  video_url text,
  thumbnail_url text,
  target_status text
) as $$
begin
  perform private.require_admin();

  return query
  with grouped as (
    select r.target_type as g_type, r.target_id as g_id, count(*) as cnt,
           array_agg(distinct r.reason) as all_reasons
    from content_reports r
    where r.status = 'pending'
    group by r.target_type, r.target_id
  ),
  pending as (
    select distinct on (r.target_type, r.target_id) r.*, g.cnt, g.all_reasons
    from content_reports r
    join grouped g on g.g_type = r.target_type and g.g_id = r.target_id
    where r.status = 'pending'
    order by r.target_type, r.target_id, r.created_at
  )
  select
    p.id,
    p.target_type,
    p.target_id,
    p.reason,
    p.all_reasons,
    p.cnt::integer,
    rp.username,
    p.created_at,
    coalesce(v.user_id, c.user_id, tp.id),
    coalesce(va.username, ca.username, tp.username),
    case p.target_type
      when 'video' then v.caption
      when 'comment' then c.content
      else tp.bio
    end,
    v.video_url,
    v.thumbnail_url,
    case p.target_type
      when 'video' then coalesce(v.status, 'deleted')
      when 'comment' then coalesce(c.status, 'deleted')
      else case when tp.id is null then 'deleted' when tp.is_banned then 'banned' else 'active' end
    end
  from pending p
  left join profiles rp on rp.id = p.reporter_id
  left join videos v on p.target_type = 'video' and v.id = p.target_id
  left join profiles va on va.id = v.user_id
  left join comments c on p.target_type = 'comment' and c.id = p.target_id
  left join profiles ca on ca.id = c.user_id
  left join profiles tp on p.target_type = 'profile' and tp.id = p.target_id
  order by p.cnt desc, p.created_at asc;
end;
$$ language plpgsql stable security definer set search_path = public;

-- Remplace la version à 3 paramètres de la migration 0021.
drop function if exists admin_resolve_report(uuid, text, text);

-- p_status : 'actioned' (contenu retiré / profil banni) ou 'dismissed'
-- (contenu gardé). p_author_message et p_reporter_message : textes
-- (pré-écrits côté app, modifiables) envoyés en notification ; null = aucun.
create or replace function admin_resolve_report(
  p_report_id uuid,
  p_status text,
  p_author_message text default null,
  p_reporter_message text default null,
  p_note text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
  v_report content_reports%rowtype;
  v_author_id uuid;
  v_closed integer;
begin
  if p_status not in ('actioned', 'dismissed') then
    raise exception 'Statut invalide.' using errcode = 'P0001';
  end if;
  if char_length(coalesce(p_author_message, '')) > 500
     or char_length(coalesce(p_reporter_message, '')) > 500 then
    raise exception 'Message trop long (500 caractères max).' using errcode = 'P0001';
  end if;

  select * into v_report from content_reports where id = p_report_id for update;
  if v_report.id is null then
    raise exception 'Signalement introuvable.' using errcode = 'P0001';
  end if;

  if v_report.target_type = 'video' then
    select user_id into v_author_id from videos where id = v_report.target_id;
  elsif v_report.target_type = 'comment' then
    select user_id into v_author_id from comments where id = v_report.target_id;
  else
    v_author_id := v_report.target_id;
  end if;

  if p_status = 'actioned' then
    if v_report.target_type = 'video' then
      update videos set status = 'removed' where id = v_report.target_id;
    elsif v_report.target_type = 'comment' then
      update comments set status = 'removed' where id = v_report.target_id;
    elsif v_author_id is not null then
      perform private.apply_ban(
        v_author_id, true,
        coalesce(nullif(trim(p_author_message), ''), v_report.reason),
        v_admin_id
      );
    end if;
  end if;

  -- Message aux signaleurs (tous ceux en attente sur ce contenu).
  if nullif(trim(p_reporter_message), '') is not null then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    select distinct r.reporter_id, 'moderation', 'Ton signalement a été traité',
           trim(p_reporter_message), null::text, null::uuid
    from content_reports r
    where r.target_type = v_report.target_type
      and r.target_id = v_report.target_id
      and r.status = 'pending'
      and r.reporter_id is not null
      and r.reporter_id is distinct from v_author_id;
  end if;

  -- Message à l'auteur (inutile s'il vient d'être banni : il ne peut plus
  -- se connecter).
  if v_author_id is not null
     and nullif(trim(p_author_message), '') is not null
     and not (p_status = 'actioned' and v_report.target_type = 'profile') then
    insert into notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_author_id, 'moderation', 'Message de la modération', trim(p_author_message),
      case when p_status = 'dismissed' and v_report.target_type = 'video' then 'video' end,
      case when p_status = 'dismissed' and v_report.target_type = 'video' then v_report.target_id end
    );
  end if;

  update content_reports
  set status = p_status,
      resolved_by = v_admin_id,
      resolution_note = left(coalesce(p_note, p_author_message), 1000),
      resolved_at = now()
  where target_type = v_report.target_type
    and target_id = v_report.target_id
    and status = 'pending';
  get diagnostics v_closed = row_count;

  return jsonb_build_object('resolved', true, 'reports_closed', v_closed);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 4. Statistiques
-- -------------------------------------------------------------------------
create or replace function admin_dashboard_stats()
returns jsonb as $$
begin
  perform private.require_admin();

  return jsonb_build_object(
    'players_total', (select count(*) from profiles where role = 'player'),
    'players_today', (select count(*) from profiles where role = 'player' and created_at >= date_trunc('day', now())),
    'players_7d', (select count(*) from profiles where role = 'player' and created_at >= now() - interval '7 days'),
    'videos_total', (select count(*) from videos where status = 'active'),
    'videos_today', (select count(*) from videos where status = 'active' and created_at >= date_trunc('day', now())),
    'challenges_active', (select count(*) from challenges where status = 'active' and end_date > now()),
    'reports_pending', (select count(distinct (target_type, target_id)) from content_reports where status = 'pending'),
    'banned_total', (select count(*) from profiles where is_banned)
  );
end;
$$ language plpgsql stable security definer set search_path = public;

-- -------------------------------------------------------------------------
-- 5. Joueurs
-- -------------------------------------------------------------------------
create or replace function admin_list_users(
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  email text,
  role text,
  created_at timestamptz,
  videos_count integer,
  followers_count integer,
  is_banned boolean,
  ban_reason text,
  reports_count bigint
) as $$
declare
  v_search text := nullif(trim(p_search), '');
begin
  perform private.require_admin();

  return query
  select
    p.id, p.username, p.display_name, p.avatar_url, u.email::text, p.role,
    p.created_at, p.videos_count, p.followers_count, p.is_banned, p.ban_reason,
    (select count(*) from content_reports r
      left join videos v on r.target_type = 'video' and v.id = r.target_id
      left join comments c on r.target_type = 'comment' and c.id = r.target_id
      where coalesce(v.user_id, c.user_id, case when r.target_type = 'profile' then r.target_id end) = p.id)
  from profiles p
  left join auth.users u on u.id = p.id
  where v_search is null
     or p.username ilike '%' || v_search || '%'
     or p.display_name ilike '%' || v_search || '%'
     or u.email ilike '%' || v_search || '%'
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$ language plpgsql stable security definer set search_path = public, auth;

-- -------------------------------------------------------------------------
-- 6. Défis officiels
-- -------------------------------------------------------------------------
create or replace function admin_create_official_challenge(
  p_title text,
  p_description text,
  p_end_date timestamptz,
  p_category text default null,
  p_prize_description text default null
)
returns jsonb as $$
declare
  v_admin_id uuid := private.require_admin();
  v_challenge_id uuid;
begin
  if p_title is null or char_length(trim(p_title)) < 3 or char_length(p_title) > 80 then
    raise exception 'Le titre doit faire entre 3 et 80 caractères.' using errcode = 'P0001';
  end if;
  if char_length(coalesce(p_description, '')) > 1000 then
    raise exception 'La description est trop longue (1000 caractères max).' using errcode = 'P0001';
  end if;
  if p_end_date is null or p_end_date <= now() then
    raise exception 'La date de fin doit être dans le futur.' using errcode = 'P0001';
  end if;
  if p_end_date > now() + interval '90 days' then
    raise exception 'Un défi officiel ne peut pas durer plus de 90 jours.' using errcode = 'P0001';
  end if;

  insert into challenges (
    creator_id, title, description, type, category, entry_cost, prize_pool,
    prize_description, sponsor_name, is_official, end_date, status
  ) values (
    v_admin_id, trim(p_title), coalesce(p_description, ''), 'world', p_category, 0, 0,
    left(nullif(trim(p_prize_description), ''), 500), 'Football IQ Universe', true,
    p_end_date, 'active'
  )
  returning id into v_challenge_id;

  return jsonb_build_object('challenge_id', v_challenge_id);
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- Droits
-- -------------------------------------------------------------------------
revoke execute on function admin_set_ban(uuid, boolean, text) from public, anon;
revoke execute on function admin_list_reports() from public, anon;
revoke execute on function admin_resolve_report(uuid, text, text, text, text) from public, anon;
revoke execute on function admin_dashboard_stats() from public, anon;
revoke execute on function admin_list_users(text, integer, integer) from public, anon;
revoke execute on function admin_create_official_challenge(text, text, timestamptz, text, text) from public, anon;

grant execute on function admin_set_ban(uuid, boolean, text) to authenticated;
grant execute on function admin_list_reports() to authenticated;
grant execute on function admin_resolve_report(uuid, text, text, text, text) to authenticated;
grant execute on function admin_dashboard_stats() to authenticated;
grant execute on function admin_list_users(text, integer, integer) to authenticated;
grant execute on function admin_create_official_challenge(text, text, timestamptz, text, text) to authenticated;
