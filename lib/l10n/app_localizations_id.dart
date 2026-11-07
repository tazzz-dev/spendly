// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get settingsTitle => 'Setting';

  @override
  String get settingsRestorePurchase => 'Pulihkan Pembayaran Sebelumnya';

  @override
  String get settingsRemoveAds => 'Hapus Iklan';

  @override
  String get settingsUnavailable => 'Fitur ini belum tersedia di versi ini';

  @override
  String get settingsShowDecimals => 'Tampilkan Angka Desimal';

  @override
  String settingsShowDecimalsExample(String amount) {
    return 'Contoh: $amount';
  }

  @override
  String get settingsBackupRestore => 'Backup dan Restore Data';

  @override
  String get settingsDeleteAll => 'Hapus Semua Data';

  @override
  String get settingsDeleteAllBody =>
      'Seluruh transaksi, rekening, hutang, saran, dan anggaran akan dikosongkan. Setelan tidak ikut terhapus. Aksi ini tidak dapat diurungkan.';

  @override
  String get settingsDeleteAllDone => 'Semua data telah dihapus';

  @override
  String get settingsReminder => 'Pengingat';

  @override
  String get settingsReminderSubtitle => 'Pengingat mencatat harian';

  @override
  String get settingsReminderWhen => 'Kapan';

  @override
  String get settingsReminderPermissionDenied =>
      'Izin notifikasi ditolak, pengingat tidak akan muncul';

  @override
  String get settingsTheme => 'Warna Tema';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsCancel => 'Batal';

  @override
  String get settingsDelete => 'Hapus';

  @override
  String settingsLoadFailed(String error) {
    return 'Gagal membaca setelan: $error';
  }

  @override
  String get themeBlue => 'Biru Terang';

  @override
  String get themePink => 'Mode Pink';

  @override
  String get themePurple => 'Mode Ungu';

  @override
  String get themeDark => 'Mode Gelap';
}
