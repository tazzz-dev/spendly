import 'scanned_transaction.dart';

/// Menebak kategori dari judul/merchant hasil OCR.
///
/// Ini **bukan** model bahasa: daftar kata kunci yang sengaja bisa dibaca dan
/// diuji. Bila tidak ada yang cocok, pengeluaran menjadi "Lainnya" dan
/// pemasukan menjadi "Pemasukan". Pengguna selalu bisa menggantinya di layar
/// tinjauan.
class CategoryGuesser {
  const CategoryGuesser._();

  static const String expenseFallback = 'Lainnya';
  static const String incomeFallback = 'Pemasukan';

  /// Urutan penting: kategori pertama yang cocok yang dipakai. Kata kunci yang
  /// lebih khusus diletakkan lebih dulu.
  static const List<(String, List<String>)> _expenseRules = [
    (
      'Makanan & Minuman',
      [
        'makan',
        'minum',
        'warung',
        'resto',
        'restoran',
        'cafe',
        'kafe',
        'kopi',
        'bakso',
        'mie',
        'nasi',
        'ayam',
        'martabak',
        'pizza',
        'burger',
        'gofood',
        'grabfood',
        'shopeefood',
        'food',
        'kantin',
        'boba',
        'juice',
        'jus',
        'starbucks',
        'kfc',
        'mcdonald',
        'sushi',
        'goreng',
        'gorengan',
        'telor',
        'telur',
        'beverage',
        'bakery',
        'roti',
        'kue',
        'cake',
        'dessert',
      ],
    ),
    (
      'Transportasi',
      [
        'gojek',
        'grab',
        'ojek',
        'taksi',
        'taxi',
        'bensin',
        'pertamina',
        'spbu',
        'bbm',
        'parkir',
        'tol',
        'krl',
        'mrt',
        'lrt',
        'transjakarta',
        'bus',
        'travel',
        'tiket',
        'kereta',
        'pesawat',
        'gofood driver',
      ],
    ),
    (
      'Tagihan',
      [
        'listrik',
        'pln',
        'pdam',
        'air',
        'internet',
        'indihome',
        'telkom',
        'bpjs',
        'kartu kredit',
        'cicilan',
        'tagihan',
        'iuran',
        'sewa',
        'kos',
        'asuransi',
        'pajak',
      ],
    ),
    (
      'Pulsa & Data',
      [
        'pulsa',
        'paket data',
        'kuota',
        'telkomsel',
        'indosat',
        'im3',
        'xl',
        'tri',
        'smartfren',
        'by.u',
        'data',
      ],
    ),
    (
      'Belanja',
      [
        'shopee',
        'tokopedia',
        'lazada',
        'blibli',
        'tiktok shop',
        'indomaret',
        'alfamart',
        'supermarket',
        'minimarket',
        'hypermart',
        'belanja',
        'mall',
        'market',
        'apotek',
        'toko',
      ],
    ),
    (
      'Hiburan',
      [
        'netflix',
        'spotify',
        'youtube',
        'disney',
        'vidio',
        'game',
        'steam',
        'bioskop',
        'cinema',
        'cgv',
        'xxi',
        'langganan',
        'subscription',
        'hiburan',
      ],
    ),
    (
      'Kesehatan',
      [
        'klinik',
        'rumah sakit',
        'dokter',
        'obat',
        'farmasi',
        'pharmacy',
        'hospital',
        'lab',
        'gigi',
      ],
    ),
    (
      'Pendidikan',
      [
        'sekolah',
        'kuliah',
        'kampus',
        'kursus',
        'buku',
        'udemy',
        'coursera',
        'pendidikan',
        'spp',
        'ukt',
      ],
    ),
    ('Donasi', ['donasi', 'zakat', 'infaq', 'sedekah', 'charity', 'amal']),
    ('Transfer', ['transfer ke', 'kirim ke', 'transfer', 'trf']),
  ];

  static const List<(String, List<String>)> _incomeRules = [
    (
      'Gaji',
      ['gaji', 'salary', 'payroll', 'upah', 'thr', 'bonus', 'tunjangan'],
    ),
    (
      'Pemasukan',
      [
        'refund',
        'cashback',
        'pengembalian dana',
        'bunga',
        'dividen',
        'penjualan',
        'diterima',
        'menerima',
        'masuk',
        'top up',
        'topup',
        'isi saldo',
        'pendapatan',
        'income',
      ],
    ),
  ];

  static String guess(String rawText, ScannedTransactionType type) {
    final text = rawText.toLowerCase();
    final rules = type == ScannedTransactionType.income
        ? _incomeRules
        : _expenseRules;

    for (final rule in rules) {
      for (final keyword in rule.$2) {
        if (text.contains(keyword)) return rule.$1;
      }
    }

    return type == ScannedTransactionType.income
        ? incomeFallback
        : expenseFallback;
  }

  /// Daftar kategori bawaan untuk pemilih di layar tinjauan. Kategori milik
  /// pengguna yang sudah ada ditambahkan oleh layar, bukan di sini.
  static List<String> get expenseCategories =>
      [for (final rule in _expenseRules) rule.$1] + [expenseFallback];

  static List<String> get incomeCategories =>
      [for (final rule in _incomeRules) rule.$1] + [incomeFallback];
}
