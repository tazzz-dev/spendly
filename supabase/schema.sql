-- Skema cloud Spendly untuk Supabase (PostgreSQL).
--
-- Jalankan seluruh berkas ini sekali di Supabase Dashboard › SQL Editor.
-- Setelah itu daftarkan URL balik OAuth di Authentication › URL Configuration:
--
--   * Site URL          : https://<domain-anda>/
--   * Redirect URLs     :
--       https://<domain-anda>/**            (versi web)
--       io.supabase.spendly://login-callback (Android/iOS)
--       http://localhost:*/**                (pengembangan web)
--
-- Lalu aktifkan provider Google di Authentication › Providers dan isi Client ID
-- serta Client Secret dari Google Cloud Console.
--
-- Catatan rancangan:
--   * Nama kolom sama persis dengan SQLite lokal, sehingga klien tidak perlu
--     memetakan nama.
--   * Uang dan waktu memakai BIGINT: nominal maksimum aplikasi 999.999.999.999
--     dan epoch milidetik sama-sama tidak muat di INTEGER 32-bit.
--   * Boolean disimpan sebagai SMALLINT 0/1, sama seperti SQLite, agar nilai
--     yang bolak-balik tidak berubah tipe.
--   * Penghapusan memakai deleted_at (hapus lunak), bukan DELETE.
--   * Konflik diselesaikan klien dengan aturan "updated_at terbesar menang".

create table if not exists public.wallets (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  type text not null,
  opening_balance bigint not null default 0,
  currency text not null default 'IDR',
  icon text,
  color bigint,
  is_default smallint not null default 0,
  use_count bigint not null default 0,
  sort_order bigint not null default 0,
  archived_at bigint,
  deleted_at bigint,
  created_at bigint not null,
  updated_at bigint not null
);

create table if not exists public.debts (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  party_name text not null,
  phone text,
  date text not null,
  note text,
  target_amount bigint,
  target_direction text,
  paid_opening bigint not null default 0,
  is_settled smallint not null default 0,
  deleted_at bigint,
  created_at bigint not null,
  updated_at bigint not null
);

create table if not exists public.budgets (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  category text not null,
  period text not null,
  amount bigint not null,
  warn_percent bigint not null default 80,
  start_date text,
  end_date text,
  deleted_at bigint,
  created_at bigint not null,
  updated_at bigint not null
);

create table if not exists public.custom_reports (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  start_date text not null,
  end_date text not null,
  deleted_at bigint,
  created_at bigint not null,
  updated_at bigint not null
);

create table if not exists public.transactions (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind text not null,
  wallet_id text not null,
  counter_wallet_id text,
  transfer_group_id text,
  title text,
  category text,
  note text,
  amount bigint not null,
  date text not null,
  time text,
  debt_entry_id text,
  created_at bigint not null,
  updated_at bigint not null,
  deleted_at bigint
);

create table if not exists public.debt_entries (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  debt_id text not null,
  amount bigint not null,
  date text not null,
  time text,
  wallet_id text,
  note text,
  deleted_at bigint,
  created_at bigint not null,
  updated_at bigint not null
);

-- Penarikan inkremental selalu menyaring user_id dan updated_at.
create index if not exists idx_wallets_user_updated on public.wallets (user_id, updated_at);
create index if not exists idx_debts_user_updated on public.debts (user_id, updated_at);
create index if not exists idx_budgets_user_updated on public.budgets (user_id, updated_at);
create index if not exists idx_custom_reports_user_updated on public.custom_reports (user_id, updated_at);
create index if not exists idx_transactions_user_updated on public.transactions (user_id, updated_at);
create index if not exists idx_debt_entries_user_updated on public.debt_entries (user_id, updated_at);

-- Row Level Security: setiap pengguna hanya melihat dan mengubah barisnya.
-- Kunci anon yang tertanam di aplikasi tidak memberi akses ke data orang lain.
do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'wallets', 'debts', 'budgets', 'custom_reports', 'transactions', 'debt_entries'
  ]
  loop
    execute format('alter table public.%I enable row level security', tbl);

    execute format('drop policy if exists %I_select on public.%I', tbl, tbl);
    execute format(
      'create policy %I_select on public.%I for select using (user_id = auth.uid())',
      tbl, tbl
    );

    execute format('drop policy if exists %I_insert on public.%I', tbl, tbl);
    execute format(
      'create policy %I_insert on public.%I for insert with check (user_id = auth.uid())',
      tbl, tbl
    );

    execute format('drop policy if exists %I_update on public.%I', tbl, tbl);
    execute format(
      'create policy %I_update on public.%I for update using (user_id = auth.uid()) with check (user_id = auth.uid())',
      tbl, tbl
    );

    execute format('drop policy if exists %I_delete on public.%I', tbl, tbl);
    execute format(
      'create policy %I_delete on public.%I for delete using (user_id = auth.uid())',
      tbl, tbl
    );
  end loop;
end $$;

-- Supabase mengekspos tabel baru ke API secara otomatis, tetapi bila proyek
-- memakai grant manual, pastikan peran anon/authenticated tetap mendapat akses
-- yang dibatasi RLS di atas.
grant select, insert, update, delete on
  public.wallets,
  public.debts,
  public.budgets,
  public.custom_reports,
  public.transactions,
  public.debt_entries
to authenticated;
