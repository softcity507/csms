# Staff Access Portal — Repository and Delivery Structure

This repository currently contains a minimal Next.js App Router starter and an initial Supabase schema. The assessment's proposed portal is not implemented yet. Keep new code in the existing root-level `app/` structure unless the project is deliberately migrated; do not document a nonexistent `src/` tree as current.


There is no `src/` directory. Current dependencies include Next.js 16, React 19, Zustand, Prisma, and NextAuth. Supabase client/SSR packages and `jose` are not currently dependencies. Check current installed Next.js documentation under `node_modules/next/dist/docs/` before implementing routes, middleware/proxy, rewrites, or other framework-specific behavior, as required by `AGENTS.md`.

## Intended application structure (to build in this repo)

```text
app/
├── (auth)/
│   ├── login/page.tsx
│   └── auth/callback/route.ts
├── (portal)/
│   ├── layout.tsx                 # Authenticated shell
│   ├── page.tsx                   # Assigned application dashboard
│   ├── admin/
│   │   ├── users/page.tsx         # Allowlist, status, role management
│   │   ├── applications/page.tsx  # Application catalog
│   │   ├── grants/page.tsx        # Per-user assignments and expiry
│   │   └── audit/page.tsx         # Filterable security/audit history
│   └── demo/[recordId]/page.tsx   # Controlled demo with user-scoped synthetic data
├── api/
│   └── launch/[slug]/route.ts     # Server-side session, status, grant check and launch
├── tools/[slug]/page.tsx          # Only if tools are actually routed through this Next app
├── layout.tsx
├── page.tsx                       # Public entry/redirect
└── globals.css
components/
├── admin/                         # User, application, grant, and audit UI
├── dashboard/                     # App cards and portal navigation
└── ui/                            # Shared accessible primitives
lib/
├── auth/                          # Session and role checks
├── supabase/                      # Browser/server clients and cookie handling
├── access/                        # Assignment and expiry policy
├── audit/                         # Server-side audit writes
└── types.ts
supabase/
├── migrations/                    # Versioned schema, RLS, triggers, seed changes
├── functions/                     # Only if a verified server-side need requires them
└── schema.sql                     # Keep aligned with migrations
```

The tree is a proposed organization, not a claim that these files already exist. Do not add a middleware guard as the only authorization layer: every protected page, API, and launch must check identity, active status, role, and the specific non-revoked, unexpired assignment on the server/database. Zustand is for non-sensitive UI state only. Credentials and signed tokens must remain server-side and must never be exposed in URLs, client bundles, logs, or evidence.

## Data and identity boundaries

- Each staff member signs in with an individual identity. Portal assignments are per user and application; a shared vendor account does not provide user-specific authorization or data separation.
- Keep portal identity and vendor identity distinct. A portal JWT, OAuth API grant, deep link, or already-authenticated browser session does not by itself prove the vendor website has signed in the intended staff member.
- Use only vendor-supported SSO or an owner-approved enterprise launcher for real vendor launches. Validate prompts, MFA, vendor-side role limits, first/repeat login, and revocation with approved test accounts.
- Isolate test data and use dedicated synthetic identities. Do not connect to an existing CRM or request production credentials for this assessment.
- Record login, launch, assignment/user changes, denied access, expiry, and relevant session events with enough context to investigate; never log secrets or bearer tokens.
- The owner must approve persistent credentials/grants, security changes, paid services, paid commitments, and credential launcher use.

## Assessment records and deliverables

Keep the four-application feasibility inventory with the project documentation (or a dated artifact linked here). For each app include service/target page, owner and plan, login/MFA/account model, supported flow type, official evidence and check date, test prerequisites, prompts, costs, revocation behavior, blockers, and recommendation. Mark blocked and untested work plainly.

The test record must cover one admin and two differently assigned staff identities: identity and admin boundaries, assignment isolation and direct URL/API attempts, an approved actual vendor launch if available, revocation and disabled-user behavior, expiry and audit evidence, session/token safety, accessibility/usability, mobile/desktop, deployment from a clean browser, and a small live change.

Submission structure should include:

```text
submission/
├── README.md                 # Architecture, data flow, access model, setup/deploy
├── .env.example              # Names and safe placeholders only
├── evidence/                 # Dated redacted screenshots/recording and test results
├── feasibility/              # Four-app inventory and dated official evidence
├── plan.pdf                  # Or plan.pptx; scope, rollout, dependencies, itemized costs
└── cleanup.md                # Remove test users, grants, vendor settings, deployment
```

Provide a working HTTPS demo on an eligible free hosting option, state tier availability and expiry, and arrange test identities securely without publishing reusable credentials. Cost research must state currency, assumptions, free-tier limits, and one-time versus recurring costs; verify current prices rather than guessing. Production rollout is out of this assessment's scope.

## Schema reconciliation checklist

The two checked-in SQL files currently define `profiles`, `applications`, `access_grants`, and `audit_logs`; they are currently identical. Before relying on them:

- Decide the actual initial activation and app assignment policy with the owner. Active status alone must never imply access to every tool.
- Enforce the initial admin allowlist on the server/database; never trust a client-submitted role or email as admin proof.
- Define signup behavior and application grants for new users and newly added applications, including duplicate-safe migrations/backfills.
- Add complete least-privilege RLS for profiles, applications, assignments, and audit records; ensure staff cannot grant themselves access or edit roles/status.
- Define how user disablement and assignment revocation affect portal requests and document that already-open external vendor sessions may persist.
- Apply changes through versioned migrations, keep `schema.sql` consistent, and verify behavior with admin, staff A, staff B, expired, revoked, and disabled identities.

See [firststep.md](firststep.md) for the execution sequence, approval boundaries, schedule, and acceptance-test matrix.
