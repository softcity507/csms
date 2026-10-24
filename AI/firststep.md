 i want you to make a plan on how to build SSO Gateway: Build Plan (Next.js + Supabase)
- What to build
Build a single-domain SSO gateway in a Next.js App Router project on localhost:3000, using Supabase for authentication and database. 
- Step 1: 
Run the provided SQL schema in Supabase, with is_active in the profiles table defaulting to true so every new user is active from the start. 
- Step 2: 
Enable the Google provider in Supabase Auth. 
- Step 3: 
Create a database trigger on auth.users that inserts a profiles row on signup, setting role to admin if the email matches ADMIN_EMAIL from the .env file, and staff otherwise. The same trigger inserts one access_grants row for every existing application, with is_revoked false and expires_at null.       
- Step 4:  
Seed the applications table with my client tools, including name, slug, and target_url. 
**Token flow: gateway side**

When a user clicks a tool, the gateway server first checks that the user has a session, that is_active is true, and that access_grants has a valid entry, meaning not revoked and not expired. It then uses the jose library to create a short-lived JWT containing the user ID, email, and application ID, with a lifetime of five minutes, signed with a secret key. Finally, it redirects the user to the tool's target_url with the token attached.

**Token flow: client site side**

Each client site gets a small route, for example /sso, that verifies the token with the same secret key. If the token is valid, the site extracts the user ID and creates its own httpOnly session cookie, then redirects the user into the app. From then on, the site filters all data by that user ID, so each user sees only their own data. The secret key must be identical on both sides and stored only in an environment variable, never in the code.


- Step 5:  
Build a landing page that lists only the applications the user has a valid grant for, meaning not revoked and not expired. 
- Step 6:  
Write audit_logs entries for login, app launch, and grant changes.

- Libraries and technologies
Use Next.js with React and TypeScript, the supabase-js client together with the @supabase/ssr package for cookie-based sessions, and Supabase Google OAuth. Write RLS policies so users can read only their own profile and grants, applications are readable by active users, and only admins can modify grants and applications. 
Use Zustand for client-side UI state only. 
Use Next.js middleware to check the session, is_active, and a valid grant before allowing any tool route. 
Use Next.js rewrites to open each tool under localhost:3000/tools/slug. Use the jose library to sign short-lived JWTs, around five minutes, containing the user ID and application ID, and have each tool verify the token with a shared secret and then create its own httpOnly session cookie. Filter all tool data by user ID.