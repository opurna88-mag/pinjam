-- ============================================================================
-- MIGRATION 001 — INITIAL SCHEMA
-- Sistem Peminjaman Ruang FIP UM
-- ----------------------------------------------------------------------------
-- Source of truth : docs/DATABASE_DESIGN.md  (v1.1, sections 1-4)
-- Business rules  : docs/BUSINESS_RULES.md   (section 2 = single source of
--                   limits; section 3 = overlap & expiry; section 6 = approval)
--
-- HOW TO RUN
--   Supabase Dashboard -> SQL Editor -> paste entire file -> Run.
--   Or: supabase db push
--
-- ORDER (do not reorder):
--   1  extensions            8  bookings
--   2  profiles              9  EXCLUDE constraint (anti double-booking)
--   3  rooms                10  performance indexes
--   4  room_facilities      11  helper fns (is_admin, expire_stale_bookings)
--   5  room_images          12  auth triggers (email domain, new user)
--   6  gallery_images       13  updated_at trigger
--   7  operating_hours      14  RLS policies
--                          15  grants
--                          16  public_calendar view
--                          17  pg_cron job
--
-- NON-GOALS (must stay in app code, never in SQL):
--   * slot granularity, min/max duration, submission window  -> lib/booking-rules.ts
--     (values live ONLY in docs/BUSINESS_RULES.md section 2)
--   * capacity check against rooms.capacity                  -> Zod + API
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS
-- ============================================================================
create extension if not exists "pgcrypto";    -- gen_random_uuid()
create extension if not exists "btree_gist";  -- required by EXCLUDE (room_id with =)
create extension if not exists "pg_cron";     -- scheduled expiry


-- ============================================================================
-- 2. PROFILES (extends auth.users)
-- ============================================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  full_name     text,
  phone_number  text,
  role          text not null default 'student'
                check (role in ('student', 'lecturer', 'admin')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table  public.profiles is 'Application profile, 1:1 with auth.users.';
comment on column public.profiles.role is 'student (default) | lecturer | admin. Roles are equal for booking; role only grants admin privileges.';


-- ============================================================================
-- 3. ROOMS
-- ============================================================================
create table if not exists public.rooms (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  code         text not null unique,
  capacity     integer not null check (capacity > 0),
  location     text,
  description  text,
  image_url    text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on column public.rooms.is_active is 'Inactive rooms are hidden from public search but keep their booking history.';


-- ============================================================================
-- 4. ROOM_FACILITIES  (rooms --< room_facilities)
-- NOTE: no profile_id here. v1.0 had a wrong relation to profiles.
-- ============================================================================
create table if not exists public.room_facilities (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.rooms(id) on delete cascade,
  facility    text not null,
  created_at  timestamptz not null default now(),
  constraint room_facilities_unique_per_room unique (room_id, facility)
);


-- ============================================================================
-- 5. ROOM_IMAGES
-- ============================================================================
create table if not exists public.room_images (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.rooms(id) on delete cascade,
  url         text not null,
  is_cover    boolean not null default false,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);

-- at most one cover image per room
create unique index if not exists room_images_one_cover_per_room
  on public.room_images (room_id)
  where is_cover = true;


-- ============================================================================
-- 6. GALLERY_IMAGES  (building / environment photos, admin managed)
-- ============================================================================
create table if not exists public.gallery_images (
  id          uuid primary key default gen_random_uuid(),
  url         text not null,
  caption     text,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);
-- ============================================================================
-- 6b. NOTIFICATION_LOGS  (audit + retry queue for email / WhatsApp delivery)
-- Rows are written by the service-role client after the API response is sent.
-- A failed delivery never rolls back a booking.
-- ============================================================================
create table if not exists public.notification_logs (
  id             uuid primary key default gen_random_uuid(),
  booking_id     uuid,
  user_id        uuid references public.profiles(id) on delete set null,
  channel        text not null check (channel in ('email', 'whatsapp')),
  event          text not null
                 check (event in ('submitted', 'approved', 'rejected', 'expired', 'cancelled')),
  recipient      text not null,
  status         text not null default 'pending'
                 check (status in ('sent', 'failed', 'pending')),
  attempts       smallint not null default 0,
  error_message  text,
  created_at     timestamptz not null default now()
);

comment on table public.notification_logs is 'Delivery audit for email/WhatsApp notifications. Failed rows are retried by /api/cron/send-notifications.';

create index if not exists notification_logs_status_idx
  on public.notification_logs (status, attempts);

create index if not exists notification_logs_booking_idx
  on public.notification_logs (booking_id);
-- ============================================================================
-- 7. OPERATING_HOURS  (per-day hours; NEVER hardcode closing time in app code)
-- Friday closes earlier than other days — see BUSINESS_RULES.md section 1.
-- day_of_week follows EXTRACT(DOW): 0 = Sunday ... 6 = Saturday
-- ============================================================================
create table if not exists public.operating_hours (
  day_of_week  smallint primary key check (day_of_week between 0 and 6),
  open_time    time not null,
  close_time   time not null,
  is_open      boolean not null default true,
  updated_at   timestamptz not null default now(),
  constraint operating_hours_close_after_open check (close_time > open_time)
);

insert into public.operating_hours (day_of_week, open_time, close_time, is_open) values
  (1, '07:00', '16:00', true),  -- Monday
  (2, '07:00', '16:00', true),  -- Tuesday
  (3, '07:00', '16:00', true),  -- Wednesday
  (4, '07:00', '16:00', true),  -- Thursday
  (5, '07:00', '14:30', true),  -- Friday  <-- shorter day, closes 14:30
  (6, '07:00', '16:00', true),  -- Saturday
  (0, '07:00', '16:00', true)   -- Sunday
on conflict (day_of_week) do update
  set open_time  = excluded.open_time,
      close_time = excluded.close_time,
      is_open    = excluded.is_open,
      updated_at = now();
-- ============================================================================
-- 8. BOOKINGS
-- status lifecycle: pending -> approved | rejected | cancelled | expired
--                   approved -> cancelled (owner, before the cancellation cutoff)
-- See BUSINESS_RULES.md section 6.3 for the allowed transitions.
-- ============================================================================
create table if not exists public.bookings (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles(id) on delete cascade,
  room_id            uuid not null references public.rooms(id) on delete restrict,
  start_time         timestamptz not null,
  end_time           timestamptz not null,
  activity_name      text not null,
  participant_count  integer not null check (participant_count > 0),
  person_in_charge   text not null,
  phone_number       text not null,
  purpose            text,
  status             text not null default 'pending'
                     check (status in ('pending', 'approved', 'rejected', 'cancelled', 'expired')),
  admin_note         text,
  approved_by        uuid references public.profiles(id),
  decided_at         timestamptz,
  terms_accepted_at  timestamptz not null default now(),
  terms_version      text not null default '1.0',
  cancel_reason      text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint bookings_end_after_start check (end_time > start_time)
);

comment on column public.bookings.admin_note is 'Required by API on approve/reject (min length enforced in app) — BUSINESS_RULES.md section 6.2.';
comment on column public.bookings.phone_number is 'PRIVATE. Must never be exposed through any public endpoint or view.';


-- ============================================================================
-- 9. ANTI DOUBLE-BOOKING  (authoritative layer, race-condition proof)
-- Only pending and approved block a slot. rejected/cancelled/expired do not.
-- Half-open range '[)' so 10:00-11:00 and 11:00-12:00 do NOT conflict.
-- See BUSINESS_RULES.md section 3.3.
-- ============================================================================
alter table public.bookings
  add constraint bookings_no_overlap
  exclude using gist (
    room_id with =,
    tstzrange(start_time, end_time, '[)') with &&
  ) where (status in ('pending', 'approved'));

-- notification_logs was created before bookings (it also references profiles),
-- so add its bookings FK now that the table exists.
alter table public.notification_logs
  drop constraint if exists notification_logs_booking_id_fkey;
alter table public.notification_logs
  add constraint notification_logs_booking_id_fkey
  foreign key (booking_id) references public.bookings(id) on delete cascade;


-- ============================================================================
-- 10. PERFORMANCE INDEXES
-- ============================================================================
create index if not exists bookings_room_time_idx
  on public.bookings (room_id, start_time, end_time);

create index if not exists bookings_user_idx
  on public.bookings (user_id, created_at desc);

create index if not exists bookings_status_idx
  on public.bookings (status);

create index if not exists room_facilities_room_idx
  on public.room_facilities (room_id);

create index if not exists room_images_room_idx
  on public.room_images (room_id, sort_order);


-- ============================================================================
-- 11. HELPER FUNCTIONS
-- ============================================================================

-- 11.1 is_admin()
-- SECURITY DEFINER avoids RLS recursion when policies on profiles reference
-- profiles itself (fixed bug #10).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.profiles
     where id = auth.uid()
       and role = 'admin'
  );
$$;

comment on function public.is_admin() is 'True when the current session user has role=admin. SECURITY DEFINER to prevent RLS recursion.';


-- 11.2 expire_stale_bookings()
-- Moves pending bookings past their expiry window to 'expired'.
-- The window value itself comes from BUSINESS_RULES.md section 3.4 and is
-- mirrored in lib/booking-rules.ts. Kept as an interval constant here because
-- SQL cannot import TypeScript; if the rule changes, update BOTH places.
create or replace function public.expire_stale_bookings()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  affected integer;
begin
  update public.bookings
     set status     = 'expired',
         updated_at = now()
   where status = 'pending'
     and now() > created_at + interval '72 hours';

  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- ============================================================================
-- 12. AUTH TRIGGERS
-- ============================================================================

-- 12.1 enforce_email_domain()
-- Second (authoritative) layer of campus-email enforcement.
-- The allowed domain list is also read from ALLOWED_EMAIL_DOMAINS in the API.
create or replace function public.enforce_email_domain()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email is null or new.email !~* '@um\.ac\.id$' then
    raise exception 'EMAIL_DOMAIN_NOT_ALLOWED'
      using hint = 'Use a @um.ac.id email address.';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_email_domain_trigger on auth.users;
create trigger enforce_email_domain_trigger
  before insert or update of email on auth.users
  for each row execute function public.enforce_email_domain();


-- 12.2 handle_new_user()
-- Creates the profile row on signup with the default role.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'student'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ============================================================================
-- 13. UPDATED_AT TRIGGER
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at_profiles on public.profiles;
create trigger set_updated_at_profiles
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_rooms on public.rooms;
create trigger set_updated_at_rooms
  before update on public.rooms
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_bookings on public.bookings;
create trigger set_updated_at_bookings
  before update on public.bookings
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_operating_hours on public.operating_hours;
create trigger set_updated_at_operating_hours
  before update on public.operating_hours
  for each row execute function public.set_updated_at();


-- ============================================================================
-- 14. ROW LEVEL SECURITY
-- ============================================================================
alter table public.profiles         enable row level security;
alter table public.rooms            enable row level security;
alter table public.room_facilities  enable row level security;
alter table public.room_images      enable row level security;
alter table public.gallery_images   enable row level security;
alter table public.operating_hours  enable row level security;
alter table public.bookings         enable row level security;
alter table public.notification_logs enable row level security;

-- ---------------------------------------------------------------------------
-- 14.1 profiles
-- ---------------------------------------------------------------------------
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
  on public.profiles for update
  to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- 14.2 rooms — four separate policies (v1.0 used one 'for all' that collided
-- with the public SELECT policy; fixed bug #2)
-- ---------------------------------------------------------------------------
drop policy if exists "rooms_select_public" on public.rooms;
create policy "rooms_select_public"
  on public.rooms for select
  using (is_active = true or public.is_admin());

drop policy if exists "rooms_insert_admin" on public.rooms;
create policy "rooms_insert_admin"
  on public.rooms for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "rooms_update_admin" on public.rooms;
create policy "rooms_update_admin"
  on public.rooms for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "rooms_delete_admin" on public.rooms;
create policy "rooms_delete_admin"
  on public.rooms for delete
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- 14.3 room_facilities / room_images / gallery_images — public read, admin write
-- ---------------------------------------------------------------------------
drop policy if exists "room_facilities_select_public" on public.room_facilities;
create policy "room_facilities_select_public"
  on public.room_facilities for select
  using (true);

drop policy if exists "room_facilities_write_admin" on public.room_facilities;
create policy "room_facilities_write_admin"
  on public.room_facilities for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "room_images_select_public" on public.room_images;
create policy "room_images_select_public"
  on public.room_images for select
  using (true);

drop policy if exists "room_images_write_admin" on public.room_images;
create policy "room_images_write_admin"
  on public.room_images for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "gallery_images_select_public" on public.gallery_images;
create policy "gallery_images_select_public"
  on public.gallery_images for select
  using (true);

drop policy if exists "gallery_images_write_admin" on public.gallery_images;
create policy "gallery_images_write_admin"
  on public.gallery_images for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- 14.4 operating_hours — public read, admin update
-- ---------------------------------------------------------------------------
drop policy if exists "operating_hours_select_public" on public.operating_hours;
create policy "operating_hours_select_public"
  on public.operating_hours for select
  using (true);

drop policy if exists "operating_hours_update_admin" on public.operating_hours;
create policy "operating_hours_update_admin"
  on public.operating_hours for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- 14.5 bookings — owner or admin only. There is NO public SELECT policy:
-- the public calendar reads the public_calendar view instead (bug #11).
-- ---------------------------------------------------------------------------
drop policy if exists "bookings_select_own_or_admin" on public.bookings;
create policy "bookings_select_own_or_admin"
  on public.bookings for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "bookings_insert_own" on public.bookings;
create policy "bookings_insert_own"
  on public.bookings for insert
  to authenticated
  with check (user_id = auth.uid() and status = 'pending');

drop policy if exists "bookings_update_admin" on public.bookings;
create policy "bookings_update_admin"
  on public.bookings for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "bookings_cancel_own" on public.bookings;
create policy "bookings_cancel_own"
  on public.bookings for update
  to authenticated
  using (user_id = auth.uid() and status in ('pending', 'approved'))
  with check (user_id = auth.uid() and status = 'cancelled');

drop policy if exists "bookings_delete_admin" on public.bookings;
create policy "bookings_delete_admin"
  on public.bookings for delete
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- 14.6 notification_logs — admin read only. Writes come from the service role
-- client (lib/supabase/admin.ts) which bypasses RLS, so no INSERT policy here.
-- ---------------------------------------------------------------------------
drop policy if exists "notification_logs_select_admin" on public.notification_logs;
create policy "notification_logs_select_admin"
  on public.notification_logs for select
  to authenticated
  using (public.is_admin());
-- ============================================================================
-- 15. GRANTS
-- RLS still governs row access; these grants only allow the roles to attempt
-- queries. anon gets read-only on the public catalogue.
-- ============================================================================
grant usage on schema public to anon, authenticated;

grant select on public.rooms, public.room_facilities, public.room_images,
                public.gallery_images, public.operating_hours
  to anon, authenticated;

grant select, insert, update, delete on public.rooms,
                                          public.room_facilities,
                                          public.room_images,
                                          public.gallery_images
  to authenticated;

grant select, insert, update on public.bookings to authenticated;
grant delete on public.bookings to authenticated;

grant select, update on public.profiles to authenticated;

grant select on public.notification_logs to authenticated;
grant update on public.operating_hours to authenticated;


-- ============================================================================
-- 16. PUBLIC CALENDAR VIEW
-- Limited column set on purpose: phone_number, admin_note, user_id and any
-- email are NOT exposed. Bug #11 was a leaking public calendar.
-- security_invoker = off so the view can read bookings without an
-- owner/admin RLS match; it is queried through the server client.
-- ============================================================================
create or replace view public.public_calendar
with (security_invoker = off) as
select
  b.id,
  b.room_id,
  r.code            as room_code,
  r.name            as room_name,
  b.start_time,
  b.end_time,
  b.activity_name,
  b.person_in_charge,
  b.status
from public.bookings b
join public.rooms r on r.id = b.room_id
where b.status in ('pending', 'approved');

comment on view public.public_calendar is 'Public calendar projection. Intentionally omits phone_number, admin_note and user_id.';

grant select on public.public_calendar to anon, authenticated;


-- ============================================================================
-- 17. PG_CRON — expire stale pending bookings
-- Interval mirrors BUSINESS_RULES.md section 3.4 (checked every 10 minutes).
-- ============================================================================
select cron.unschedule('expire-stale-bookings')
where exists (select 1 from cron.job where jobname = 'expire-stale-bookings');

select cron.schedule(
  'expire-stale-bookings',
  '*/10 * * * *',
  $$ select public.expire_stale_bookings(); $$
);
-- ============================================================================
-- 18. VERIFICATION (run manually after the migration, all read-only)
-- ============================================================================
-- 18.1 RLS must be enabled on every table -> all rows should show rowsecurity = true
--   select tablename, rowsecurity
--     from pg_tables
--    where schemaname = 'public'
--    order by tablename;

-- 18.2 Anti double-booking constraint must exist -> 1 row
--   select conname from pg_constraint where conname = 'bookings_no_overlap';

-- 18.3 Friday must close at 14:30 -> close_time = 14:30:00
--   select day_of_week, open_time, close_time from public.operating_hours
--    where day_of_week = 5;

-- 18.4 Public calendar must NOT leak private columns -> 0 rows expected
--   select column_name
--     from information_schema.columns
--    where table_name = 'public_calendar'
--      and column_name in ('phone_number', 'admin_note', 'user_id');

-- 18.5 Cron job registered -> 1 row
--   select jobname, schedule, active from cron.job where jobname = 'expire-stale-bookings';

-- 18.6 Overlap must actually be rejected. Run inside a transaction and roll back:
--   begin;
--     -- insert two overlapping pending rows for the same room -> 2nd must fail 23P01
--   rollback;

-- ============================================================================
-- NEXT STEP: run docs/seed/seed.sql (15 rooms + 70 demo bookings).
-- ============================================================================