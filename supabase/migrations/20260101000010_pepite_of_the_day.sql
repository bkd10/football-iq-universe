-- La Pépite du Jour — voir PARTIE 8.9 : "À l'ouverture de l'app, une vidéo
-- d'un talent mis en avant. Pas une pub — du contenu inspirant. Ici, un
-- inconnu peut devenir une star."
--
-- Sélection anti-biais : parmi les vidéos récentes à fort talent_score
-- venant de profils encore peu suivis (< 500 abonnés), un tirage
-- déterministe par jour (même pépite pour tout le monde, change chaque
-- jour) évite d'avoir besoin d'un cron job dédié.

create or replace function get_pepite_of_the_day()
returns table (
  video_id uuid,
  video_url text,
  thumbnail_url text,
  caption text,
  category text,
  views_count integer,
  user_id uuid,
  username text,
  display_name text,
  avatar_url text,
  country text,
  city text,
  player_position text,
  stars integer,
  followers_count integer,
  world_rank integer
)
language sql
stable
as $$
  with candidates as (
    select
      v.id as video_id, v.video_url, v.thumbnail_url, v.caption, v.category,
      v.views_count, v.user_id,
      p.username, p.display_name, p.avatar_url, p.country, p.city,
      p.position as player_position, p.stars, p.followers_count
    from videos v
    join profiles p on p.id = v.user_id
    where v.status = 'active'
      and v.created_at > now() - interval '30 days'
      and p.followers_count < 500
    order by v.talent_score desc
    limit 50
  )
  select
    c.video_id, c.video_url, c.thumbnail_url, c.caption, c.category,
    c.views_count, c.user_id, c.username, c.display_name, c.avatar_url,
    c.country, c.city, c.player_position, c.stars, c.followers_count,
    (select count(*) + 1 from profiles p2 where p2.stars > c.stars)::integer as world_rank
  from candidates c
  order by md5(c.video_id::text || to_char(current_date, 'YYYY-MM-DD'))
  limit 1;
$$;

grant execute on function get_pepite_of_the_day() to authenticated, anon;
