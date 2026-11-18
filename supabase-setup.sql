-- AB Wangi Tagihan — tabel sinkron
-- Tempel semua isi file ini di Supabase → SQL Editor → Run. Aman dijalankan ulang.

create table if not exists public.tagihan_items (
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  id         text        not null,
  data       jsonb,
  deleted    boolean     not null default false,
  upd        bigint      not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists tagihan_items_user_updated on public.tagihan_items (user_id, updated_at);

-- updated_at selalu diisi jam server (dipakai buat narik perubahan terbaru)
create or replace function public.tagihan_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := clock_timestamp();
  return new;
end $$;

drop trigger if exists tagihan_touch on public.tagihan_items;
create trigger tagihan_touch before insert or update on public.tagihan_items
for each row execute function public.tagihan_touch();

-- Keamanan: tiap akun cuma bisa lihat & ubah datanya sendiri
alter table public.tagihan_items enable row level security;

drop policy if exists "tagihan pilih"  on public.tagihan_items;
drop policy if exists "tagihan tambah" on public.tagihan_items;
drop policy if exists "tagihan ubah"   on public.tagihan_items;

create policy "tagihan pilih"  on public.tagihan_items for select to authenticated using (user_id = auth.uid());
create policy "tagihan tambah" on public.tagihan_items for insert to authenticated with check (user_id = auth.uid());
create policy "tagihan ubah"   on public.tagihan_items for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, insert, update on public.tagihan_items to authenticated;
