-- Bonus de bienvenue : 100 Ballons au lieu de 500 (décision de Tom,
-- 15/10/2026 : les Ballons doivent rester rares pour que les joueurs aient
-- envie d'en acheter). Le montant est lu dans `app_config.economy`, il se
-- change désormais sans toucher au code. Les comptes existants gardent ce
-- qu'ils ont.

create schema if not exists private;

update app_config
set value = value || '{"welcome_bonus": 100}'::jsonb
where key = 'economy';

alter table profiles alter column coins set default 0;

create or replace function private.welcome_bonus()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select (value ->> 'welcome_bonus')::integer from app_config where key = 'economy'), 100);
$$;

revoke execute on function private.welcome_bonus() from public, anon, authenticated;

create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
  v_already_confirmed boolean := new.email_confirmed_at is not null;
  v_initial_coins integer := case
    when v_role = 'player' and v_already_confirmed then private.welcome_bonus()
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
  v_bonus integer := private.welcome_bonus();
begin
  update public.profiles
  set coins = coins + v_bonus
  where id = new.id and role = 'player'
  returning coins into v_new_balance;

  if v_new_balance is not null then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', v_bonus, 'coins', v_new_balance, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;


revoke execute on function handle_new_user() from public, anon, authenticated;
revoke execute on function handle_user_email_confirmed() from public, anon, authenticated;
