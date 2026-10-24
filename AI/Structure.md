i want to make as Custom session management system using nextjs and supabase and jwt token based session management system
Admin can add multiple tool in admin page with complete Authentication and Authorization and admin have all permissions
USER AND ADMIN  first login from google and can add tools and user in same domain and user does not wait to permission default true can use tools from admin subaccount that is added from admin side but all share acount will same but token and session for see same data searched in past not can other user data see.
user can use all tools on same domain like seopark.org



staff-access-portal/
├── supabase/
│   ├── functions/                  # Supabase Edge Functions
│   │   ├── check-app-access/       # Authorization & expiry validation endpoint
│   │   │   └── index.ts
│   │   └── log-audit-event/        # Edge function to log access & security events
│   │       └── index.ts
│   ├── migrations/                 # DB schema (users, applications, grants, audit_logs)
│   │   └── 20261024000000_init_schema.sql
│   └── config.toml
├── src/
│   ├── app/                        # Next.js App Router Structure
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   │   └── page.tsx        # Google OAuth SSO sign-in page
│   │   │   └── auth/callback/
│   │   │       └── route.ts        # Supabase PKCE OAuth Callback Handler
│   │   ├── (dashboard)/
│   │   │   ├── layout.tsx          # Authenticated Layout with User Session Context
│   │   │   ├── page.tsx            # Staff Dashboard (Assigned App Tiles)
│   │   │   ├── admin/
│   │   │   │   ├── users/
│   │   │   │   │   └── page.tsx    # Admin User Activation & Allowlist
│   │   │   │   ├── apps/
│   │   │   │   │   └── page.tsx    # Admin Tool Management
│   │   │   │   ├── grants/
│   │   │   │   │   └── page.tsx    # Time-Limited Application Grants
│   │   │   │   └── audit-logs/
│   │   │   │       └── page.tsx    # Real-time Audit Trail Explorer
│   │   │   └── demo-app/
│   │   │       └── page.tsx        # Isolated Controlled Demo Target App
│   │   ├── api/                    # Client-side API Routes (for internal proxy checks)
│   │   │   └── launch/
│   │   │       └── route.ts        # Enforces session, expiry check & redirect
│   │   ├── tools/
│   │   │   └── [slug]/
│   │   │       └── page.tsx        # Dynamic Tool Handler & Token Verifier
│   │   ├── error.tsx
│   │   ├── layout.tsx
│   │   └── page.tsx                # Public Landing Page / Redirect to Login
│   ├── components/
│   │   ├── admin/
│   │   │   ├── UserStatusToggle.tsx
│   │   │   ├── TimeGrantModal.tsx
│   │   │   └── AuditLogTable.tsx
│   │   ├── dashboard/
│   │   │   ├── AppTile.tsx         # Displays app status, expiry countdown, launch button
│   │   │   └── Header.tsx
│   │   └── ui/                     # Reusable UI primitives (Button, Modal, Badge, Input)
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts           # Browser Supabase Client (`createBrowserClient`)
│   │   │   ├── server.ts           # Server Components / Route Handler Supabase Client
│   │   │   └── middleware.ts       # Supabase Session Refresher for Middleware
│   │   ├── types.ts                # TypeScript Interfaces (User, App, Grant, AuditLog)
│   │   └── utils.ts                # Date formatting, Expiry Calculators
│   └── middleware.ts               # Next.js Edge Middleware for Route Guarding
├── .env.example
├── next.config.mjs
├── package.json
└── tsconfig.json