-- =========================================================================
-- Conditionner le bonus de bienvenue (500 Ballons) à une adresse e-mail
-- confirmée.
--
-- Jusqu'ici `handle_new_user()` créditait les 500 Ballons dès l'insertion
-- dans auth.users, c'est-à-dire dès la soumission du formulaire
-- d'inscription — avant toute confirmation d'e-mail. N'importe qui pouvait
-- donc créer un nombre illimité de comptes avec des adresses jetables et
-- accumuler des Ballons sans jamais confirmer aucune d'entre elles.
--
-- On distingue maintenant deux cas, pour rester correct que la
-- confirmation d'e-mail soit activée ou non côté Supabase Auth :
--   1. Si le compte est déjà confirmé au moment de l'insertion (email
--      confirmation désactivée en dev/test, ou fournisseur OAuth qui
--      confirme automatiquement) : le bonus est crédité immédiatement,
--      comme avant.
--   2. Sinon : `handle_new_user()` crée le profil avec 0 Ballon, et un
--      second trigger sur auth.users, déclenché seulement au moment où
--      `email_confirmed_at` passe de null à une valeur (clic sur le lien
--      reçu par e-mail), crédite alors les 500 Ballons.
-- Dans les deux cas, le bonus n'est jamais accordé deux fois : soit la
-- branche 1 l'a déjà fait à l'insertion et la branche 2 ne se déclenche
-- pas (email_confirmed_at était déjà non-null, la condition `old ... is
-- null` est fausse), soit l'inverse.
-- =========================================================================

create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
  v_already_confirmed boolean := new.email_confirmed_at is not null;
  v_initial_coins integer := case
    when v_role = 'player' and v_already_confirmed then 500
    else 0
  end;
begin
  if v_role not in ('player', 'scout', 'brand') then
    v_role := 'player';
  end if;

  insert into public.profiles (
    id,
    username,
    display_name,
    country,
    position,
    preferred_foot,
    birth_date,
    role,
    coins
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'player_' || substr(new.id::text, 1, 8)),
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'country',
    new.raw_user_meta_data ->> 'position',
    coalesce(new.raw_user_meta_data ->> 'preferred_foot', 'droit'),
    nullif(new.raw_user_meta_data ->> 'birth_date', '')::date,
    v_role,
    v_initial_coins
  );

  if v_initial_coins > 0 then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', v_initial_coins, 'coins', v_initial_coins, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- -------------------------------------------------------------------------
-- Crédite le bonus de bienvenue au moment réel de la confirmation d'e-mail,
-- pour les comptes qui n'étaient pas déjà confirmés à l'inscription.
-- -------------------------------------------------------------------------
create or replace function handle_user_email_confirmed()
returns trigger as $$
declare
  v_new_balance integer;
begin
  update public.profiles
  set coins = coins + 500
  where id = new.id and role = 'player'
  returning coins into v_new_balance;

  if v_new_balance is not null then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', 500, 'coins', v_new_balance, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_email_confirmed on auth.users;

create trigger on_auth_user_email_confirmed
after update on auth.users
for each row
when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
execute function handle_user_email_confirmed();
