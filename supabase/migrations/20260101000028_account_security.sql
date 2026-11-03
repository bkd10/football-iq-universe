-- Double authentification imposée côté serveur.
--
-- Un compte qui a activé une appli de codes (facteur TOTP vérifié) doit
-- saisir son code à chaque connexion : tant que sa session est « aal1 »
-- (mot de passe seul), l'API refuse toute requête. Un vol de mot de passe ne
-- suffit donc plus pour lire ou modifier ses données.
--
-- Branché comme « pre-request » de PostgREST : la fonction tourne avant
-- chaque requête de l'API (tables et RPC).

create or replace function public.enforce_mfa()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_claims jsonb := nullif(current_setting('request.jwt.claims', true), '')::jsonb;
  v_user uuid;
begin
  if v_claims is null or coalesce(v_claims ->> 'aal', '') <> 'aal1' then
    return;
  end if;
  v_user := nullif(v_claims ->> 'sub', '')::uuid;
  if v_user is null then
    return;
  end if;
  if exists (
    select 1 from auth.mfa_factors f
    where f.user_id = v_user and f.status = 'verified'
  ) then
    raise exception 'Code de double authentification requis.'
      using errcode = '42501', hint = 'mfa_required';
  end if;
end;
$$;

revoke execute on function public.enforce_mfa() from public;
grant execute on function public.enforce_mfa() to anon, authenticated, service_role;

alter role authenticator set pgrst.db_pre_request = 'public.enforce_mfa';
notify pgrst, 'reload config';
