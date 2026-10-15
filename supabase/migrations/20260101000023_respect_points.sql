-- Points de Respect : la couleur de la carte joueur se gagne par paliers,
-- comme les disques d'or (Bronze, Argent, Or, Platine, Diamant).
--
-- `profiles.likes_received_count` existait mais n'était jamais mis à jour.
-- Il devient le total de points de Respect reçus par le joueur :
--   - un Respect reçu = 1 point ;
--   - une Masterclass reçue = 3 points.
-- Les réactions qu'un joueur met sur ses propres vidéos ne comptent pas.

create schema if not exists private;

create or replace function private.respect_points(p_type text)
returns integer
language sql
immutable
as $$
  select case when p_type = 'masterclass' then 3 else 1 end;
$$;

create or replace function handle_respect_points()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_video_id uuid;
  v_reactor_id uuid;
  v_owner_id uuid;
  v_delta integer;
begin
  if tg_op = 'INSERT' then
    v_video_id := new.video_id;
    v_reactor_id := new.user_id;
    v_delta := private.respect_points(new.type);
  elsif tg_op = 'DELETE' then
    v_video_id := old.video_id;
    v_reactor_id := old.user_id;
    v_delta := -private.respect_points(old.type);
  else
    if new.type = old.type then
      return null;
    end if;
    v_video_id := new.video_id;
    v_reactor_id := new.user_id;
    v_delta := private.respect_points(new.type) - private.respect_points(old.type);
  end if;

  select user_id into v_owner_id from videos where id = v_video_id;

  -- Vidéo déjà supprimée (suppression en cascade) : les points restent acquis.
  if v_owner_id is null or v_owner_id = v_reactor_id then
    return null;
  end if;

  update profiles
  set likes_received_count = greatest(coalesce(likes_received_count, 0) + v_delta, 0)
  where id = v_owner_id;

  return null;
end;
$$;

revoke execute on function handle_respect_points() from public, anon, authenticated;

drop trigger if exists trigger_respect_points on likes;
create trigger trigger_respect_points
after insert or delete or update of type on likes
for each row
execute function handle_respect_points();

-- Rattrapage : recalcule les points de tous les joueurs à partir des
-- réactions déjà présentes.
update profiles p
set likes_received_count = coalesce((
  select sum(private.respect_points(l.type))
  from likes l
  join videos v on v.id = l.video_id
  where v.user_id = p.id
    and l.user_id <> p.id
), 0);
