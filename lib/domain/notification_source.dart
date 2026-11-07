// Daftar aplikasi yang notifikasinya boleh ditangkap. Murni: tanpa Flutter,
// tanpa drift, tanpa akses Android.
//
// Nama paket adalah satu-satunya hal yang dibaca dari notifikasi. Nama aplikasi
// dipakai untuk tampilan, bukan untuk keputusan keamanan.
enum NotificationSource {
  bca('BCA', ['com.bca']),
  mandiri('Livin Mandiri', ['id.co.bankmandiri.livin']),
  brimo('BRImo', ['id.co.bri.brimo']),
  gopay('GoPay', ['com.gojek.app', 'com.gojek.gopay']),
  ovo('OVO', ['club.sobatovo.android', 'ovo.id']),
  dana('DANA', ['id.dana']),
  shopeepay('ShopeePay', ['com.shopee.id', 'com.shopeepay.id']),

  /// blu by BCA Digital. Nama paket lama (`id.co.bankbkemobile.digital`) tetap
  /// diterima supaya pengguna versi aplikasi lama tidak kehilangan notifikasi.
  blu('blu', ['com.bcadigital.blu', 'id.co.bankbkemobile.digital']);

  const NotificationSource(this.appName, this.packages);

  /// Nama yang tampil di inbox.
  final String appName;

  /// Nama paket Android. Satu aplikasi bisa punya lebih dari satu nama paket;
  /// GoPay misalnya pernah dikirim lewat aplikasi Gojek maupun aplikasi
  /// GoPay yang berdiri sendiri.
  final List<String> packages;

  static NotificationSource? fromPackage(String packageName) {
    final value = packageName.trim();
    for (final source in values) {
      if (source.packages.contains(value)) return source;
    }
    return null;
  }

  /// Seluruh nama paket target. Dipakai lapisan Android untuk menyaring
  /// notifikasi sebelum menyentuh basis data.
  static Set<String> get allPackages => {
    for (final source in values) ...source.packages,
  };
}
