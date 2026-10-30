-- ANIMEVERSE secure backend schema for Supabase PostgreSQL.
create extension if not exists pgcrypto;

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'user')) default 'user',
  created_at timestamptz not null default now()
);
alter table public.user_roles enable row level security;

drop policy if exists "Users can read their own role" on public.user_roles;
create policy "Users can read their own role"
on public.user_roles for select to authenticated
using (auth.uid() = user_id);

-- No client INSERT/UPDATE/DELETE policies on user_roles.
-- Assign admin role only through trusted SQL Editor / server-side service.

create table if not exists public.anime_picks (
  mal_id bigint primary key check (mal_id > 0),
  title text not null,
  title_english text,
  image_url text,
  score numeric(4,2),
  year integer,
  type text,
  anime_json jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.anime_picks enable row level security;

drop policy if exists "Anyone can read anime picks" on public.anime_picks;
create policy "Anyone can read anime picks"
on public.anime_picks for select to anon, authenticated using (true);

drop policy if exists "Admins can insert anime picks" on public.anime_picks;
create policy "Admins can insert anime picks"
on public.anime_picks for insert to authenticated
with check (exists (
  select 1 from public.user_roles r
  where r.user_id = auth.uid() and r.role = 'admin'
));

drop policy if exists "Admins can update anime picks" on public.anime_picks;
create policy "Admins can update anime picks"
on public.anime_picks for update to authenticated
using (exists (
  select 1 from public.user_roles r
  where r.user_id = auth.uid() and r.role = 'admin'
))
with check (exists (
  select 1 from public.user_roles r
  where r.user_id = auth.uid() and r.role = 'admin'
));

drop policy if exists "Admins can delete anime picks" on public.anime_picks;
create policy "Admins can delete anime picks"
on public.anime_picks for delete to authenticated
using (exists (
  select 1 from public.user_roles r
  where r.user_id = auth.uid() and r.role = 'admin'
));

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists anime_picks_set_updated_at on public.anime_picks;
create trigger anime_picks_set_updated_at
before update on public.anime_picks
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.user_roles (user_id, role)
  values (new.id, 'user')
  on conflict (user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

grant usage on schema public to anon, authenticated;
grant select on public.anime_picks to anon, authenticated;
grant insert, update, delete on public.anime_picks to authenticated;
grant select on public.user_roles to authenticated;

-- After signup, promote the exact owner account by running this separately:
-- insert into public.user_roles (user_id, role)
-- select id, 'admin' from auth.users
-- where lower(email) = lower('YOUR-EMAIL@example.com')
-- on conflict (user_id) do update set role = 'admin';
