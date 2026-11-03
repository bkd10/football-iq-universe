-- Garde-fous pour que le jeu ne soit pas un jeu d'argent.
--
-- En France, un jeu d'argent = une mise payante + du hasard + un gain.
-- Les Ballons achetés avec de l'argent réel ne peuvent donc JAMAIS servir
-- de mise pour gagner autre chose :
--   - Battles et Challenges payants (l'entrée alimente la cagnotte du
--     gagnant) : seuls les Ballons gagnés en jouant peuvent être misés ;
--   - les Ballons achetés servent uniquement aux bonus (mise en avant,
--     etc.), jamais à une cagnotte ;
--   - un défi avec un vrai lot (défi sponsorisé) est toujours gratuit ;
--   - les Ballons ne s'échangent jamais contre de l'argent et ne se
--     transfèrent pas entre joueurs (aucune fonction ne le permet).
--
-- `profiles.purchased_coins` = part du solde qui vient d'achats. Elle est
-- dépensée en premier pour les bonus, jamais pour une mise. Tenue à jour
-- automatiquement à chaque écriture du grand livre (`transactions`).

create schema if not exists private;

alter table profiles add column if not exists purchased_coins integer not null default 0
  check (purchased_coins >= 0);

create or replace function private.track_purchased_coins()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_purchased integer;
  v_amount integer := abs(new.amount);
begin
  if new.currency is distinct from 'coins' then
    return null;
  end if;

  select purchased_coins into v_purchased
  from profiles where id = new.user_id
  for update;

  if new.type = 'purchase' and new.amount > 0 then
    update profiles set purchased_coins = purchased_coins + v_amount
    where id = new.user_id;
  elsif new.type = 'spend' and new.amount < 0 then
    if new.reason in ('join_battle', 'join_challenge') then
      -- Après la mise, il doit rester au moins tous les Ballons achetés :
      -- la mise vient donc entièrement de Ballons gagnés.
      if coalesce(new.balance_after, 0) < v_purchased then
        raise exception 'Seuls les Ballons gagnés en jouant peuvent servir de mise. Les Ballons achetés servent aux bonus.'
          using errcode = 'P0001';
      end if;
    else
      update profiles set purchased_coins = greatest(0, purchased_coins - v_amount)
      where id = new.user_id;
    end if;
  end if;

  update profiles set purchased_coins = greatest(coins, 0)
  where id = new.user_id and purchased_coins > greatest(coins, 0);

  return null;
end;
$$;

revoke execute on function private.track_purchased_coins() from public, anon, authenticated;

drop trigger if exists trigger_track_purchased_coins on transactions;
create trigger trigger_track_purchased_coins
after insert on transactions
for each row execute function private.track_purchased_coins();

-- Un vrai lot ne s'achète jamais : entrée gratuite obligatoire.
alter table challenges drop constraint if exists challenges_real_prize_free_entry;
alter table challenges add constraint challenges_real_prize_free_entry
  check (prize_currency is distinct from 'real' or entry_cost = 0) not valid;

-- Solde du joueur connecté, séparé en Ballons gagnés / achetés.
create or replace function my_wallet()
returns table (coins integer, purchased_coins integer, earned_coins integer)
language sql
stable
security definer
set search_path = public
as $$
  select p.coins, p.purchased_coins, greatest(p.coins - p.purchased_coins, 0)
  from profiles p
  where p.id = auth.uid();
$$;

revoke execute on function my_wallet() from public, anon;
grant execute on function my_wallet() to authenticated;
