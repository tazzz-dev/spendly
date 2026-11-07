/// Empat tema berwarna milik Sepran. SPEC G-6 dan ST-4.
///
/// Bukan sekadar terang/gelap/sistem: pengguna memilih salah satu dari empat
/// warna, dan pilihannya tersimpan di setelan. Lihat SPEC §5.12.
///
/// Berkas ini sengaja hanya memuat **identitas** tema — kode simpanan dan
/// nilainya yang tetap. Wujud tampilannya (warna benih, terang/gelap, dan
/// ThemeData) tinggal di `lib/app/theme.dart`, dan namanya yang tampil ke
/// pengguna tinggal di berkas ARB `lib/l10n/`. Dengan begitu `lib/domain/`
/// tetap murni: tidak mengimpor Flutter maupun drift.
enum AppTheme {
  blue('blue'),
  pink('pink'),
  purple('purple'),
  dark('dark');

  const AppTheme(this.storageValue);

  /// Sebagaimana tersimpan di tabel `app_settings`.
  final String storageValue;

  static AppTheme fromStorage(String value) => AppTheme.values.firstWhere(
    (theme) => theme.storageValue == value,
    orElse: () => AppTheme.blue,
  );
}
