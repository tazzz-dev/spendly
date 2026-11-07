// Aturan rekening yang tidak menyentuh basis data maupun Flutter sama sekali.
// Dipisahkan ke sini supaya bisa diuji tanpa membuka SQLite. Lihat SPEC §5.1.

/// Sebab sebuah rekening tidak boleh dihapus.
enum WalletDeleteBlock {
  /// SPEC G-8 dan R-5: rekening default hanya boleh diedit.
  isDefault,

  /// SPEC R-4: masih dipakai pergerakan uang.
  inUse,
}

/// Hasil pemeriksaan boleh-hapus.
class WalletDeleteVerdict {
  /// Boleh dihapus.
  const WalletDeleteVerdict.allowed() : block = null, usageCount = 0;

  /// Tidak boleh dihapus, beserta sebabnya.
  const WalletDeleteVerdict.blocked(this.block, this.usageCount);

  final WalletDeleteBlock? block;

  /// Berapa pergerakan yang masih memakai rekening ini. Hanya bermakna bila
  /// [block] bernilai [WalletDeleteBlock.inUse].
  final int usageCount;

  bool get allowed => block == null;
}

/// Pesan penolakan penghapusan yang dibaca pengguna.
///
/// Ditaruh di lapisan domain supaya bisa diuji tanpa membangun layar. Layar
/// tinggal menampilkannya. SPEC R-4, R-5, dan G-8.
String deleteBlockMessage(WalletDeleteVerdict verdict) =>
    switch (verdict.block) {
      // SPEC R-5 dan G-8.
      WalletDeleteBlock.isDefault =>
        'Rekening bawaan tidak bisa dihapus, hanya bisa diubah.',
      // SPEC R-4.
      WalletDeleteBlock.inUse =>
        'Rekening ini masih dipakai oleh ${verdict.usageCount} pergerakan. '
            'Hapus dulu transaksinya, baru rekening ini bisa dihapus.',
      // Tidak terpakai: hanya dipanggil saat penghapusan memang ditolak.
      null => 'Rekening tidak bisa dihapus.',
    };

/// Aturan penamaan rekening. SPEC G-9.
class WalletName {
  const WalletName._();

  /// Batas panjang nama. Bukan tiruan dari Sepran, hanya batas wajar supaya
  /// nama tidak merusak tata letak. Keputusan kita.
  static const int maxLength = 40;

  /// Pesan yang dipakai saat nama sudah terpakai. Persis kalimat Sepran,
  /// lihat SPEC §8 kasus tepi "Nama rekening sama".
  static const String duplicateMessage = 'Nama Rekening sudah digunakan';

  /// Mengembalikan pesan galat, atau null bila nama sah.
  static String? validate(String raw) {
    final name = normalize(raw);
    if (name.isEmpty) return 'Nama rekening wajib diisi';
    if (name.length > maxLength) {
      return 'Nama rekening paling panjang $maxLength huruf';
    }
    return null;
  }

  /// Bentuk yang disimpan: tanpa spasi di ujung.
  static String normalize(String raw) => raw.trim();

  /// Bentuk pembanding keunikan: dipangkas lalu dijadikan huruf kecil.
  ///
  /// Keunikan nama **tidak peka huruf besar-kecil** (SPEC G-9): "BCA" dan
  /// "bca" adalah rekening yang sama di mata pengguna, jadi yang kedua ditolak.
  static String fold(String raw) => normalize(raw).toLowerCase();

  /// Dua nama menunjuk rekening yang sama bila bentuk pembandingnya sama.
  static bool isSame(String a, String b) => fold(a) == fold(b);
}
