// `isNotNull` disembunyikan dari drift: nama itu dipakai drift untuk ekspresi
// SQL, sementara di berkas ini yang dimaksud adalah pencocok dari flutter_test.
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/settings_repository.dart';
import 'package:pencatatan_keuangan/domain/app_preferences.dart';
import 'package:pencatatan_keuangan/domain/theme_choice.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('setelan yang belum pernah ditulis memakai nilai bawaan', () async {
    final prefs = await repository.load();

    expect(prefs, const AppPreferences());
    expect(prefs.theme, AppTheme.blue);
    expect(prefs.showDecimals, isTrue);
  });

  test('setelan yang disimpan bisa dibaca kembali, berkali-kali', () async {
    final prefs = const AppPreferences().copyWith(
      theme: AppTheme.dark,
      showDecimals: false,
      language: AppLanguage.thailand,
      reminderEnabled: true,
      reminderTime: '19:45',
    );
    await repository.save(prefs.diff(const AppPreferences()));

    expect(await repository.load(), prefs);
  });

  test('menyimpan dua kali menimpa nilai lama', () async {
    await repository.save({SettingKey.theme: 'pink'});
    await repository.save({SettingKey.theme: 'purple'});

    expect((await repository.load()).theme, AppTheme.purple);
  });

  test('mengosongkan data membiarkan setelan tetap', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Buat rekening sungguhan dahulu: transaksi merujuknya lewat kunci
    // asing yang sedang ditegakkan (SPEC R-4).
    await db
        .into(db.wallets)
        .insert(
          WalletsCompanion.insert(
            id: 'wallet-1',
            name: 'BCA',
            type: 'bank',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'tx-1',
            kind: 'income',
            walletId: 'wallet-1',
            title: const Value('Gaji'),
            amount: 500000,
            date: '2026-10-19',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.suggestions)
        .insert(
          SuggestionsCompanion.insert(
            id: 'sg-1',
            type: 'title',
            name: 'Gaji',
            kind: 'income',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await repository.save({SettingKey.showDecimals: '0'});

    await repository.clearAllData();

    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.suggestions).get(), isEmpty);
    expect(await db.select(db.debts).get(), isEmpty);
    expect((await repository.load()).showDecimals, isFalse); // setelan selamat.
  });

  test('setelah dikosongkan tetap ada tepat satu rekening bawaan', () async {
    // SPEC G-8: pemasangan pertama membuat rekening bawaan; ikutkan satu
    // rekening tambahan untuk membuktikan semuanya ikut terhapus.
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.wallets)
        .insert(
          WalletsCompanion.insert(
            id: 'wallet-2',
            name: 'BCA',
            type: 'bank',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await repository.clearAllData();

    final wallets = await db.select(db.wallets).get();
    expect(wallets.length, 1);
    expect(wallets.single.name, 'Uang Tunai');
    expect(wallets.single.isDefault, isTrue);
  });
}
