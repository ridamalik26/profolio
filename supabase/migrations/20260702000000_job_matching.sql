-- ProFolio: job applications + saved jobs tables and RLS policies.
-- Run this in the Supabase SQL editor (or via `supabase db push`).

-- ── applications table ──────────────────────────────────────────────────────

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id text not null,
  job_title text not null,
  company_name text not null,
  job_url text,
  location text,
  job_type text,
  salary text,
  match_score integer,
  status text not null default 'pending'
    check (status in ('pending', 'applied', 'accepted', 'rejected')),
  applicant_name text,
  applicant_email text,
  applicant_phone text,
  resume_url text,
  applied_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists applications_user_job_unique
  on public.applications (user_id, job_id);

alter table public.applications enable row level security;

drop policy if exists "Users can view own applications" on public.applications;
create policy "Users can view own applications"
  on public.applications for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own applications" on public.applications;
create policy "Users can insert own applications"
  on public.applications for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own applications" on public.applications;
create policy "Users can update own applications"
  on public.applications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own applications" on public.applications;
create policy "Users can delete own applications"
  on public.applications for delete
  using (auth.uid() = user_id);

drop trigger if exists set_applications_updated_at on public.applications;
create trigger set_applications_updated_at
  before update on public.applications
  for each row
  execute function public.set_updated_at();

-- ── saved_jobs table ─────────────────────────────────────────────────────────

create table if not exists public.saved_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id text not null,
  job_title text not null,
  company_name text not null,
  job_url text,
  location text,
  job_type text,
  salary text,
  match_score integer,
  saved_at timestamptz not null default now()
);

create unique index if not exists saved_jobs_user_job_unique
  on public.saved_jobs (user_id, job_id);

alter table public.saved_jobs enable row level security;

drop policy if exists "Users can view own saved jobs" on public.saved_jobs;
create policy "Users can view own saved jobs"
  on public.saved_jobs for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own saved jobs" on public.saved_jobs;
create policy "Users can insert own saved jobs"
  on public.saved_jobs for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own saved jobs" on public.saved_jobs;
create policy "Users can delete own saved jobs"
  on public.saved_jobs for delete
  using (auth.uid() = user_id);
