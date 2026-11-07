import 'notification_draft.dart';
import 'notification_source.dart';
import 'tx_rules.dart';

/// Hasil parsing satu notifikasi.
class NotificationParseResult {
  const NotificationParseResult({
    required this.source,
    required this.amount,
    required this.type,
  });

  final NotificationSource source;

  /// Nominal positif, rupiah utuh.
  final int amount;

  final NotificationDraftType type;
}

/// Mesin parsing notifikasi, sepenuhnya luring.
///
/// Aturannya sengaja konservatif: bila aplikasi tidak dikenal, tidak ada
/// nominal, atau arah uang tidak dapat dipastikan, notifikasi **dibuang**.
/// Lebih baik tidak ada draft daripada draft yang salah nominalnya.
class NotificationParserEngine {
  const NotificationParserEngine();

  /// Notifikasi yang tidak pernah merupakan transaksi.
  ///
  /// "masuk" tidak dimasukkan sebagai kata tunggal: banyak notifikasi
  /// pemasukan memakai frasa "dana masuk" atau "uang masuk". Yang dibuang
  /// adalah "masuk akun/aplikasi", yang merupakan notifikasi login.
  static final List<RegExp> _blacklist = [
    RegExp(r'\botp\b', caseSensitive: false),
    RegExp(r'kode\s+verifikasi', caseSensitive: false),
    RegExp(r'\blogin\b', caseSensitive: false),
    RegExp(r'\blog\s*in\b', caseSensitive: false),
    RegExp(r'\bmasuk\s+(ke\s+)?(akun|aplikasi)\b', caseSensitive: false),
    RegExp(r'\bcashback\b', caseSensitive: false),
    RegExp(r'\bpromo\b', caseSensitive: false),
    RegExp(r'\bdiskon\b', caseSensitive: false),
    RegExp(r'\bkeamanan\b', caseSensitive: false),
    RegExp(r'kadaluwarsa|kedaluwarsa', caseSensitive: false),
    RegExp(r'\bpin\b', caseSensitive: false),
    RegExp(r'\bpassword\b|\bsandi\b', caseSensitive: false),
    RegExp(r'batas\s+waktu', caseSensitive: false),
  ];

  /// Nominal rupiah. Menerima `Rp50.000`, `Rp 50.000`, `Rp. 50.000`, dan
  /// `IDR 50.000`. Bagian pecahan dibulatkan ke rupiah terdekat.
  static final RegExp _rupiah = RegExp(
    r'(?:Rp\.?|IDR)\s*((?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d+)?)',
    caseSensitive: false,
  );

  /// Sinyal arah uang. Urutan penting saat dua pola mulai di posisi yang sama:
  /// pemasukan diperiksa lebih dulu, sehingga "transfer dari ..." tidak
  /// tertukar dengan "transfer ke ...".
  static final List<_Signal> _signals = [
    _Signal(
      NotificationDraftType.income,
      RegExp(
        r'berhasil\s+transfer\s+dari|transfer\s+dari|'
        r'transfer\s+berhasil\s+dari|transfer\s+masuk|dana\s+masuk|'
        r'uang\s+masuk|saldo\s+masuk|'
        r'(?:udah|sudah|telah)?\s*masuk\s+ke\s+'
        r'(?:gopay|ovo|dana|shopeepay|blu|dompet|rekening|saldo)\b|'
        r'top\s*up\s+berhasil|'
        r'topup\s+berhasil|berhasil\s+top\s*up|isi\s+saldo\s+berhasil|'
        r'top\s*up\s+(?:saldo|dana)\b|isi\s+saldo\b|tambah\s+saldo\b|'
        r'menerima\s+(transfer|uang|dana|rp)|kamu\s+menerima|'
        r'(?:telah|sudah|berhasil)\s+diterima|kamu\s+terima|anda\s+terima|'
        r'berhasil\s+menerima|pengembalian\s+dana|refund|'
        r'\bkredit\b|pemasukan|\bgaji\b|transaksi\s+masuk',
        caseSensitive: false,
      ),
    ),
    _Signal(
      NotificationDraftType.expense,
      RegExp(
        r'berhasil\s+transfer\s+ke|transfer\s+ke|transfer\s+berhasil\s+ke|'
        r'pembayaran|berhasil\s+bayar|\bbayar\b|\bmembayar\b|pembelian|'
        r'\bqr\b|\bqris\b|\bdebit\b|pulsa\s+terkirim|'
        r'tarik\s+tunai|penarikan|pengeluaran|belanja|'
        r'\bpayment\b|\bpaid\b',
        caseSensitive: false,
      ),
    ),
  ];

  /// Mengembalikan null bila notifikasi bukan transaksi yang bisa dipakai.
  NotificationParseResult? parse({
    required String packageName,
    required String title,
    required String message,
  }) {
    final source = NotificationSource.fromPackage(packageName);
    if (source == null) return null;

    final titleText = title.trim();
    final messageText = message.trim();
    final combined = _normalize('$titleText $messageText');
    if (combined.isEmpty) return null;
    if (_blacklist.any((pattern) => pattern.hasMatch(combined))) {
      return null;
    }

    final amount = _readAmount('$messageText $titleText');
    if (amount == null) return null;

    final type = _readType(combined);
    if (type == null) return null;

    return NotificationParseResult(source: source, amount: amount, type: type);
  }

  static String _normalize(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  /// Memilih nominal transaksi, bukan saldo.
  ///
  /// Notifikasi sering memuat dua nominal: "Pembayaran Rp50.000, saldo
  /// Rp1.000.000". Nominal yang didahului kata saldo/sisa/limit dilewati. Bila
  /// semua nominal ternyata saldo, notifikasi ditolak: nominal saldo bukan
  /// nominal transaksi, dan draft dengan nominal salah lebih berbahaya daripada
  /// tidak ada draft.
  static int? _readAmount(String text) {
    final matches = _rupiah.allMatches(text).toList(growable: false);
    if (matches.isEmpty) return null;

    final balancePrefix = RegExp(
      r'\b(saldo|sisa|limit)\b[^0-9]{0,30}$',
      caseSensitive: false,
    );
    // "Saldo masuk Rp100.000" adalah pemasukan, bukan saldo akhir. Jangan
    // ikut dibuang oleh aturan saldo di atas.
    final incomingPhrase = RegExp(
      r'\b(saldo|dana|uang)\s+masuk\b[^0-9]{0,15}$',
      caseSensitive: false,
    );
    // "Berhasil top up saldo Rp172.000" dan "Isi saldo Rp50.000" juga nominal
    // transaksi. Tanpa pengecualian ini, kata "saldo" membuat nominalnya
    // dibuang dan notifikasi top up yang sah hilang.
    final topUpPhrase = RegExp(
      r'\b(?:top\s*up|topup|isi|tambah)\s+(?:saldo|dana)\b[^0-9]{0,15}$',
      caseSensitive: false,
    );

    for (final match in matches) {
      final value = _parseAmount(match.group(1));
      if (value == null) continue;

      final prefixStart = match.start - 40 < 0 ? 0 : match.start - 40;
      final prefix = text.substring(prefixStart, match.start);
      if (balancePrefix.hasMatch(prefix) &&
          !incomingPhrase.hasMatch(prefix) &&
          !topUpPhrase.hasMatch(prefix)) {
        continue;
      }
      return value;
    }
    return null;
  }

  static int? _parseAmount(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(',');
    if (parts.length > 2) return null;

    var whole = parts.first.replaceAll('.', '');
    if (whole.isEmpty) return null;
    var value = int.tryParse(whole);
    if (value == null) return null;

    if (parts.length == 2 && parts[1].isNotEmpty) {
      final first = int.tryParse(parts[1][0]);
      if (first == null) return null;
      if (first >= 5) value += 1;
    }

    if (value <= 0 || value > TransactionRules.maxAmount) return null;
    return value;
  }

  static NotificationDraftType? _readType(String text) {
    NotificationDraftType? best;
    var bestStart = 1 << 30;

    for (final signal in _signals) {
      final match = signal.pattern.firstMatch(text);
      if (match == null) continue;
      if (match.start < bestStart) {
        best = signal.type;
        bestStart = match.start;
      }
    }
    return best;
  }
}

class _Signal {
  const _Signal(this.type, this.pattern);

  final NotificationDraftType type;
  final RegExp pattern;
}
