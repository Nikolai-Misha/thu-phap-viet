-- THƯ PHÁP VIỆT — Supabase schema + Row Level Security
-- Chạy toàn bộ file trong Supabase Dashboard > SQL Editor.
-- Tạo user Admin trong Authentication > Users trước, sau đó chạy câu INSERT
-- bootstrap ở cuối file với UUID thật của user đó.

begin;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
revoke all on table public.admin_users from anon, authenticated;
grant select on table public.admin_users to authenticated;

drop policy if exists "Admins can read their own admin marker" on public.admin_users;
create policy "Admins can read their own admin marker"
on public.admin_users
for select
to authenticated
using (user_id = (select auth.uid()));

-- SECURITY DEFINER function lets RLS policies check membership without
-- exposing the admin_users table to anonymous visitors or other users.
create or replace function public.is_site_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users as au
    where au.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_site_admin() from public;
grant execute on function public.is_site_admin() to anon, authenticated;

create table if not exists public.artworks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 200),
  description text not null default '',
  completed_at date,
  media jsonb not null default '[]'::jsonb
    check (jsonb_typeof(media) = 'array'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.artworks enable row level security;
revoke all on table public.artworks from anon, authenticated;
grant select on table public.artworks to anon, authenticated;
grant insert, update, delete on table public.artworks to authenticated;

drop policy if exists "Anyone can view public artworks" on public.artworks;
create policy "Anyone can view public artworks"
on public.artworks
for select
to anon, authenticated
using (true);

drop policy if exists "Only admins can add artworks" on public.artworks;
create policy "Only admins can add artworks"
on public.artworks
for insert
to authenticated
with check ((select public.is_site_admin()));

drop policy if exists "Only admins can edit artworks" on public.artworks;
create policy "Only admins can edit artworks"
on public.artworks
for update
to authenticated
using ((select public.is_site_admin()))
with check ((select public.is_site_admin()));

drop policy if exists "Only admins can remove artworks" on public.artworks;
create policy "Only admins can remove artworks"
on public.artworks
for delete
to authenticated
using ((select public.is_site_admin()));

create or replace function public.set_artworks_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_artworks_updated_at on public.artworks;
revoke all on function public.set_artworks_updated_at() from public, anon, authenticated;

create trigger set_artworks_updated_at
before update on public.artworks
for each row execute function public.set_artworks_updated_at();

-- The gallery itself is public, so artwork media is intentionally public-read.
-- Only authenticated Admin members can upload, replace or delete media.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'artworks',
  'artworks',
  true,
  52428800,
  array['image/jpeg','image/png','image/gif','image/webp','video/mp4','video/webm']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Only admins can upload artwork media" on storage.objects;
create policy "Only admins can upload artwork media"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'artworks'
  and (select public.is_site_admin())
);

drop policy if exists "Only admins can update artwork media" on storage.objects;
create policy "Only admins can update artwork media"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'artworks'
  and (select public.is_site_admin())
)
with check (
  bucket_id = 'artworks'
  and (select public.is_site_admin())
);

drop policy if exists "Only admins can delete artwork media" on storage.objects;
create policy "Only admins can delete artwork media"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'artworks'
  and (select public.is_site_admin())
);

commit;

-- ADMIN BOOTSTRAP — chạy riêng SAU KHI tạo user Admin trong Authentication > Users.
-- Thay UUID bên dưới bằng User UID thực tế trong Supabase Dashboard.
-- Không dùng email hoặc mật khẩu ở đây.
-- insert into public.admin_users (user_id)
-- values ('00000000-0000-0000-0000-000000000000')
-- on conflict (user_id) do nothing;
