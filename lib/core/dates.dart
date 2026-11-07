import 'package:intl/intl.dart';

/// Tanggal lokal sebagai teks `YYYY-MM-DD`.
///
/// Keputusan kita, bukan tiruan Sepran yang menyimpan epoch milidetik.
/// Indonesia tidak memakai DST, sehingga teks lokal menghilangkan seluruh
/// persoalan zona waktu dan membuat pengelompokan per hari jadi sepele.
/// Lihat SPEC G-4.
class AppDate {
  const AppDate._();

  static final DateFormat _key = DateFormat('yyyy-MM-dd');
  static final DateFormat _readable = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _full = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _weekday = DateFormat('EEE, dd MMM yyyy', 'id_ID');
  static final DateFormat _monthLabel = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _time = DateFormat('HH:mm');

  /// Kunci penyimpanan untuk sebuah waktu.
  static String key(DateTime dateTime) => _key.format(dateTime);

  /// Kunci untuk hari ini.
  static String today() => key(DateTime.now());

  /// `18 Okt 2026`
  static String readable(String dateKey) => _readable.format(parseKey(dateKey));

  /// `20 Oktober 2026`. Dipakai kepala halaman detail transaksi.
  static String full(String dateKey) => _full.format(parseKey(dateKey));

  /// `Sen, 18 Okt 2026`. Dipakai sebagai kepala halaman Transaksi, sesuai
  /// susunan SPEC T-12.
  static String weekdayReadable(String dateKey) =>
      _weekday.format(parseKey(dateKey));

  /// Menggeser [dateKey] sebanyak [days] hari.
  ///
  /// Menyusun ulang tanggalnya dari komponen tahun/bulan/hari, bukan menambah
  /// durasi: cara itu tidak pernah tersandung perbedaan panjang bulan, dan tidak
  /// bergantung pada zona waktu.
  static String shift(String dateKey, int days) {
    final date = parseKey(dateKey);
    return key(DateTime(date.year, date.month, date.day + days));
  }

  /// Jam `HH:MM`. Lihat SPEC G-5.
  static String timeKey(DateTime dateTime) => _time.format(dateTime);

  /// Jam sekarang, untuk mengisi kolom Jam saat form baru dibuka.
  static String nowTime() => timeKey(DateTime.now());

  /// `Oktober 2026`
  static String monthLabel(String dateKey) =>
      _monthLabel.format(parseKey(dateKey));

  /// Mengubah `YYYY-MM-DD` menjadi `DateTime` di tengah malam lokal.
  static DateTime parseKey(String dateKey) => _key.parse(dateKey);

  /// Hari pertama bulan yang memuat [dateKey].
  static String firstDayOfMonth(String dateKey) {
    final date = parseKey(dateKey);
    return key(DateTime(date.year, date.month, 1));
  }

  /// Hari terakhir bulan yang memuat [dateKey].
  static String lastDayOfMonth(String dateKey) {
    final date = parseKey(dateKey);
    // Hari ke-0 bulan berikutnya adalah hari terakhir bulan ini.
    return key(DateTime(date.year, date.month + 1, 0));
  }
}
