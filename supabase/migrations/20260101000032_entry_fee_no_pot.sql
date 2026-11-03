-- Modèle « Candy Crush » (décision de Tom, 03/11/2026) : pour entrer dans
-- une Battle ou un Challenge payant, on dépense des Ballons, quoi qu'il
-- arrive, comme une vie dans un jeu. Ces Ballons ne vont plus dans une
-- cagnotte : le gagnant ne remporte jamais les Ballons des autres, il gagne
-- des Stars (+100), des points de forme sur sa carte et une victoire au
-- compteur. Sans cagnotte, il n'y a plus de pari : les Ballons achetés
-- peuvent donc servir à entrer.
--
-- Reste inchangé : remboursement de l'entrée si la Battle est annulée ou
-- sans vainqueur ; défis officiels gratuits avec une récompense offerte
-- par l'appli ; défis sponsorisés à vrai lot toujours gratuits.

-- Une entrée payante n'alimente jamais de cagnotte.
create or replace function private.no_pot_for_paid_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(new.entry_cost, 0) > 0 and new.prize_currency is distinct from 'real' then
    new.prize_pool := 0;
  end if;
  return new;
end;
$$;

revoke execute on function private.no_pot_for_paid_entry() from public, anon, authenticated;

drop trigger if exists trigger_no_pot_for_paid_entry on challenges;
create trigger trigger_no_pot_for_paid_entry
before insert or update of prize_pool, entry_cost on challenges
for each row execute function private.no_pot_for_paid_entry();

-- Cagnottes déjà constituées par des entrées payantes : remises à zéro
-- (les joueurs ne perdent rien, l'entrée reste remboursée en cas
-- d'annulation).
update challenges set prize_pool = 0
where status = 'active' and entry_cost > 0 and prize_currency is distinct from 'real' and prize_pool > 0;

-- Ballons achetés : utilisés en premier pour toute dépense, entrées
-- comprises (plus de restriction, puisqu'il n'y a plus de mise).
create or replace function private.track_purchased_coins()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount integer := abs(new.amount);
begin
  if new.currency is distinct from 'coins' then
    return null;
  end if;

  if new.type = 'purchase' and new.amount > 0 then
    update profiles set purchased_coins = purchased_coins + v_amount
    where id = new.user_id;
  elsif new.type = 'spend' and new.amount < 0 then
    update profiles set purchased_coins = greatest(0, purchased_coins - v_amount)
    where id = new.user_id;
  end if;

  update profiles set purchased_coins = greatest(coins, 0)
  where id = new.user_id and purchased_coins > greatest(coins, 0);

  return null;
end;
$$;
