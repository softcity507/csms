-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table (Extends Supabase Auth Users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'staff')) DEFAULT 'staff',
  is_active BOOLEAN DEFAULT true, -- Requires Admin Approval/Activation
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Applications Inventory
CREATE TABLE public.applications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  target_url TEXT NOT NULL,
  is_demo BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Application Access Grants (Supports Time-Limited Access)
CREATE TABLE public.access_grants (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  app_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES public.profiles(id),
  expires_at TIMESTAMPTZ, -- NULL means permanent until revoked
  is_revoked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, app_id)
);

-- 4. Audit Trail Log Table
CREATE TABLE public.audit_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  actor_id UUID REFERENCES public.profiles(id),
  target_user_id UUID REFERENCES public.profiles(id),
  app_id UUID REFERENCES public.applications(id),
  action TEXT NOT NULL, -- e.g., 'LOGIN', 'APP_LAUNCH', 'GRANT_ACCESS', 'EXPIRE_ACCESS', 'REVOKE_ACCESS'
  outcome TEXT CHECK (outcome IN ('SUCCESS', 'DENIED', 'EXPIRED', 'FAILED')),
  ip_address TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.access_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;