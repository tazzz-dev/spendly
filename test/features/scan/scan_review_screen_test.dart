import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/mutation_source.dart';
import 'package:pencatatan_keuangan/domain/scanned_transaction.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';
import 'package:pencatatan_keuangan/features/scan/scan_review_screen.dart';

/// Uji layar tinjauan Scan AI: hanya baris yang dicentang dan memakai dompet
/// yang dipilih yang boleh masuk ke basis data.
void main() {
  late AppDatabase db;
  String? danaWalletId;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Membaca rekening bawaan sekaligus memicu pembuatan skema (SPEC G-8).
    await db.select(db.wallets).get();
  });

  tearDown(() => db.close());

  const items = [
    ScannedTransaction(
      id: 'scan-0',
      date: '2026-10-18',
      time: '12:34',
      amount: 25000,
      type: ScannedTransactionType.expense,
      title: 'Warung Makan Bu Sari',
      category: 'Makanan & Minuman',
      rawText: 'Warung Makan Bu Sari -Rp25.000',
    ),
    ScannedTransaction(
      id: 'scan-1',
      date: '2026-10-19',
      time: '09:15',
      amount: 150000,
      type: ScannedTransactionType.income,
      title: 'Transfer dari Budi',
      category: 'Pemasukan',
      rawText: 'Transfer dari Budi Rp150.000',
    ),
  ];

  /// Membuka layar tinjauan dengan layar tinggi supaya kedua kartu ikut dibangun
  /// oleh `ListView.builder` yang malas.
  Future<void> openReview(
    WidgetTester tester, {
    List<ScannedTransaction>? reviewItems,
    MutationSource? source,
    List<String> imagePaths = const [],
  }) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ScanReviewScreen(
                        items: reviewItems ?? items,
                        sourceCount: 1,
                        source: source,
                        imagePaths: imagePaths,
                      ),
                    ),
                  ),
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }

  /// Melepas pohon widget lebih dulu supaya langganan stream drift ditutup di
  /// dalam uji, bukan setelah batas waktu uji habis.
  Future<void> closeUi(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // drift menjadwalkan timer nol detik saat langganan stream ditutup; satu
    // langkah waktu kecil cukup untuk menjalankannya sebelum uji selesai.
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Membungkus uji supaya pohon widget selalu dilepas, termasuk saat gagal.
  /// Tanpa ini, kegagalan di tengah uji meninggalkan stream terbuka yang
  /// membuat proses `flutter test` tidak pernah selesai.
  void reviewTest(
    String description,
    Future<void> Function(WidgetTester) body, {
    List<ScannedTransaction>? reviewItems,
    MutationSource? source,
    List<String> imagePaths = const [],
    Future<void> Function()? prepare,
  }) {
    testWidgets(description, (tester) async {
      try {
        if (prepare != null) await prepare();
        await openReview(
          tester,
          reviewItems: reviewItems,
          source: source,
          imagePaths: imagePaths,
        );
        await body(tester);
      } finally {
        await closeUi(tester);
      }
    });
  }

  Future<void> pickBulkWallet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('scan_wallet')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang Tunai').last);
    await tester.pumpAndSettle();
  }

  reviewTest('menyimpan hanya baris yang dicentang', (tester) async {
    expect(find.text('Warung Makan Bu Sari'), findsOneWidget);
    expect(find.text('Transfer dari Budi'), findsOneWidget);

    await pickBulkWallet(tester);

    // Baris pertama dilepas centangnya.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text('1 transaksi dipilih'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan_save')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, 'Transfer dari Budi');
    expect(rows.single.date, '2026-10-19');
    expect(rows.single.note, 'Dari Scan AI');
    // Uang masuk disimpan bertanda positif, uang keluar bertanda negatif.
    expect(rows.single.amount, 150000);
  });

  reviewTest('tanpa dompet, simpan ditolak dan tidak menulis apa pun', (
    tester,
  ) async {
    await tester.tap(find.byKey(const Key('scan_save')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih dompet terlebih dahulu.'), findsOneWidget);
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  reviewTest('pilih semua lalu simpan menulis kedua baris', (tester) async {
    await pickBulkWallet(tester);

    await tester.tap(find.byKey(const Key('scan_save')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(2));
    // Pengeluaran disimpan negatif, pemasukan positif (SPEC RW-5).
    expect(rows.map((row) => row.amount).toSet(), {-25000, 150000});
  });

  reviewTest(
    'baris yang sudah tercatat otomatis dilepas centangnya',
    (tester) async {
      expect(
        find.textContaining('Sudah tercatat: "Makan lama"'),
        findsOneWidget,
      );
      expect(find.text('1 transaksi dipilih'), findsOneWidget);

      await pickBulkWallet(tester);
      await tester.tap(find.byKey(const Key('scan_save')));
      await tester.pumpAndSettle();

      final rows = await db.select(db.transactions).get();
      // Satu transaksi lama tetap satu, hanya pemasukan baru yang ditambahkan.
      expect(rows, hasLength(2));
      expect(rows.where((row) => row.title == 'Makan lama'), hasLength(1));
      expect(
        rows.where((row) => row.title == 'Transfer dari Budi'),
        hasLength(1),
      );
    },
    prepare: () async {
      final wallet = (await db.select(db.wallets).getSingle());
      await TransactionRepository(db).createSimple(
        kind: TxKind.expense,
        amount: 25000,
        walletId: wallet.id,
        title: 'Makan lama',
        category: 'Makanan & Minuman',
        date: '2026-10-18',
        time: '12:34',
      );
    },
  );

  reviewTest(
    'mencentang duplikat memunculkan konfirmasi sebelum menyimpan',
    (tester) async {
      await pickBulkWallet(tester);

      // Centang ulang baris yang tadi otomatis dilepas.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('2 transaksi dipilih'), findsOneWidget);

      await tester.tap(find.byKey(const Key('scan_save')));
      await tester.pumpAndSettle();

      expect(find.text('Mungkin sudah tercatat'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(1)); // hanya transaksi lama, tidak ada tambahan.
      expect(find.text('1 transaksi dipilih'), findsOneWidget);
    },
    prepare: () async {
      final wallet = (await db.select(db.wallets).getSingle());
      await TransactionRepository(db).createSimple(
        kind: TxKind.expense,
        amount: 25000,
        walletId: wallet.id,
        title: 'Makan lama',
        category: 'Makanan & Minuman',
        date: '2026-10-18',
        time: '12:34',
      );
    },
  );

  reviewTest(
    'sumber DANA memilih dompet DANA otomatis',
    (tester) async {
      expect(
        find.textContaining('Dompet "DANA" dipilih otomatis'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('scan_save')));
      await tester.pumpAndSettle();

      expect(find.text('Pilih dompet terlebih dahulu.'), findsNothing);

      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(2));
      expect(rows.where((row) => row.walletId == danaWalletId).length, 2);
    },
    source: const MutationSource(key: 'dana', label: 'DANA', aliases: ['dana']),
    prepare: () async {
      danaWalletId = await WalletRepository(db).create(
        name: 'DANA',
        type: WalletType.ewallet,
        openingBalance: 0,
        iconKey: 'wallet',
        color: 0xFF118EEA,
      );
    },
  );

  reviewTest('tombol lihat foto membuka pratinjau gambar sumber', (
    tester,
  ) async {
    expect(find.text('Lihat foto sumber (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan_view_photos')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Foto sumber'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan_close_photos')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Foto sumber'), findsNothing);
  }, imagePaths: const ['/tidak/ada.png']);

  reviewTest(
    'kategori hasil scan bisa ditulis bebas, bukan hanya memilih',
    (tester) async {
      await pickBulkWallet(tester);

      await tester.enterText(
        find.byKey(const Key('scan_category_scan-0')),
        'Jajan Kantor',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan_save')));
      await tester.pumpAndSettle();

      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.category, 'Jajan Kantor');
    },
    reviewItems: const [
      ScannedTransaction(
        id: 'scan-0',
        date: '2026-10-18',
        amount: 25000,
        type: ScannedTransactionType.expense,
        title: 'Warung Makan Bu Sari',
        category: 'Makanan & Minuman',
      ),
    ],
  );

  reviewTest(
    'pilihan arah untuk semua mengubah pemasukan/pengeluaran sekaligus',
    (tester) async {
      await pickBulkWallet(tester);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('scan_direction_all')),
          matching: find.text('Masuk'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan_save')));
      await tester.pumpAndSettle();

      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.kind, TxKind.income.storageValue);
      expect(rows.single.amount, 25000);
    },
    reviewItems: const [
      ScannedTransaction(
        id: 'scan-0',
        date: '2026-10-18',
        amount: 25000,
        type: ScannedTransactionType.expense,
        title: 'Warung Makan Bu Sari',
        category: 'Makanan & Minuman',
      ),
    ],
  );
}
