/// Daftar tabel yang ikut sinkronisasi dan urutannya.
///
/// Urutan mengikuti arah kunci asing: rekening lebih dulu, lalu hutang, baru
/// transaksi dan entri hutang. Tanpa urutan ini, baris transaksi bisa tiba
/// sebelum rekening yang dirujuknya dan ditolak oleh `PRAGMA foreign_keys`.
///
/// Tabel `app_settings` **tidak** ikut: tema, bahasa, dan pengingat adalah
/// pilihan perangkat, bukan data pencatatan. Tabel draft notifikasi juga tidak:
/// notifikasi hanya masuk ke ponsel yang menerimanya, sedangkan transaksi hasil
/// konfirmasinya sudah tersinkron lewat tabel `transactions`.
class SyncTable {
  const SyncTable(this.name, {required this.columns});

  final String name;

  /// Kolom yang dibaca, dikirim, dan ditulis. Nama kolom sengaja sama di
  /// SQLite lokal dan PostgreSQL, sehingga tidak ada pemetaan nama.
  final List<String> columns;
}

/// `INSERT ... ON CONFLICT(id) DO UPDATE` yang hanya menimpa bila versi cloud
/// lebih baru. Baris yang sama tuanya (atau lebih lama) dibiarkan.
///
/// Dipisah ke sini supaya bisa diuji langsung terhadap SQLite di memori tanpa
/// memerlukan klien Supabase.
String syncUpsertSql(SyncTable table) {
  final columns = table.columns.join(', ');
  final placeholders = List.filled(table.columns.length, '?').join(', ');
  final assignments = table.columns
      .where((column) => column != 'id')
      .map((column) => '$column = excluded.$column')
      .join(', ');

  return 'INSERT INTO ${table.name} ($columns) VALUES ($placeholders) '
      'ON CONFLICT(id) DO UPDATE SET $assignments '
      'WHERE excluded.updated_at > ${table.name}.updated_at';
}

const List<SyncTable> syncTables = [
  SyncTable(
    'wallets',
    columns: [
      'id',
      'name',
      'type',
      'opening_balance',
      'currency',
      'icon',
      'color',
      'is_default',
      'use_count',
      'sort_order',
      'archived_at',
      'deleted_at',
      'created_at',
      'updated_at',
    ],
  ),
  SyncTable(
    'debts',
    columns: [
      'id',
      'party_name',
      'phone',
      'date',
      'note',
      'target_amount',
      'target_direction',
      'paid_opening',
      'is_settled',
      'deleted_at',
      'created_at',
      'updated_at',
    ],
  ),
  SyncTable(
    'budgets',
    columns: [
      'id',
      'category',
      'period',
      'amount',
      'warn_percent',
      'start_date',
      'end_date',
      'deleted_at',
      'created_at',
      'updated_at',
    ],
  ),
  SyncTable(
    'custom_reports',
    columns: [
      'id',
      'name',
      'start_date',
      'end_date',
      'deleted_at',
      'created_at',
      'updated_at',
    ],
  ),
  SyncTable(
    'transactions',
    columns: [
      'id',
      'kind',
      'wallet_id',
      'counter_wallet_id',
      'transfer_group_id',
      'title',
      'category',
      'note',
      'amount',
      'date',
      'time',
      'debt_entry_id',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
  ),
  SyncTable(
    'debt_entries',
    columns: [
      'id',
      'debt_id',
      'amount',
      'date',
      'time',
      'wallet_id',
      'note',
      'deleted_at',
      'created_at',
      'updated_at',
    ],
  ),
];
