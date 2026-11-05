-- PP304 COMMAND / fresh Supabase project only.
-- Apply ONLY after creating a dedicated project, never to Smart Meeting AI.
-- Supabase Auth: create users through Auth > Users, then enable the user profile below.

create extension if not exists btree_gist with schema extensions;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'viewer' check (role in ('admin','editor','viewer')),
  enabled boolean not null default false,
  created_at timestamptz not null default now()
);

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Trigger in a non-exposed schema. Newly invited users are DISABLED by default.
create or replace function private.create_pp304_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.email, ''))
  on conflict (user_id) do nothing;
  return new;
end; $$;

drop trigger if exists on_pp304_auth_user_created on auth.users;
create trigger on_pp304_auth_user_created
  after insert on auth.users for each row
  execute function private.create_pp304_profile();

create table if not exists public.personnel (
  id text primary key,
  name text not null,
  group_name text not null default '',
  position text not null default '',
  post text not null default '',
  joined_at date,
  active boolean not null default true,
  source text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.team_assignments (
  id text primary key,
  code text not null,
  effective_from date not null,
  p1 text not null default '',
  p2 text not null default '',
  vehicle text not null default '',
  source text not null default '',
  updated_at timestamptz not null default now(),
  constraint unique_team_effective unique(code,effective_from)
);

create table if not exists public.duty_schedules (
  id text primary key,
  date date not null,
  shift smallint not null check(shift in (1,2,3)),
  kind text not null default '',
  code text not null,
  team_code text not null default '',
  display_code text not null default '',
  area text not null default '',
  updated_at timestamptz not null default now(),
  constraint unique_duty_slot unique(date,shift,team_code)
);
create index if not exists duty_schedules_date_idx on public.duty_schedules(date);

create table if not exists public.duty_replacements (
  id text primary key,
  date date not null,
  shift smallint not null check(shift in (1,2,3)),
  code text not null,
  original_name text not null default '',
  substitute_name text not null default '',
  vehicle text not null default '',
  reason text not null default '',
  updated_at timestamptz not null default now()
);
create index if not exists replacements_date_idx on public.duty_replacements(date);

create table if not exists public.post_assignments (
  id text primary key,
  post text not null,
  slot smallint not null,
  effective_from date not null,
  primary_name text not null,
  support_name text not null default '',
  active boolean not null default true,
  source text not null default '',
  updated_at timestamptz not null default now(),
  constraint unique_post_effective unique(post,slot,effective_from)
);

create table if not exists public.leaves (
  id text primary key,
  personnel_id text not null references public.personnel(id) on delete restrict,
  name text not null,
  start_date date not null,
  end_date date not null,
  type text not null check(length(trim(type)) > 0),
  status text not null default 'บันทึก' check(status in ('บันทึก','รออนุมัติ','อนุมัติ','ยกเลิก')),
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_leave_dates check(start_date <= end_date),
  constraint leave_max_days check (end_date - start_date <= 366),
  constraint no_overlapping_active_leave exclude using gist
    (personnel_id with =, daterange(start_date,end_date,'[]') with &&)
    where (status <> 'ยกเลิก')
);
create index if not exists leaves_start_end_idx on public.leaves(start_date,end_date);

create or replace function private.pp304_touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;

do $$ declare t text; begin
  foreach t in array array['personnel','team_assignments','duty_schedules','duty_replacements','post_assignments','leaves'] loop
    execute format('drop trigger if exists pp304_touch on public.%I', t);
    execute format('create trigger pp304_touch before update on public.%I for each row execute function private.pp304_touch_updated_at()', t);
  end loop;
end $$;

alter table public.profiles enable row level security;
create policy "users can read own PP304 profile" on public.profiles
  for select to authenticated using (user_id = (select auth.uid()));

-- Membership is granted only via the Supabase dashboard / protected administrator workflow.
-- A signed-up, unapproved, or anonymous user cannot read operational/personnel data.
do $$ declare t text; begin
  foreach t in array array['personnel','team_assignments','duty_schedules','duty_replacements','post_assignments','leaves'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on public.%I from public, anon, authenticated',t);
    execute format('grant select, insert, update, delete on public.%I to authenticated',t);
    execute format($fmt$create policy "PP304 member reads %1$s" on public.%1$I for select to authenticated using (
      exists (select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.enabled=true)
    )$fmt$,t);
    execute format($fmt$create policy "PP304 editor inserts %1$s" on public.%1$I for insert to authenticated with check (
      exists (select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.enabled=true and p.role in ('admin','editor'))
    )$fmt$,t);
    execute format($fmt$create policy "PP304 editor updates %1$s" on public.%1$I for update to authenticated using (
      exists (select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.enabled=true and p.role in ('admin','editor'))
    ) with check (
      exists (select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.enabled=true and p.role in ('admin','editor'))
    )$fmt$,t);
    execute format($fmt$create policy "PP304 editor deletes %1$s" on public.%1$I for delete to authenticated using (
      exists (select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.enabled=true and p.role in ('admin','editor'))
    )$fmt$,t);
  end loop;
end $$;

revoke all on public.profiles from public, anon, authenticated;
grant select on public.profiles to authenticated;

-- Existing authentications may lack profiles if the table is applied to a reused project.
insert into public.profiles(user_id,display_name)
select u.id,coalesce(u.email,'') from auth.users u
on conflict (user_id) do nothing;

-- To activate the first ADMIN after they exist in Authentication > Users:
-- update public.profiles set role='admin', enabled=true
-- where user_id=(select id from auth.users where email='admin@example.org');

-- Optional Realtime; may require publication privileges. If this fails, manual refresh still works.
-- alter publication supabase_realtime add table public.personnel, public.team_assignments,
--   public.duty_schedules, public.duty_replacements, public.post_assignments, public.leaves;
