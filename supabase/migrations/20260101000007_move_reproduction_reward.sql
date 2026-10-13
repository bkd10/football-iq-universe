-- Récompense l'inventeur d'un Move à chaque reproduction (+1 Ballon — voir
-- PARTIE 7.1 "Move reproduit : 1 Ballon"). Remplace `handle_new_video`
-- (définie dans 20260101000002_triggers.sql) plutôt que de la modifier :
-- le trigger existant pointe déjà vers cette fonction, `create or replace`
-- suffit à changer son comportement sans la recréer.
create or replace function handle_new_video()
returns trigger as $$
declare
  v_original_creator_id uuid;
  v_new_balance integer;
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

    select user_id into v_original_creator_id
    from videos where id = new.original_move_id;

    -- Pas d'auto-récompense si on reproduit son propre Move.
    if v_original_creator_id is not null and v_original_creator_id != new.user_id then
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
$$ language plpgsql;
