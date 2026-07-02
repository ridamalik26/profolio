-- ProFolio: bring the live `applications` / `saved_jobs` tables in sync with
-- 20260702000000_job_matching.sql. The tables were created before several
-- columns (and the composite unique index used by upsert's onConflict) were
-- added to that migration, so the app's insert/upsert calls were failing with
-- "Could not find the '<column>' column" (PGRST204) and
-- "no unique or exclusion constraint matching the ON CONFLICT specification"
-- (42P10). Safe to re-run.

alter table public.applications
  add column if not exists job_type text,
  add column if not exists salary text,
  add column if not exists match_score integer,
  add column if not exists applicant_name text,
  add column if not exists applicant_email text,
  add column if not exists applicant_phone text,
  add column if not exists resume_url text,
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists applications_user_job_unique
  on public.applications (user_id, job_id);

drop trigger if exists set_applications_updated_at on public.applications;
create trigger set_applications_updated_at
  before update on public.applications
  for each row
  execute function public.set_updated_at();

alter table public.saved_jobs
  add column if not exists location text,
  add column if not exists job_type text,
  add column if not exists salary text,
  add column if not exists match_score integer;

create unique index if not exists saved_jobs_user_job_unique
  on public.saved_jobs (user_id, job_id);
