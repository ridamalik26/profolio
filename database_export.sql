-- ============================================================================
-- ProFolio — Complete Database Export
-- ============================================================================
-- Consolidated snapshot of the current schema (tables + RLS policies) for:
--   users, applications, saved_jobs, notifications
--
-- This is a point-in-time export for reference/backup/re-provisioning — the
-- source of truth for incremental changes is supabase/migrations/*.sql:
--   20260701000000_init_users_and_storage.sql
--   20260702000000_job_matching.sql
--   20260703000000_fix_applications_saved_jobs_columns.sql
--   20260704000000_notifications_and_settings.sql
--
-- Safe to re-run: every statement uses IF NOT EXISTS / OR REPLACE / DROP...
-- IF EXISTS guards. Run in the Supabase SQL editor (or via `supabase db push`
-- against a fresh project) to (re)create the full schema in one pass.
-- ============================================================================

-- ── Shared trigger function ──────────────────────────────────────────────────

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================================
-- Table: users
-- ============================================================================

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text,
  phone text,
  date_of_birth date,
  address text,
  education jsonb not null default '[]'::jsonb,
  experience jsonb not null default '[]'::jsonb,
  skills text[] not null default '{}'::text[],
  languages text[] not null default '{}'::text[],
  certifications jsonb not null default '[]'::jsonb,
  portfolio_url text,
  linkedin_url text,
  avatar_url text,
  resume_url text,
  resume_filename text,
  resume_uploaded_at timestamptz,
  resume_file_size_bytes integer,
  resume_content_type text,
  notification_prefs jsonb not null default
    '{"job_alerts": true, "status_updates": true, "recommendations": true}'::jsonb,
  is_public boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists "Users can view own row" on public.users;
create policy "Users can view own row"
  on public.users for select
  using (auth.uid() = id);

drop policy if exists "Users can insert own row" on public.users;
create policy "Users can insert own row"
  on public.users for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own row" on public.users;
create policy "Users can update own row"
  on public.users for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can delete own row" on public.users;
create policy "Users can delete own row"
  on public.users for delete
  using (auth.uid() = id);

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at
  before update on public.users
  for each row
  execute function public.set_updated_at();

-- ============================================================================
-- Table: applications
-- ============================================================================

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

-- ============================================================================
-- Table: saved_jobs
-- ============================================================================

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

-- ============================================================================
-- Table: notifications
-- ============================================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('job_alert', 'status_update', 'recommendation')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "Users can view own notifications" on public.notifications;
create policy "Users can view own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own notifications" on public.notifications;
create policy "Users can insert own notifications"
  on public.notifications for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can update own notifications"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own notifications" on public.notifications;
create policy "Users can delete own notifications"
  on public.notifications for delete
  using (auth.uid() = user_id);
