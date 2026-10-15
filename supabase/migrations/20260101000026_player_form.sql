-- Forme du joueur sur les 30 derniers jours : la partie de la note qui peut
-- baisser. La note affichée sur la carte = carrière (45 à 89, ne baisse
-- pas) + forme (-6 à +10), bornée entre 40 et 99.
--
-- Forme :
--   - Respect reçus ces 30 derniers jours : jusqu'à +8 (échelle log10) ;
--   - Battles terminées ces 30 derniers jours : +2 par victoire, -2 par
--     défaite, entre -4 et +4 ;
--   - aucune vidéo publiée depuis 30 jours : -3.
--
-- Stockée dans `profiles.form_score` (lisible, jamais modifiable par les
-- clients), recalculée tout de suite quand un joueur publie ou reçoit une
-- réaction, et toutes les heures pour tout le monde (Battles terminées,
-- Respect qui sortent de la fenêtre des 30 jours).

create schema if not exists private;

alter table profiles add column if not exists form_score smallint not null default 0;
grant select (form_score) on profiles to anon, authenticated;

create index if not exists idx_likes_video_created on likes (video_id, created_at desc);
create index if not exists idx_videos_user_created on videos (user_id, created_at desc);

create or replace function private.compute_form(p_user_id uuid)
returns smallint
language sql
stable
security definer
set search_path = public
as $$
  select greatest(-6, least(10,
    least(round(log(1 + rr.pts) * 3)::integer, 8)
    + greatest(-4, least(4, b.net * 2))
    - case when a.posted then 0 else 3 end
  ))::smallint
  from
    (
      select coalesce(sum(private.respect_points(l.type)), 0)::numeric as pts
      from likes l
      join videos v on v.id = l.video_id
      where v.user_id = p_user_id
        and l.user_id <> p_user_id
        and l.created_at > now() - interval '30 days'
    ) rr,
    (
      select coalesce(sum(case when c.winner_id = p_user_id then 1 else -1 end), 0)::integer as net
      from challenge_participations cp
      join challenges c on c.id = cp.challenge_id
      where cp.user_id = p_user_id
        and c.type = 'battle'
        and c.status = 'completed'
        and c.winner_id is not null
        and c.end_date > now() - interval '30 days'
    ) b,
    (
      select exists (
        select 1 from videos v
        where v.user_id = p_user_id
          and v.status = 'active'
          and v.created_at > now() - interval '30 days'
      ) as posted
    ) a;
$$;

create or replace function private.refresh_form(p_user_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update profiles
  set form_score = private.compute_form(p_user_id)
  where id = p_user_id
    and form_score is distinct from private.compute_form(p_user_id);
$$;

-- Recalcul pour tous les joueurs (tâche planifiée toutes les heures).
create or replace function refresh_form_scores()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  update profiles p
  set form_score = f.score
  from (select id, private.compute_form(id) as score from profiles) f
  where f.id = p.id and p.form_score is distinct from f.score;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function refresh_form_scores() from public, anon, authenticated;
revoke execute on function private.compute_form(uuid) from public, anon, authenticated;
revoke execute on function private.refresh_form(uuid) from public, anon, authenticated;

-- Mise à jour immédiate : réaction reçue ou retirée, vidéo publiée.
create or replace function handle_form_on_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform private.refresh_form(v.user_id)
  from videos v
  where v.id = coalesce(new.video_id, old.video_id);
  return null;
end;
$$;

create or replace function handle_form_on_video()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform private.refresh_form(new.user_id);
  return null;
end;
$$;

revoke execute on function handle_form_on_like() from public, anon, authenticated;
revoke execute on function handle_form_on_video() from public, anon, authenticated;

drop trigger if exists trigger_form_on_like on likes;
create trigger trigger_form_on_like
after insert or delete or update of type on likes
for each row execute function handle_form_on_like();

drop trigger if exists trigger_form_on_video on videos;
create trigger trigger_form_on_video
after insert or update of status on videos
for each row execute function handle_form_on_video();

-- Calcul initial pour les joueurs existants.
select refresh_form_scores();

create extension if not exists pg_cron;
select cron.unschedule('refresh-form-scores')
where exists (select 1 from cron.job where jobname = 'refresh-form-scores');
select cron.schedule('refresh-form-scores', '7 * * * *', 'select public.refresh_form_scores()');
