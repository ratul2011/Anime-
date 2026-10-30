# ANIMEVERSE — Secure Backend Edition

This package integrates **Supabase Auth + PostgreSQL + Row Level Security (RLS)**.

## Included
- `public/index.html` — frontend connected to Supabase Auth and database.
- `supabase/migrations/001_secure_schema.sql` — role table, anime picks table, signup trigger, and RLS policies.

## 1. Create a Supabase project
1. Create a project at https://supabase.com/dashboard.
2. In Project Settings → API (or API Keys), copy the Project URL and the anon/publishable key.
3. Open `public/index.html` and replace:
   - `https://YOUR-PROJECT.supabase.co`
   - `YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY`
4. Never put the `service_role` or secret key in frontend HTML, GitHub, or a public repository.

## 2. Create the database
1. Open Supabase SQL Editor.
2. Paste and run `supabase/migrations/001_secure_schema.sql`.
3. New signups automatically receive the normal `user` role.
4. Do not create any client policy that lets users write their own `user_roles` row.

## 3. Create your admin account
1. Open the website and create an account with your email and a strong password.
2. Confirm the email if email confirmation is enabled.
3. In Supabase SQL Editor, run this statement after replacing the email with the exact account email:

```sql
insert into public.user_roles (user_id, role)
select id, 'admin'
from auth.users
where lower(email) = lower('YOUR-EMAIL@example.com')
on conflict (user_id) do update set role = 'admin';
```

4. Sign out and sign in again. The Admin button appears after the database role check succeeds.

## 4. Publish the frontend
- Host the contents of `public/` on GitHub Pages, Netlify, or Vercel.
- Add the deployed HTTPS domain to Supabase Authentication → URL Configuration → Site URL and Redirect URLs.
- Use HTTPS.

## Security model
- The frontend contains only the anon/publishable key, which is public by design.
- Never expose a Supabase `service_role` or secret key in browser code.
- RLS independently checks the authenticated user's role on every insert/update/delete. Hiding the Admin button is not the security boundary.
- New users are assigned `user`; they cannot promote themselves because no client write policy exists for `user_roles`.
- Visitors can read curated picks; only admins can modify them.
- Enable email confirmation and MFA in Supabase Auth settings where appropriate.
- Dashboard counts shown here are local-context metrics, not a global user analytics system.
- Anime catalogue data still comes from the public Jikan API and is subject to its availability/rate limits.

## Deployment status
This is a configured integration starter, not a deployed live service. You still need to create your Supabase project, add its URL/key, run the SQL migration, promote your admin account, and publish the frontend. Do not send secret keys in chat.
