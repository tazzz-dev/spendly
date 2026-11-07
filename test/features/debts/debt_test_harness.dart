import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/core/money.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/debt_repository.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';

/// `testWidgets` yang meruntuhkan pohon widget lebih dulu.
///
/// Drift menjadwalkan `Timer` berdurasi nol saat stream query dibatalkan. Di
/// widget test, pembatalan itu terjadi ketika `ProviderScope` dibuang, yaitu
/// tepat sebelum binding memeriksa timer yang tersisa. Satu pump tambahan
/// memberi timer itu kesempatan berbunyi sehingga test tidak gagal karena
/// "A Timer is still pending".
void debtWidgetTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

/// Perkakas bersama untuk widget test modul Hutang.
///
/// Membuka basis data SQLite di memori yang sama untuk layar dan repository,
/// sehingga test bisa memeriksa keadaan setelah berinteraksi dengan UI.
class DebtTestHarness {
  DebtTestHarness._(this.db) : repository = DebtRepository(db);

  static Future<DebtTestHarness> create() async {
    // Sama seperti main(): AppDate memakai nama bulan Indonesia.
    await initializeDateFormatting('id_ID');
    final harness = DebtTestHarness._(AppDatabase(NativeDatabase.memory()));
    // Paksa skema dan rekening bawaan selesai dibuat sebelum widget dipasang.
    await harness.repository.watchRecords().first;
    return harness;
  }

  final AppDatabase db;
  final DebtRepository repository;

  /// Format tanpa desimal supaya teks uji pendek dan mudah dibaca.
  final MoneyFormat money = MoneyFormat(showDecimals: false);

  Future<String> cashWalletId() async {
    final balances = await WalletRepository(db).watchBalances().first;
    return balances.firstWhere((wallet) => wallet.isDefault).id;
  }

  Future<void> close() => db.close();

  Widget app(Widget home, {MoneyFormat? money, double textScale = 1}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        moneyFormatProvider.overrideWithValue(money ?? this.money),
      ],
      child: MaterialApp(
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: textScale == 1
                ? media
                : media.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: home,
      ),
    );
  }
}
