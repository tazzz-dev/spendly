import 'dart:convert';

import '../../core/dates.dart';

/// Jenis baris yang dikenal berkas JSON ekspor Sepran.
///
/// Berkas menyebutnya `expense`, `income`, dan `transfer`. Nama sengaja tidak
/// memakai [TxKind][]: `transfer` di berkas masih berupa satu baris dengan
/// rekening tujuan, bukan dua baris seperti di basis data kita.
enum SepranJsonKind { income, expense, transfer }

/// Satu baris transaksi dari berkas JSON Sepran.
class SepranJsonTransaction {
  const SepranJsonTransaction({
    required this.date,
    required this.kind,
    required this.amount,
    required this.title,
    required this.category,
    required this.wallet,
    this.time,
    this.counterWallet,
  });

  /// `YYYY-MM-DD`.
  final String date;

  /// Jam `HH:MM`, bila berkas memuatnya.
  final String? time;

  final SepranJsonKind kind;

  /// **Bertanda**: pemasukan positif, pengeluaran negatif, pindah saldo
  /// positif (nominal yang dipindahkan).
  final int amount;

  final String title;
  final String category;

  /// Nama rekening asal.
  final String wallet;

  /// Nama rekening tujuan; hanya untuk pindah saldo.
  final String? counterWallet;

  /// Dampak baris ini pada saldo [wallet].
  ///
  /// Pindah saldo mengurangi rekening asal sebesar nominalnya. Rekening tujuan
  /// mendapat tambahan yang sama lewat [counterWallet].
  int get walletDelta => switch (kind) {
    SepranJsonKind.income => amount,
    SepranJsonKind.expense => -amount.abs(),
    SepranJsonKind.transfer => -amount.abs(),
  };

  /// Dampak baris ini pada saldo [counterWallet], nol untuk non-transfer.
  int get counterWalletDelta =>
      kind == SepranJsonKind.transfer ? amount.abs() : 0;
}

/// Ringkasan satu rekening yang disebut berkas.
///
/// [openingBalance] sudah dihitung, bukan dibaca: saldo target dikurangi
/// seluruh mutasi rekening itu. Karena itu saldo akhir sesudah impor akan sama
/// dengan [targetBalance].
class SepranJsonWalletSummary {
  const SepranJsonWalletSummary({
    required this.name,
    required this.transactionCount,
    required this.netFlow,
    this.targetBalance,
    this.openingBalance,
  });

  final String name;

  /// Saldo akhir yang diinginkan, dibaca dari `wallet_balances`.
  ///
  /// Null bila rekening hanya muncul di daftar transaksi tanpa saldo target.
  final int? targetBalance;

  /// `targetBalance - netFlow`. Null bila [targetBalance] null.
  final int? openingBalance;

  /// Berapa baris menyentuh rekening ini. Pindah saldo dihitung pada kedua
  /// rekening yang terlibat.
  final int transactionCount;

  /// Jumlah nominal bertanda seluruh baris yang menyentuh rekening ini.
  final int netFlow;

  /// Apakah rekening ini punya saldo target di berkas.
  bool get hasTarget => targetBalance != null;
}

/// Hasil membaca satu berkas JSON Sepran.
class SepranJsonPreview {
  const SepranJsonPreview({
    required this.rows,
    required this.wallets,
    required this.skipped,
    required this.skippedBalances,
  });

  final List<SepranJsonTransaction> rows;

  /// Rekening unik, urut seperti di `wallet_balances` lalu transaksi.
  final List<SepranJsonWalletSummary> wallets;

  /// Baris transaksi yang dilewati karena tidak valid.
  final int skipped;

  /// Baris `wallet_balances` yang dilewati karena tidak valid.
  final int skippedBalances;

  int get income => rows
      .where((row) => row.kind == SepranJsonKind.income)
      .fold<int>(0, (sum, row) => sum + row.amount);

  int get expense => rows
      .where((row) => row.kind == SepranJsonKind.expense)
      .fold<int>(0, (sum, row) => sum + row.amount.abs());

  int get transferCount =>
      rows.where((row) => row.kind == SepranJsonKind.transfer).length;

  /// Tanggal paling awal, atau null bila tidak ada baris.
  String? get firstDate {
    if (rows.isEmpty) return null;
    return rows
        .map((row) => row.date)
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  }

  /// Tanggal paling akhir, atau null bila tidak ada baris.
  String? get lastDate {
    if (rows.isEmpty) return null;
    return rows
        .map((row) => row.date)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
  }

  List<String> get walletNames =>
      wallets.map((wallet) => wallet.name).toList(growable: false);
}

/// Membaca berkas JSON ekspor Sepran dari HP.
///
/// Formatnya berbeda dari `.xlsx`: selain transaksi, berkas memuat saldo akhir
/// tiap rekening. Saldo itulah yang dipakai untuk menghitung saldo awal, supaya
/// angka di aplikasi ini langsung sama dengan angka di HP.
///
/// Baris yang tidak valid dilewati dan dihitung, sama seperti impor Excel
/// (SPEC X-9). Nama rekening dibandingkan tanpa memandang besar-kecil huruf,
/// karena nama rekening di aplikasi ini juga unik tanpa memandang besar-kecil
/// huruf (SPEC G-9).
class SepranJsonParser {
  const SepranJsonParser();

  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final RegExp _timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');

  SepranJsonPreview parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Berkas JSON tidak valid: ${error.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Isi berkas harus berupa objek JSON dengan "wallet_balances" dan '
        '"transactions".',
      );
    }

    final rawBalances = decoded['wallet_balances'];
    final rawTransactions = decoded['transactions'];
    if (rawBalances != null && rawBalances is! List) {
      throw const FormatException('"wallet_balances" harus berupa daftar.');
    }
    if (rawTransactions != null && rawTransactions is! List) {
      throw const FormatException('"transactions" harus berupa daftar.');
    }

    // Nama rekening disatukan lebih dulu, supaya "BLU" dan "blu" tidak menjadi
    // dua rekening. Ejaan yang dipakai adalah yang pertama ditemui.
    final names = <String, String>{};
    String remember(String raw) {
      final name = raw.trim();
      final key = name.toLowerCase();
      return names.putIfAbsent(key, () => name);
    }

    final balances = rawBalances is List ? rawBalances : const <Object?>[];
    final transactions = rawTransactions is List
        ? rawTransactions
        : const <Object?>[];

    final targets = <String, int>{};
    final balanceOrder = <String>[];
    var skippedBalances = 0;

    for (final raw in balances) {
      if (raw is! Map) {
        skippedBalances++;
        continue;
      }
      final rawName = raw['name'];
      final name = rawName is String ? rawName.trim() : '';
      final target = _money(raw['balance']);
      if (name.isEmpty || target == null) {
        skippedBalances++;
        continue;
      }

      final canonical = remember(name);
      final key = canonical.toLowerCase();
      if (!targets.containsKey(key)) balanceOrder.add(canonical);
      // Bila nama muncul dua kali, entri terakhir yang menang.
      targets[key] = target;
    }

    final rows = <SepranJsonTransaction>[];
    var skipped = 0;

    for (final raw in transactions) {
      if (raw is! Map) {
        skipped++;
        continue;
      }

      final date = _date(raw['date']);
      final kind = _kind(raw['type']);
      final amount = _money(raw['amount']);
      final rawWallet = raw['wallet'];
      final wallet = rawWallet is String ? rawWallet.trim() : '';

      if (date == null ||
          kind == null ||
          amount == null ||
          amount == 0 ||
          wallet.isEmpty) {
        skipped++;
        continue;
      }

      String? counterWallet;
      if (kind == SepranJsonKind.transfer) {
        final rawCounter = raw['counter_wallet'];
        final counter = rawCounter is String ? rawCounter.trim() : '';
        if (counter.isEmpty || counter.toLowerCase() == wallet.toLowerCase()) {
          skipped++;
          continue;
        }
        counterWallet = counter;
      }

      rows.add(
        SepranJsonTransaction(
          date: date,
          time: _time(raw['time']),
          kind: kind,
          // Tanda dinormalisasi: pengeluaran selalu negatif, pemasukan dan
          // pindah saldo selalu positif. Berkas yang tandanya keliru tidak
          // boleh merusak saldo.
          amount: kind == SepranJsonKind.expense ? -amount.abs() : amount.abs(),
          title: _text(raw['title']),
          category: _text(raw['category']),
          wallet: remember(wallet),
          counterWallet: counterWallet == null ? null : remember(counterWallet),
        ),
      );
    }

    final counts = <String, int>{};
    final flows = <String, int>{};

    for (final row in rows) {
      final key = row.wallet.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      flows[key] = (flows[key] ?? 0) + row.walletDelta;

      final counter = row.counterWallet;
      if (counter != null) {
        final counterKey = counter.toLowerCase();
        counts[counterKey] = (counts[counterKey] ?? 0) + 1;
        flows[counterKey] = (flows[counterKey] ?? 0) + row.counterWalletDelta;
      }
    }

    // Urutan: rekening yang punya saldo target lebih dulu (urutan berkas),
    // lalu rekening yang hanya muncul di transaksi.
    final ordered = <String>[
      ...balanceOrder,
      for (final name in names.values)
        if (!targets.containsKey(name.toLowerCase())) name,
    ];

    final wallets = [
      for (final name in ordered)
        SepranJsonWalletSummary(
          name: name,
          targetBalance: targets[name.toLowerCase()],
          openingBalance: targets[name.toLowerCase()] == null
              ? null
              : targets[name.toLowerCase()]! - (flows[name.toLowerCase()] ?? 0),
          transactionCount: counts[name.toLowerCase()] ?? 0,
          netFlow: flows[name.toLowerCase()] ?? 0,
        ),
    ];

    return SepranJsonPreview(
      rows: rows,
      wallets: wallets,
      skipped: skipped,
      skippedBalances: skippedBalances,
    );
  }

  static SepranJsonKind? _kind(Object? value) {
    if (value is! String) return null;
    return switch (value.trim().toLowerCase()) {
      'income' || 'pemasukan' => SepranJsonKind.income,
      'expense' || 'pengeluaran' => SepranJsonKind.expense,
      'transfer' || 'pindah saldo' => SepranJsonKind.transfer,
      _ => null,
    };
  }

  static String _text(Object? value) =>
      value is String ? value.trim() : (value == null ? '' : '$value'.trim());

  /// Nominal boleh berupa angka JSON maupun teks desimal.
  ///
  /// Teks menerima gaya Indonesia (`1.234.567,89`) dan gaya berkas
  /// (`2500000.00`). Hasilnya rupiah utuh; bagian pecahan dibulatkan.
  static int? _money(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is! String) return null;

    var text = value.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (text.isEmpty || text == '-') return null;

    final negative = text.startsWith('-');
    text = text.replaceAll('-', '');
    if (text.isEmpty) return null;

    if (text.contains(',')) {
      // Koma desimal; titik pemisah ribuan.
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      final dots = '.'.allMatches(text).length;
      if (dots > 1) {
        text = text.replaceAll('.', '');
      } else if (dots == 1) {
        final fraction = text.split('.').last;
        // "1.234" gaya Indonesia, "2500000.00" desimal.
        if (fraction.length == 3) text = text.replaceAll('.', '');
      }
    }

    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    final rounded = parsed.round();
    return negative ? -rounded : rounded;
  }

  /// Menolak tanggal yang tidak ada di kalender, seperti 31 Februari.
  static String? _date(Object? value) {
    if (value is! String) return null;
    final match = _datePattern.firstMatch(value.trim());
    if (match == null) return null;

    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return AppDate.key(date);
  }

  static String? _time(Object? value) {
    if (value is! String) return null;
    final match = _timePattern.firstMatch(value.trim());
    if (match == null) return null;

    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
