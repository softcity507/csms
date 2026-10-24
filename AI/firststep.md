# Staff Access Portal — Assessment-First Build Plan

## Goal

Build an isolated staff access portal for four intended vendor applications. Staff sign in with individual identities, see only assigned tools, and use approved launch flows. Administrators manage staff status, application assignments, expiry, and audit history. Each user must remain isolated in the portal and in every connected tool; a shared vendor login must never be presented as individual authorization or data isolation.

The assessment requires a working portal and controlled demo, plus evidence-backed feasibility research for all four vendor applications. A real vendor integration is demonstrated only when its prerequisites and the owner's approval are available. Do not represent a mock, API token, deep link, or reused browser session as SSO.

## Checkpoint before integrations (hours 1–2)

Create an inventory for each of the four intended applications before implementation of vendor integrations. Record:

- Exact vendor/service and target page, account owner, plan, and official documentation checked (with URL and check date).
- Available login methods, MFA requirements, staff account model, and vendor-side roles.
- Whether the requested flow is supported SSO, an approved enterprise credential launcher, or simply reuse of an existing authenticated browser session. Explain what it proves and what it does not prove.
- Required test accounts and identities, sandbox/test tenant, redirect URI, identity-provider access, vendor settings, and any launcher setup.
- First and repeat login experience, user prompts/consent/MFA, costs or plan prerequisites, revocation behavior, and unsupported cases.
- Blockers, evidence, options, cost implications, and recommended next step.

The assessment specifically notes that ServiceM8's official login page offered Google sign-in (checked 20 October 2026), but that alone does not establish that a custom portal can authenticate every staff member. Google sign-in is distinct from Google Authenticator MFA; its client deep links may still require login; and an OAuth API grant does not establish a browser session. Validate these distinctions using an approved ServiceM8 test account and current official evidence.

Submit this inventory and proposed scope as the feasibility checkpoint. If a flow is unsupported or prerequisites are missing, mark it blocked, explain why, and ask the owner before changing vendor or approach. Continue independent portal work without claiming the blocked flow works.

## Scope and approval boundaries

- Develop from scratch in an isolated test environment with synthetic data and dedicated test identities.
- Do not request production credentials or access an existing CRM. No existing-system access or migration is part of this assessment.
- Use real vendor services only with explicitly approved test accounts.
- Obtain owner approval before creating persistent credentials or grants, changing account security, enabling paid services, accepting a paid commitment, or using an enterprise credential launcher.
- Do not assume a free hosting tier makes vendor integrations free. Do not require a paid integration just to complete the assessment.
- Keep secrets out of source control, browser assets, URLs, logs, screenshots, recordings, and submitted credentials.

## Proposed implementation sequence

1. **Reconcile current project and schema.** This repo is a minimal Next.js App Router starter, not the proposed `src/` layout. Review the current schema/migration and update the plan/schema only after choosing the approved identity and assignment model. New staff may be active by default only if owner policy allows it; access must still require explicit per-application assignment. Define the initial admin allowlist on the server and prevent staff from changing their own role, active state, or assignments.
2. **Authentication and authorization.** Implement individual sign-in, server-validated sessions, admin-only management, and backend checks for every page, API, and tool launch. Do not trust a hidden link or client-side route guard as authorization. Use row-level security or equivalent server-side checks so users read only their own profile and assignments; admins manage users, apps, grants, and audit records.
3. **Portal and controlled demo.** Build a responsive dashboard showing only active, assigned, unrevoked, unexpired applications. Add an isolated demo tool with synthetic, user-scoped records so separate staff identities can prove data isolation.
4. **Audit and admin controls.** Record sign-in, launch, grant create/update/revoke, user disable/enable, denied access, and relevant session events with actor, subject/application, timestamp, and outcome. Add assignment revocation, user disablement, expiry, and logout/session expiry controls. Explain that revoking portal access may not terminate an already-open vendor session.
5. **Real integrations.** Implement only the approved flow established by the inventory. Use a vendor-supported OAuth/OIDC SSO flow or an explicitly approved enterprise launcher where available. A five-minute signed token is appropriate only for a client integration that is designed to verify it; it does not create a session in an unrelated vendor website. Do not send bearer tokens in query strings or claim the vendor login is complete unless the actual vendor flow confirms it.
6. **Deployment and evidence.** Deploy an HTTPS demo to an eligible free hosting option, document availability limits/expiry, and provide reproducible setup/deployment instructions, configuration examples without secrets, dated evidence, test results, known limitations, and cleanup steps. Prepare the requested short PDF/PowerPoint plan with rollout, dependencies, and itemized hosting, identity, vendor, and launcher costs; identify currency, assumptions, free-tier limits, and recurring versus one-time costs using verified current prices.

## Time plan

| Time | Work |
| --- | --- |
| Hours 1–2 | Confirm scenario; inventory four apps; research supported login flows; identify blockers; deliver feasibility checkpoint and required approvals. |
| Hours 3–5 | Individual staff sign-in, admin allowlist, roles/assignments, responsive dashboard, isolated demo and test identities. |
| Hours 6–8 | Controlled demo, audit events, begin only an approved real integration; end-of-day update with working features, evidence, blockers, and remaining scope. |
| Hours 9–11 | Complete permitted integration if prerequisites allow; revocation, session controls, and time-limited grants; mark blocked/untested apps. |
| Hours 12–14 | Run acceptance tests, fix authorization/usability defects, inspect mobile behavior, verify deployment in a clean browser. |
| Hours 15–16 | Finish evidence/docs and short plan; demonstrate one small live change and its effect; report actual time and unfinished items. |

## Acceptance test record

Use one admin and two staff identities with different assignments. Record expected result, actual result, and evidence for each case; explicitly label blocked/untested cases.

| Area | Required check |
| --- | --- |
| Identity | Allowed staff can sign in; unknown/disabled identities are denied; staff cannot access admin actions. |
| Assignment | Staff A and B see different apps. Direct URLs, protected APIs, changed identifiers, and unauthorized launches are denied server-side. |
| Real launch | Approved vendor flow opens the actual service as the intended test identity; show first/repeat access, prompts, MFA, and vendor-side role limits. |
| Revocation | Revoke an assignment and disable a staff member; subsequent portal requests fail; document behavior of already-open vendor sessions. |
| Expiry | Show access before and denial after expiry and matching audit records. |
| Session/data safety | Demonstrate logout/expiry; confirm credentials and tokens are absent from client assets, repository, URLs, logs, and evidence. |
| Quality | Check mobile/desktop, keyboard use, useful errors, clean-browser deployment, and the requested live change. |

**Completion for this assessment:** an isolated working portal and controlled app, required security/admin behavior, evidence for one approved real integration if prerequisites are supplied, and a truthful four-app feasibility report. Missing prerequisites leave that integration pending; submit the independent working scope and blocker evidence. Production rollout is future scope and requires all four flows, vendor permissions/offboarding checks, approved costs/dependencies, security review, operational ownership, and support. Unauthorized access, exposed secrets, MFA bypass, or presenting a mock as live are critical failures.

## Current repository gap

The existing `supabase/schema.sql` and migration define profiles, applications, grants, and audit logs, but `profiles.is_active` currently defaults to `false`; they do not yet implement the signup/admin allowlist, per-app initial assignment policy, audit write policy, or complete RLS rules from the earlier proposal. The current app page is placeholder text and no auth, dashboard, launch, or admin routes are implemented. Treat this document as a plan, not proof these controls exist. Reconcile both schema files together before implementation and test the resulting policy using the acceptance matrix above.
