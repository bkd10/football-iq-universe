-- Missions quotidiennes — PARTIE 8.5. `login_completed`/`video_posted`
-- sont déjà mis à jour par `award_coins` (voir migration précédente) au
-- moment où l'utilisateur réclame son bonus de connexion / publie une
-- vidéo. Cette migration ajoute le suivi "vidéos regardées" et son bonus
-- de palier (+5 Ballons à la 3e vidéo du jour).

create or replace function increment_videos_watched()
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := current_date;
  v_watched integer;
  v_bonus_awarded boolean := false;
  v_new_balance integer;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

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

grant execute on function increment_videos_watched() to authenticated;
