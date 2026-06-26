-- ============================================================
--  Amina & Mohammed Shamil — Nikah Invitation
--  Supabase schema, Row-Level Security, storage, and seed data
--  Run this in the Supabase SQL Editor (Project → SQL → New query).
-- ============================================================

-- ----------------------------------------------------------------
-- 1. RSVP TABLE
-- ----------------------------------------------------------------
create table if not exists public.rsvps (
  id                 uuid primary key default gen_random_uuid(),
  full_name          text not null,
  mobile_number      text not null,
  attendance_status  text not null check (attendance_status in ('yes','no')),
  adults             integer not null default 0,
  children           integer not null default 0,
  message            text,
  created_at         timestamptz not null default now()
);

-- If "no", force adults/children to 0 and require a message.
create or replace function public.rsvp_normalise()
returns trigger language plpgsql as $$
begin
  if new.attendance_status = 'no' then
    new.adults := 0;
    new.children := 0;
    if new.message is null or length(btrim(new.message)) = 0 then
      raise exception 'A message or reason is required when not attending.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_rsvp_normalise on public.rsvps;
create trigger trg_rsvp_normalise
  before insert or update on public.rsvps
  for each row execute function public.rsvp_normalise();

-- ----------------------------------------------------------------
-- 2. GUEST PHOTOS TABLE
-- ----------------------------------------------------------------
create table if not exists public.guest_photos (
  id               uuid primary key default gen_random_uuid(),
  guest_name       text not null,
  caption          text,
  image_url        text not null,
  storage_path     text not null,
  approval_status  text not null default 'pending'
                     check (approval_status in ('pending','approved','rejected')),
  featured         boolean not null default false,
  created_at       timestamptz not null default now()
);

create index if not exists guest_photos_status_idx
  on public.guest_photos (approval_status, featured desc, created_at desc);

-- ----------------------------------------------------------------
-- 3. WEBSITE SETTINGS TABLE
-- ----------------------------------------------------------------
create table if not exists public.website_settings (
  id            uuid primary key default gen_random_uuid(),
  setting_name  text not null unique,
  setting_value text not null,
  updated_at    timestamptz not null default now()
);

insert into public.website_settings (setting_name, setting_value) values
  ('rsvp_enabled',    'true'),
  ('uploads_enabled', 'true'),
  ('gallery_enabled', 'true'),
  ('auto_approve',    'false'),
  ('max_images',      '10'),
  ('music_enabled',   'true')
on conflict (setting_name) do nothing;

-- ============================================================
--  ROW-LEVEL SECURITY
-- ============================================================
alter table public.rsvps            enable row level security;
alter table public.guest_photos     enable row level security;
alter table public.website_settings enable row level security;

-- ---------- RSVPS ----------
-- Public (anon) may INSERT only. They may not read/update/delete.
drop policy if exists rsvps_public_insert on public.rsvps;
create policy rsvps_public_insert
  on public.rsvps for insert
  to anon, authenticated
  with check (true);

-- Authenticated admins may read / update / delete everything.
drop policy if exists rsvps_admin_select on public.rsvps;
create policy rsvps_admin_select
  on public.rsvps for select to authenticated using (true);

drop policy if exists rsvps_admin_update on public.rsvps;
create policy rsvps_admin_update
  on public.rsvps for update to authenticated using (true) with check (true);

drop policy if exists rsvps_admin_delete on public.rsvps;
create policy rsvps_admin_delete
  on public.rsvps for delete to authenticated using (true);

-- ---------- GUEST PHOTOS ----------
-- Public may INSERT new photos (always land as pending via app logic).
drop policy if exists photos_public_insert on public.guest_photos;
create policy photos_public_insert
  on public.guest_photos for insert
  to anon, authenticated
  with check (approval_status = 'pending' or approval_status = 'approved');

-- Public may SELECT only approved photos.
drop policy if exists photos_public_select_approved on public.guest_photos;
create policy photos_public_select_approved
  on public.guest_photos for select
  to anon
  using (approval_status = 'approved');

-- Admins may read everything and update / delete.
drop policy if exists photos_admin_select on public.guest_photos;
create policy photos_admin_select
  on public.guest_photos for select to authenticated using (true);

drop policy if exists photos_admin_update on public.guest_photos;
create policy photos_admin_update
  on public.guest_photos for update to authenticated using (true) with check (true);

drop policy if exists photos_admin_delete on public.guest_photos;
create policy photos_admin_delete
  on public.guest_photos for delete to authenticated using (true);

-- ---------- WEBSITE SETTINGS ----------
-- Public may READ settings (to honour enabled/disabled toggles).
drop policy if exists settings_public_select on public.website_settings;
create policy settings_public_select
  on public.website_settings for select to anon, authenticated using (true);

-- Only admins may change settings.
drop policy if exists settings_admin_write on public.website_settings;
create policy settings_admin_write
  on public.website_settings for all to authenticated using (true) with check (true);

-- ============================================================
--  STORAGE BUCKET: wedding-memories
-- ============================================================
insert into storage.buckets (id, name, public)
values ('wedding-memories','wedding-memories', true)
on conflict (id) do update set public = true;

-- Public may upload into the guest-uploads/ folder.
drop policy if exists storage_public_upload on storage.objects;
create policy storage_public_upload
  on storage.objects for insert
  to anon, authenticated
  with check (
    bucket_id = 'wedding-memories'
    and (storage.foldername(name))[1] = 'guest-uploads'
  );

-- Anyone may read files in this public bucket (needed for the gallery).
drop policy if exists storage_public_read on storage.objects;
create policy storage_public_read
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'wedding-memories');

-- Admins may delete files (used when an admin deletes a photo).
drop policy if exists storage_admin_delete on storage.objects;
create policy storage_admin_delete
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'wedding-memories');

-- ============================================================
--  REALTIME (optional but recommended)
--  Lets the public gallery refresh instantly when a photo is approved.
-- ============================================================
alter publication supabase_realtime add table public.guest_photos;

-- ============================================================
--  CREATE THE ADMIN ACCOUNT
--  Do NOT create users in SQL. Instead:
--   Supabase Dashboard → Authentication → Users → "Add user"
--   Enter the couple's/admin email + a strong password.
--   (Optionally disable public sign-ups under Authentication → Providers.)
--  Any authenticated user is treated as an admin by the policies above,
--  so keep sign-ups closed and only create trusted admin accounts.
-- ============================================================
