-- Durées de conservation annoncées dans la politique de confidentialité
-- (RGPD, principe de limitation de la conservation) :
-- les signalements traités sont effacés 1 an après la décision.
-- Les signalements en attente restent jusqu'à leur traitement.

create or replace function private.purge_old_reports()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.content_reports
  where status <> 'pending'
    and coalesce(resolved_at, created_at) < now() - interval '1 year';
$$;

revoke all on function private.purge_old_reports() from public;

create extension if not exists pg_cron;
select cron.unschedule('purge-old-reports')
where exists (select 1 from cron.job where jobname = 'purge-old-reports');
select cron.schedule('purge-old-reports', '17 3 * * *', 'select private.purge_old_reports()');
