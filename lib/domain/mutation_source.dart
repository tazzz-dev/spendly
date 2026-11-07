import 'wallet_balance.dart';

/// Sumber mutasi yang dikenali dari teks hasil OCR.
///
/// Deteksi ini hanya dipakai untuk **menebak** dompet yang paling mungkin dan
/// memberi tahu pengguna sumber gambarnya. Tidak ada baris yang otomatis
/// dianggap baru atau lama hanya karena sumbernya terdeteksi.
class MutationSource {
  const MutationSource({
    required this.key,
    required this.label,
    required this.aliases,
  });

  /// Kunci stabil untuk pengujian dan pemetaan.
  final String key;

  /// Nama yang ditampilkan ke pengguna, mis. `DANA`.
  final String label;

  /// Kata-kata yang menandakan sumber ini. Aliases yang lebih panjang
  /// (mis. `bca digital`) mengalahkan yang pendek (`bca`) saat menghitung skor.
  final List<String> aliases;
}

/// Mendeteksi sumber mutasi dari teks OCR dan mencocokkannya dengan rekening
/// yang sudah dimiliki pengguna.
///
/// Murni: tanpa Flutter, tanpa basis data, sehingga mudah diuji dengan teks
/// tangkapan layar sungguhan.
class MutationSourceDetector {
  const MutationSourceDetector();

  /// Daftar sumber yang dikenali. Urutannya hanya menentukan pemenang saat skor
  /// sama; skor sendiri dihitung dari panjang dan jumlah kemunculan alias.
  static const List<MutationSource> sources = [
    MutationSource(
      key: 'dana',
      label: 'DANA',
      aliases: ['dana', 'search send money'],
    ),
    MutationSource(key: 'ovo', label: 'OVO', aliases: ['ovo']),
    MutationSource(
      key: 'gopay',
      label: 'GoPay',
      aliases: ['gopay', 'go-pay', 'go pay'],
    ),
    MutationSource(
      key: 'shopeepay',
      label: 'ShopeePay',
      aliases: ['shopeepay', 'shopee pay', 'shopee-pay'],
    ),
    MutationSource(
      key: 'bca',
      label: 'BCA',
      aliases: ['klikbca', 'bca mobile', 'mybca', 'bca'],
    ),
    MutationSource(
      key: 'mandiri',
      label: 'Mandiri',
      aliases: ['livin', 'mandiri'],
    ),
    MutationSource(key: 'bri', label: 'BRI', aliases: ['brimo', 'bri']),
    MutationSource(
      key: 'bni',
      label: 'BNI',
      aliases: ['bni mobile', 'wondr', 'bni'],
    ),
    MutationSource(
      key: 'blu',
      label: 'Blu',
      aliases: ['blu by bca digital', 'bca digital', 'blu'],
    ),
    MutationSource(
      key: 'seabank',
      label: 'SeaBank',
      aliases: ['seabank', 'sea bank'],
    ),
    MutationSource(
      key: 'jago',
      label: 'Bank Jago',
      aliases: ['bank jago', 'jago'],
    ),
    MutationSource(
      key: 'cimb',
      label: 'CIMB Niaga',
      aliases: ['octo mobile', 'cimb niaga', 'cimb', 'octo'],
    ),
    MutationSource(
      key: 'permata',
      label: 'Permata',
      aliases: ['permata mobile', 'permata'],
    ),
    MutationSource(key: 'bsi', label: 'BSI', aliases: ['bsi mobile', 'bsi']),
    MutationSource(key: 'btn', label: 'BTN', aliases: ['btn mobile', 'btn']),
    MutationSource(key: 'danamon', label: 'Danamon', aliases: ['danamon']),
    MutationSource(key: 'ocbc', label: 'OCBC', aliases: ['ocbc']),
    MutationSource(key: 'jenius', label: 'Jenius', aliases: ['jenius']),
  ];

  /// Frasa umum yang mengandung nama merek tetapi bukan penanda sumber.
  static final RegExp _genericPhrases = RegExp(
    r'\bsumber\s+dana\b',
    caseSensitive: false,
  );

  /// Mengembalikan sumber dengan skor tertinggi, atau `null` bila tak ada yang
  /// cocok. Skor = jumlah kemunculan × panjang alias, sehingga teks yang
  /// menyebut "BCA Digital" beberapa kali tidak salah dibaca sebagai BCA biasa.
  MutationSource? detect(String text) {
    if (text.trim().isEmpty) return null;
    final lower = text
        .replaceAll(_genericPhrases, ' ')
        .replaceAll('\u00a0', ' ')
        .toLowerCase();

    MutationSource? best;
    var bestScore = 0;
    for (final source in sources) {
      var score = 0;
      for (final alias in source.aliases) {
        final hits = _countOccurrences(lower, alias.toLowerCase());
        score += hits * alias.length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = source;
      }
    }
    return best;
  }

  /// Mencari rekening pengguna yang namanya memuat nama sumber atau salah satu
  /// aliasnya. Alias terpanjang dicoba lebih dulu supaya "BCA Digital" memilih
  /// rekening Blu, bukan rekening BCA.
  WalletBalance? matchWallet(
    MutationSource? source,
    List<WalletBalance> wallets,
  ) {
    if (source == null || wallets.isEmpty) return null;

    final aliases = <String>{source.label, ...source.aliases}.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final alias in aliases) {
      final needle = _normalize(alias);
      if (needle.isEmpty) continue;
      for (final wallet in wallets) {
        if (_normalize(wallet.name).contains(needle)) return wallet;
      }
    }
    return null;
  }

  static int _countOccurrences(String text, String needle) {
    if (needle.isEmpty) return 0;
    final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(needle)}(?![a-z0-9])');
    return pattern.allMatches(text).length;
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
