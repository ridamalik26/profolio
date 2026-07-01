-- ProFolio: users table, RLS policies, and storage buckets/policies.
-- Run this in the Supabase SQL editor (or via `supabase db push`).

-- ── users table ────────────────────────────────────────────────────────────

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

-- Keep updated_at fresh on every write.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at
  before update on public.users
  for each row
  execute function public.set_updated_at();

-- ── Storage buckets ───────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('resumes', 'resumes', false)
on conflict (id) do update set public = false;

-- ── Storage policies ──────────────────────────────────────────────────────
-- Files are stored at "<uid>/<filename>"; (storage.foldername(name))[1] is the
-- first path segment, i.e. the uid that owns the file.

-- avatars: public read, owner-only write/update/delete
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update own avatar" on storage.objects;
create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own avatar" on storage.objects;
create policy "Users can delete own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- resumes: fully private, owner-only read/write/update/delete
drop policy if exists "Users can read own resume" on storage.objects;
create policy "Users can read own resume"
  on storage.objects for select
  using (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can upload own resume" on storage.objects;
create policy "Users can upload own resume"
  on storage.objects for insert
  with check (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update own resume" on storage.objects;
create policy "Users can update own resume"
  on storage.objects for update
  using (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own resume" on storage.objects;
create policy "Users can delete own resume"
  on storage.objects for delete
  using (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
