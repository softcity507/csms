Here is a comprehensive, phased master plan consisting of **32 granular steps** designed for an AI agent or developer to build, test, verify, and push this secure Supabase + Next.js App Router application portal to GitHub.

---

## Phase 1: Project Initialization & Environment Setup

* **Step 1:** Initialize a new Next.js project with TypeScript, Tailwind CSS, and App Router (`npx create-next-app@latest . --typescript --tailwind --app`).
* **Step 2:** Install essential dependencies (`@supabase/supabase-js`, `@supabase/ssr`, `lucide-react`, `clsx`, `tailwind-merge`).
* **Step 3:** Create local environment configuration files (`.env.local` and `.env.example`) defining `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`.
* **Step 4:** Set up the directory structure matching your proposed architecture (`app/`, `components/`, `lib/`, `supabase/`).

---

## Phase 2: Database Setup & Supabase Configuration

* **Step 5:** Create a new project on Supabase and link it locally via the Supabase CLI (`supabase link`).
* **Step 6:** Create the initial migration file under `supabase/migrations/` and paste the provided SQL schema (Tables, Indexes, Functions, Triggers, and RLS policies).
* **Step 7:** Update the admin bootstrap email in the migration (`sadaqatali507bscs@gmail.com` or your production admin email) and run the migration (`supabase db push`).
* **Step 8:** Configure Google OAuth provider in the Supabase Dashboard under **Authentication > Providers**, adding the correct callback URL.

---

## Phase 3: Core Library & Supabase Client Setup

* **Step 9:** Build `lib/supabase/client.ts` to instantiate the browser client using `createBrowserClient` from `@supabase/ssr`.
* **Step 10:** Build `lib/supabase/server.ts` to handle server-side cookie management and create server clients using `createServerClient`.
* **Step 11:** Implement `lib/auth/` utilities to check active user sessions, fetch profile metadata, and verify roles.
* **Step 12:** Implement `lib/access/` and `lib/audit/` helper functions to check access grants, log actions, and evaluate application expiry rules server-side.

---

## Phase 4: Authentication & Routing Shell

* **Step 13:** Create the public entry point at `app/page.tsx` that inspects session state and redirects users to `/login` or `/` (portal dashboard).
* **Step 14:** Implement the login page at `app/(auth)/login/page.tsx` featuring a secure Google Sign-In button utilizing Supabase Auth.
* **Step 15:** Implement the auth callback route handler at `app/(auth)/auth/callback/route.ts` to exchange authorization codes for active sessions.
* **Step 16:** Create the authenticated portal shell layout at `app/(portal)/layout.tsx` enforcing active session and user status checks.

---

## Phase 5: Portal Dashboard & User Features

* **Step 17:** Build the assigned application dashboard at `app/(portal)/page.tsx` displaying active applications granted to the logged-in user.
* **Step 18:** Build reusable UI primitives and dashboard components under `components/ui/` and `components/dashboard/` (e.g., App Cards, Navigation Bar).
* **Step 19:** Implement the controlled synthetic demo records page at `app/(portal)/demo/[recordId]/page.tsx` with user-scoped CRUD operations.

---

## Phase 6: Admin Dashboard Implementation

* **Step 20:** Create the admin layout and navigation tab shell restricting access strictly to users where `is_portal_admin()` evaluates to true.
* **Step 21:** Implement the user management view at `app/(portal)/admin/users/page.tsx` to view allowlist entries, profiles, and active status controls.
* **Step 22:** Implement the application catalog view at `app/(portal)/admin/applications/page.tsx` for managing registered applications and launch types.
* **Step 23:** Implement the access grants view at `app/(portal)/admin/grants/page.tsx` for provisioning and revoking per-user assignments with optional expiry dates.
* **Step 24:** Implement the filterable audit log view at `app/(portal)/admin/audit/page.tsx` to inspect security events, mutations, and outcomes.

---

## Phase 7: API Routes, Launch Mechanism & Audit Logging

* **Step 25:** Build the secure server-side launcher API route at `app/api/launch/[slug]/route.ts` that verifies active grants, checks application status, and issues audit logs.
* **Step 26:** Integrate server-side audit event logging for login success, app launches, and access denials using the service role client.
* **Step 27:** Create form validation and error handling for all admin panels and user data inputs.

---

## Phase 8: Comprehensive Testing & Quality Assurance

* **Step 28:** Test **Admin Privileges**: Log in with the primary admin account (`sadaqatali507bscs@gmail.com`) and verify access to all admin views and management capabilities.
* **Step 29:** Test **Staff Access & Allowlisting**: Add a test staff email to `user_allowlist`, sign in via Google, and verify that profile creation triggers correctly and grants work as intended.
* **Step 30:** Test **Revocation & Expiry**: Revoke an access grant or set an expired timestamp, then attempt to launch the application to verify that access is blocked and logged correctly in audit trails.

---

## Phase 9: Final Review & GitHub Push

* **Step 31:** Run a final code lint and build test (`npm run build`) to ensure zero TypeScript or build errors.
* **Step 32:** Initialize Git, stage all verified files, commit with a descriptive message, and push the completed repository to GitHub (`git remote add origin <url>`, `git push -u origin main`).