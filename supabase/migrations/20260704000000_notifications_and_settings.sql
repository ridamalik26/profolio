-- ProFolio: notification center + settings (notification preferences, account
-- visibility). Run this in the Supabase SQL editor (or via `supabase db push`).

-- ── notifications table ──────────────────────────────────────────────────────

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

-- ── settings columns on users ────────────────────────────────────────────────

alter table public.users
  add column if not exists notification_prefs jsonb not null default
    '{"job_alerts": true, "status_updates": true, "recommendations": true}'::jsonb,
  add column if not exists is_public boolean not null default true;
