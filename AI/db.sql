 

begin;

-- 1. Application identities and per-user allowlist
create table public.user_allowlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  role text not null default 'staff'
    check (role in ('admin', 'staff')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index user_allowlist_email_lower_key
  on public.user_allowlist (lower(email));

-- IMPORTANT: replace the address with the actual owner/admin Google identity.
-- This creates no usable admin while left as the example address.
insert into public.user_allowlist (email, role, is_active)
values ('sadaqatali507bscs@gmail.com', 'admin', true);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  role text not null default 'staff'
    check (role in ('admin', 'staff')),
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index profiles_email_lower_key on public.profiles (lower(email));

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  slug text not null unique
    check (slug ~ '^[a-z0-9]+([_-][a-z0-9]+)*$'),
  target_url text not null check (target_url ~* '^https?://'),
  is_active boolean not null default true,
  -- This records the verified launch category; it does not make a vendor
  -- integration work by itself. Keep pending/blocked until verified.
  launch_type text not null default 'pending'
    check (launch_type in (
      'pending', 'vendor_sso', 'enterprise_launcher',
      'existing_session', 'demo', 'blocked'
    )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.access_grants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  app_id uuid not null references public.applications (id) on delete cascade,
  is_revoked boolean not null default false,
  expires_at timestamptz,
  created_by uuid references public.profiles (id) on delete set null,
  updated_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, app_id)
);

create index access_grants_user_id_idx on public.access_grants (user_id);
create index access_grants_app_id_idx on public.access_grants (app_id);

-- Inventory fields support the assessment's dated, evidence-based feasibility
-- review. Store documentation references and findings, never vendor secrets.
create table public.application_assessments (
  id uuid primary key default gen_random_uuid(),
  app_id uuid not null references public.applications (id) on delete cascade,
  checked_at timestamptz not null default now(),
  checked_by uuid references public.profiles (id) on delete set null,
  account_owner text,
  plan_name text,
  login_methods text[] not null default '{}',
  mfa_requirements text,
  staff_account_model text,
  supported_flow text not null default 'unknown'
    check (supported_flow in (
      'unknown', 'vendor_sso', 'enterprise_launcher',
      'existing_session', 'unsupported'
    )),
  first_login_behavior text,
  repeat_login_behavior text,
  revocation_behavior text,
  prerequisites text,
  cost_notes text,
  blockers text,
  recommendation text,
  evidence jsonb not null default '[]'::jsonb
    check (jsonb_typeof(evidence) = 'array'),
  created_at timestamptz not null default now()
);

create index application_assessments_app_checked_idx
  on public.application_assessments (app_id, checked_at desc);

-- Audit events are append-only. Do not put credentials, cookies, tokens,
-- authorization headers, or sensitive vendor data in details.
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id) on delete set null,
  subject_user_id uuid references public.profiles (id) on delete set null,
  app_id uuid references public.applications (id) on delete set null,
  action text not null check (length(trim(action)) > 0),
  outcome text not null default 'success'
    check (outcome in ('success', 'denied', 'failure', 'info')),
  details jsonb not null default '{}'::jsonb
    check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);

create index audit_logs_created_at_idx on public.audit_logs (created_at desc);
create index audit_logs_actor_id_idx on public.audit_logs (actor_id);
create index audit_logs_subject_user_id_idx on public.audit_logs (subject_user_id);
create index audit_logs_app_id_idx on public.audit_logs (app_id);

-- Synthetic, user-scoped records for the controlled demonstration only.
create table public.demo_records (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index demo_records_owner_id_idx on public.demo_records (owner_id);

-- 2. Timestamp and authorization helpers
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- SECURITY DEFINER helpers avoid recursive profile RLS checks. The owner of
-- these functions must remain a trusted database role (normally postgres).
create function public.is_portal_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.role = 'admin'
      and p.is_active = true
  );
$$;

create function public.is_active_portal_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.is_active = true
  );
$$;

create function public.can_access_application(p_app_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_portal_user()
    and exists (
      select 1
      from public.access_grants g
      join public.applications a on a.id = g.app_id
      where g.user_id = (select auth.uid())
        and g.app_id = p_app_id
        and g.is_revoked = false
        and (g.expires_at is null or g.expires_at > now())
        and a.is_active = true
    );
$$;

-- Creates a profile for every Supabase Auth user. Only an email explicitly
-- present in user_allowlist is enabled; unlisted/unknown users stay disabled.
create function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_allowed public.user_allowlist%rowtype;
  v_email text;
begin
  v_email := lower(trim(coalesce(new.email, '')));

  select * into v_allowed
  from public.user_allowlist ua
  where lower(ua.email) = v_email
  limit 1;

  insert into public.profiles (id, email, role, is_active)
  values (
    new.id,
    v_email,
    coalesce(v_allowed.role, 'staff'),
    coalesce(v_allowed.is_active, false)
  )
  on conflict (id) do update
    set email = excluded.email,
        role = excluded.role,
        is_active = excluded.is_active,
        updated_at = now();

  insert into public.audit_logs (
    actor_id, subject_user_id, action, outcome, details
  ) values (
    null, new.id, 'identity.signup', 'info',
    jsonb_build_object('allowlisted', v_allowed.id is not null)
  );

  return new;
end;
$$;

-- When an admin changes the allowlist, update any matching existing profile.
-- Removing an allowlist entry disables the profile and demotes it to staff.
create function public.sync_allowlist_to_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  if tg_op = 'DELETE' then
    v_email := lower(old.email);
    update public.profiles
      set role = 'staff', is_active = false, updated_at = now()
      where lower(email) = v_email;
    return old;
  end if;

  v_email := lower(new.email);
  if tg_op = 'UPDATE' and lower(old.email) <> v_email then
    -- Changing an allowlist address must also revoke the old identity.
    update public.profiles
      set role = 'staff', is_active = false, updated_at = now()
      where lower(email) = lower(old.email);
  end if;
  update public.profiles
    set role = new.role, is_active = new.is_active, updated_at = now()
    where lower(email) = v_email;

  return new;
end;
$$;

-- Database-side audit for admin/configuration changes. Login and launch
-- outcomes should also be written by trusted server code using service role.
create function public.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row jsonb;
  v_old jsonb;
  v_actor uuid;
  v_subject uuid;
  v_app uuid;
  v_action text;
begin
  v_actor := auth.uid();
  if tg_op = 'DELETE' then
    v_row := to_jsonb(old);
    v_old := v_row;
    v_action := lower(tg_table_name) || '.deleted';
  elsif tg_op = 'UPDATE' then
    v_row := to_jsonb(new);
    v_old := to_jsonb(old);
    v_action := lower(tg_table_name) || '.updated';
  else
    v_row := to_jsonb(new);
    v_action := lower(tg_table_name) || '.created';
  end if;

  if tg_table_name = 'profiles' then
    v_subject := coalesce((v_row ->> 'id')::uuid, (v_old ->> 'id')::uuid);
  elsif tg_table_name = 'access_grants' then
    v_subject := coalesce((v_row ->> 'user_id')::uuid, (v_old ->> 'user_id')::uuid);
    v_app := coalesce((v_row ->> 'app_id')::uuid, (v_old ->> 'app_id')::uuid);
    if tg_op = 'UPDATE' and coalesce((v_row ->> 'is_revoked')::boolean, false)
       and not coalesce((v_old ->> 'is_revoked')::boolean, false) then
      v_action := 'grant.revoked';
    end if;
  elsif tg_table_name = 'applications' then
    v_app := coalesce((v_row ->> 'id')::uuid, (v_old ->> 'id')::uuid);
  elsif tg_table_name = 'application_assessments' then
    v_app := coalesce((v_row ->> 'app_id')::uuid, (v_old ->> 'app_id')::uuid);
  elsif tg_table_name = 'user_allowlist' then
    v_action := 'allowlist.' || case tg_op
      when 'INSERT' then 'created'
      when 'UPDATE' then 'updated'
      else 'deleted'
    end;
  end if;

  insert into public.audit_logs (
    actor_id, subject_user_id, app_id, action, outcome, details
  ) values (
    v_actor,
    v_subject,
    v_app,
    v_action,
    'success',
    jsonb_build_object(
      'table', tg_table_name,
      'operation', tg_op,
      'new', case when tg_op = 'DELETE' then null else v_row end,
      'old', case when tg_op = 'INSERT' then null else v_old end
    )
  );

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

create trigger auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create trigger allowlist_sync_profile
  after insert or update or delete on public.user_allowlist
  for each row execute function public.sync_allowlist_to_profile();

create trigger user_allowlist_updated_at
  before update on public.user_allowlist
  for each row execute function public.set_updated_at();

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger applications_updated_at
  before update on public.applications
  for each row execute function public.set_updated_at();

create trigger access_grants_updated_at
  before update on public.access_grants
  for each row execute function public.set_updated_at();

create trigger demo_records_updated_at
  before update on public.demo_records
  for each row execute function public.set_updated_at();

create trigger audit_user_allowlist
  after insert or update or delete on public.user_allowlist
  for each row execute function public.audit_row_change();

create trigger audit_profiles
  after insert or update or delete on public.profiles
  for each row execute function public.audit_row_change();

create trigger audit_applications
  after insert or update or delete on public.applications
  for each row execute function public.audit_row_change();

create trigger audit_access_grants
  after insert or update or delete on public.access_grants
  for each row execute function public.audit_row_change();

create trigger audit_application_assessments
  after insert or update or delete on public.application_assessments
  for each row execute function public.audit_row_change();

-- 3. Row Level Security
alter table public.user_allowlist enable row level security;
alter table public.profiles enable row level security;
alter table public.applications enable row level security;
alter table public.access_grants enable row level security;
alter table public.application_assessments enable row level security;
alter table public.audit_logs enable row level security;
alter table public.demo_records enable row level security;

-- Allowlist: active admins only. Signup trigger uses SECURITY DEFINER and does
-- not expose the allowlist to anonymous users or ordinary staff.
create policy "Admins can read allowlist"
  on public.user_allowlist for select to authenticated
  using ((select public.is_portal_admin()));
create policy "Admins can add allowlist entries"
  on public.user_allowlist for insert to authenticated
  with check ((select public.is_portal_admin()));
create policy "Admins can update allowlist entries"
  on public.user_allowlist for update to authenticated
  using ((select public.is_portal_admin()))
  with check ((select public.is_portal_admin()));
create policy "Admins can remove allowlist entries"
  on public.user_allowlist for delete to authenticated
  using ((select public.is_portal_admin()));

-- Profiles: users read their own; admins read all and may only change active
-- status. Role changes happen through the protected allowlist table.
create policy "Users read their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "Admins read all profiles"
  on public.profiles for select to authenticated
  using ((select public.is_portal_admin()));
create policy "Admins update profile active status"
  on public.profiles for update to authenticated
  using ((select public.is_portal_admin()))
  with check ((select public.is_portal_admin()));

-- Applications: admins see/manage the catalog; active staff see only active
-- applications for which they have a currently valid assignment.
create policy "Admins manage applications"
  on public.applications for all to authenticated
  using ((select public.is_portal_admin()))
  with check ((select public.is_portal_admin()));
create policy "Users read applications with valid grants"
  on public.applications for select to authenticated
  using ((select public.can_access_application(id)));

-- Grants: a user may inspect their own grant status, including revoked or
-- expired rows. Only admins may create/update/revoke/delete grants.
create policy "Users read their own grants"
  on public.access_grants for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Admins manage grants"
  on public.access_grants for all to authenticated
  using ((select public.is_portal_admin()))
  with check ((select public.is_portal_admin()));

-- Feasibility evidence is admin-only. Do not store secrets in evidence.
create policy "Admins manage application assessments"
  on public.application_assessments for all to authenticated
  using ((select public.is_portal_admin()))
  with check ((select public.is_portal_admin()));

-- Audit events are visible only to admins and immutable to authenticated users.
-- Trusted server code/service_role can write login, launch, and denied events.
create policy "Admins read audit logs"
  on public.audit_logs for select to authenticated
  using ((select public.is_portal_admin()));

-- Demo records are synthetic and isolated by owner. Access also requires an
-- active profile; seed them server-side for the controlled test identities.
create policy "Users read their own demo records"
  on public.demo_records for select to authenticated
  using (owner_id = (select auth.uid()) and (select public.is_active_portal_user()));
create policy "Users create their own demo records"
  on public.demo_records for insert to authenticated
  with check (owner_id = (select auth.uid()) and (select public.is_active_portal_user()));
create policy "Users update their own demo records"
  on public.demo_records for update to authenticated
  using (owner_id = (select auth.uid()) and (select public.is_active_portal_user()))
  with check (owner_id = (select auth.uid()) and (select public.is_active_portal_user()));
create policy "Users delete their own demo records"
  on public.demo_records for delete to authenticated
  using (owner_id = (select auth.uid()) and (select public.is_active_portal_user()));

-- 4. Explicit table/function privileges. RLS policies are not a substitute for
-- SQL privileges. Authenticated users cannot insert profiles or directly alter
-- roles; service_role is reserved for trusted server-side operations only.
revoke all on public.user_allowlist from anon, authenticated;
revoke all on public.profiles from anon, authenticated;
revoke all on public.applications from anon, authenticated;
revoke all on public.access_grants from anon, authenticated;
revoke all on public.application_assessments from anon, authenticated;
revoke all on public.audit_logs from anon, authenticated;
revoke all on public.demo_records from anon, authenticated;

grant select, insert, update, delete on public.user_allowlist to authenticated;
grant select on public.profiles to authenticated;
grant update (is_active) on public.profiles to authenticated;
grant select on public.applications to authenticated;
grant select on public.access_grants to authenticated;
grant insert, update, delete on public.access_grants to authenticated;
grant select, insert, update, delete on public.application_assessments to authenticated;
grant select on public.audit_logs to authenticated;
grant select, insert, update, delete on public.demo_records to authenticated;

grant usage on schema public to authenticated;
revoke all on function public.is_portal_admin() from public, anon;
revoke all on function public.is_active_portal_user() from public, anon;
revoke all on function public.can_access_application(uuid) from public, anon;
grant execute on function public.is_portal_admin() to authenticated;
grant execute on function public.is_active_portal_user() to authenticated;
grant execute on function public.can_access_application(uuid) to authenticated;
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
revoke all on function public.sync_allowlist_to_profile() from public, anon, authenticated;
revoke all on function public.audit_row_change() from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;

commit;

-- Follow-up setup in Supabase:
-- 1. Replace sadaqatali507bscs@gmail.com above with the real owner Google email.
-- 2. Enable Google under Authentication > Sign In / Providers and configure
--    the exact callback URL shown by Supabase for your project.
-- 3. Add each approved staff email to user_allowlist before they sign in.
-- 4. Add applications and grants only after the feasibility review/owner
--    approval. Existing vendor sessions may remain open after portal revoke.
-- 5. Have server code write identity.login, app.launch, and access.denied audit
--    events using a server-only service-role client. Never expose that key.
-- 6. Verify with one admin, two staff with different grants, a disabled user,
--    an expired grant, and a revoked grant before using any real integration.
