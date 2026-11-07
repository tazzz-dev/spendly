import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/mutation_text_parser.dart';
import 'package:pencatatan_keuangan/domain/scanned_transaction.dart';

void main() {
  const parser = MutationTextParser();
  final now = DateTime(2026, 10, 20, 15, 30);

  group('mutasi dompet digital', () {
    test('DANA: satu pembayaran dengan tanggal dan jam', () {
      final items = parser.parse('''
Transaksi Berhasil
Pembayaran ke Warung Makan Bu Sari
18 Okt 2026
12:34
-Rp25.000
Saldo Rp175.000
''', now: now);

      expect(items, hasLength(1));
      final item = items.single;
      expect(item.amount, 25000);
      expect(item.type, ScannedTransactionType.expense);
      expect(item.date, '2026-10-18');
      expect(item.time, '12:34');
      expect(item.title, contains('Warung Makan'));
      expect(item.category, 'Makanan & Minuman');
      expect(item.dateGuessed, isFalse);
    });

    test('GoPay: transfer masuk dibaca sebagai pemasukan', () {
      final items = parser.parse('''
Kamu menerima transfer
dari Budi
Rp150.000
18 Okt 2026 09:15
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 150000);
      expect(items.single.type, ScannedTransactionType.income);
      expect(items.single.time, '09:15');
    });

    test('nominal bertanda minus dan plus', () {
      final items = parser.parse('''
Warung kopi
-Rp18.000
18/10/2026 08:00
Gaji bulanan
+Rp5.000.000
18/10/2026 09:00
''', now: now);

      expect(items, hasLength(2));
      expect(items[0].type, ScannedTransactionType.expense);
      expect(items[1].type, ScannedTransactionType.income);
      expect(items[1].amount, 5000000);
    });
  });

  group('mutasi bank', () {
    test('BCA: dd/mm/yyyy dengan detik dan nominal ribuan', () {
      final items = parser.parse('''
18/10/2026 12:34:56
TRANSFER KE PT MAJU JAYA
Rp1.500.000
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 1500000);
      expect(items.single.date, '2026-10-18');
      expect(items.single.time, '12:34');
      expect(items.single.type, ScannedTransactionType.expense);
      expect(items.single.category, 'Transfer');
    });

    test('tanggal berlaku untuk beberapa transaksi di bawahnya', () {
      final items = parser.parse('''
18/10/2026
GOFOOD MCDONALDS
Rp45.000
Gojek
Rp23.500
19/10/2026
Gaji bulanan
+Rp5.000.000
''', now: now);

      expect(items, hasLength(3));
      expect(items[0].date, '2026-10-18');
      expect(items[1].date, '2026-10-18');
      expect(items[2].date, '2026-10-19');
      expect(items[1].category, 'Transportasi');
      expect(items[2].type, ScannedTransactionType.income);
      expect(items[2].category, 'Gaji');
    });

    test('format nominal Indonesia dan internasional', () {
      final items = parser.parse('''
Belanja bulanan
Rp 1.234.567,00
18 Okt 2026
Top up
IDR 25,000
18 Okt 2026
''', now: now);

      expect(items, hasLength(2));
      expect(items[0].amount, 1234567);
      expect(items[1].amount, 25000);
      expect(items[1].type, ScannedTransactionType.income);
    });
  });

  group('ketahanan', () {
    test('mengabaikan baris saldo dan ringkasan', () {
      final items = parser.parse('''
Saldo Rp2.000.000
Total pengeluaran Rp1.000.000
Pembayaran listrik
Rp250.000
18/10/2026
Saldo akhir Rp750.000
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 250000);
      expect(items.single.category, 'Tagihan');
    });

    test('tanggal tanpa tahun memakai tahun berjalan', () {
      final items = parser.parse('''
Kopi
Rp20.000
18 Okt
''', now: now);

      expect(items.single.date, '2026-10-18');
    });

    test('tanggal tidak terbaca ditandai, bukan dibuang', () {
      final items = parser.parse('''
Pembayaran
Rp10.000
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.dateGuessed, isTrue);
      expect(items.single.date, '2026-10-20');
    });

    test('nominal yang sama tidak tersimpan dua kali', () {
      final items = parser.parse('''
Pembayaran ke Toko A
Rp25.000
18/10/2026
Pembayaran ke Toko A
Rp25.000
18/10/2026
''', now: now);

      expect(items, hasLength(1));
    });

    test('teks kosong menghasilkan daftar kosong', () {
      expect(parser.parse('', now: now), isEmpty);
      expect(parser.parse('Tidak ada transaksi di sini', now: now), isEmpty);
    });

    test('mengabaikan nomor kartu bertopeng dan header bank', () {
      // Kasus nyata dari OCR layar mutasi: "Bank Sejahtera •••• 1234" sempat
      // terbaca sebagai transaksi Rp1.234 berjudul "Mutasi Rekening".
      final items = parser.parse('''
Mutasi Rekening
Bank Sejahtera •••• 1234
27 Okt 2026 14:32
Pembayaran ke Toko Kopi Senja
-Rp25.000
Saldo Rp1.250.000
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 25000);
      expect(items.single.title, contains('Toko Kopi'));
      expect(items.single.date, '2026-10-27');
      expect(items.single.time, '14:32');
    });

    test('mengabaikan label nomor rekening', () {
      final items = parser.parse('''
No. Rekening 1234567890
Pembayaran listrik
Rp250.000
18/10/2026
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 250000);
      expect(items.single.title, isNot(contains('Rekening')));
    });

    test('baris bank yang memuat kata transaksi tetap dibaca', () {
      final items = parser.parse('''
BCA - Pembayaran kartu kredit
Rp1.200.000
18/10/2026
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 1200000);
    });

    test('DANA: kolom nominal dan tanggal yang sudah digabung per baris', () {
      final items = parser.parse('''
Activity
This Month Statement >
RIS SPBU 34-13805 -Rp56.860 27 Oct 2026 • 19:10
RIS Telor Gulung Sudirman -Rp10.000 27 Oct 2026 • 17:45
RIS CROHAUZ IFC -Rp30.000 27 Oct 2026 • 12:12
''', now: now);

      expect(items, hasLength(3));
      expect(items[0].amount, 56860);
      expect(items[0].title, contains('SPBU'));
      expect(items[0].title, isNot(contains('Statement')));
      expect(items[0].date, '2026-10-27');
      expect(items[0].time, '19:10');
      expect(items[0].category, 'Transportasi');
      expect(items[1].amount, 10000);
      expect(items[1].time, '17:45');
      expect(items[1].category, 'Makanan & Minuman');
      expect(items[2].amount, 30000);
      expect(items.every((item) => item.type == ScannedTransactionType.expense),
          isTrue);
    });

    test('kode SPBU bukan nominal tambahan', () {
      final items = parser.parse('''
SPBU 34-13805
-Rp56.860
27 Oct 2026 19:10
''', now: now);

      expect(items, hasLength(1));
      expect(items.single.amount, 56860);
      expect(items.single.title, contains('34-13805'));
    });

    test('nominal berbeda pada tanggal dan jam yang sama tetap disimpan', () {
      // Kunci deduplikasi sempat memakai objek nominal, bukan nilainya,
      // sehingga baris seperti ini saling menghapus.
      final items = parser.parse('''
Shopee Indonesia -Rp31.675 26 Oct 2026 • 14:32
Shopee Indonesia -Rp63.600 26 Oct 2026 • 14:32
''', now: now);

      expect(items.map((item) => item.amount), [31675, 63600]);
    });
  });
}
