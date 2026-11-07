import 'tx_kind.dart';

/// Satu saran judul atau kategori yang pernah dipakai pengguna.
///
/// Menggantikan `judul_data_harian` dan `kategori_data_harian` milik Sepran.
/// Lihat SPEC §5.5 dan DATA-MODEL `suggestions`.
class TxSuggestion {
  const TxSuggestion({
    required this.id,
    required this.type,
    required this.name,
    required this.kind,
    required this.useCount,
    this.lastUsedAt,
  });

  final String id;

  /// `title` atau `category`. Lihat `SuggestionRules`.
  final String type;

  final String name;

  /// Judul dan kategori dipisah per jenis transaksi. SPEC C-3.
  final TxKind kind;

  /// Berapa kali saran ini dipakai. SPEC C-4.
  final int useCount;

  /// Kapan terakhir dipakai, epoch milidetik. SPEC C-4.
  final int? lastUsedAt;
}
