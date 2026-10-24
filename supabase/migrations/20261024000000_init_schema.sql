create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique not null,
  role text not null default 'staff' check (role in ('admin', 'staff')),
  is_active boolean not null default false, -- Requires admin approval by default
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table public.applications (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  slug text unique not null,
  target_url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table public.access_grants (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  app_id uuid references public.applications(id) on delete cascade not null,
  is_revoked boolean not null default false,
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique (user_id, app_id)
);

create table public.audit_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  details jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.applications enable row level security;
alter table public.access_grants enable row level security;
alter table public.audit_logs enable row level security;

-- RLS Policies
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Admins can update profiles" on public.profiles for update using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

create policy "Active users can view applications" on public.applications for select using (
  exists (select 1 from public.profiles where id = auth.uid() and is_active = true)
);
create policy "Admins can manage applications" on public.applications for all using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

create policy "Users can view own grants" on public.access_grants for select using (user_id = auth.uid());
create policy "Admins can manage grants" on public.access_grants for all using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);