import 'tx_rules.dart';

/// Kalkulator nominal untuk kolom Jumlah.
///
/// SPEC G-3: input nominal memakai kalkulator bawaan di dalam aplikasi, bukan
/// sekadar papan tik angka. Ditaruh di `domain/` supaya perhitungannya bisa
/// diuji tanpa membuka layar.
///
/// Murni bilangan bulat: hasil pembagian dibulatkan ke rupiah terdekat, karena
/// kita tidak pernah menyimpan pecahan. Lihat SPEC G-11.
class MoneyCalculator {
  const MoneyCalculator._();

  /// Lambang yang dipakai tombol kalkulator. Perkalian memakai huruf `x`, bukan
  /// `×`, supaya ungkapannya mudah ditulis di test dan di log.
  static const String multiply = 'x';
  static const String divide = '/';

  static const Set<String> _operators = {'+', '-', multiply, divide};

  static bool isOperator(String token) => _operators.contains(token);

  static bool _isDigit(String character) {
    final code = character.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  /// Menghitung [source], misalnya `2500x3+1000`.
  ///
  /// Mengembalikan null bila ungkapannya tidak sah, pembaginya nol, atau
  /// hasilnya melewati [maxAmount]. Pemanggil memperlakukan null sebagai
  /// "belum bisa disimpan", bukan sebagai nol.
  static int? evaluate(
    String source, {
    int maxAmount = TransactionRules.maxAmount,
  }) {
    final tokens = _tokenize(source);
    if (tokens == null) return null;

    final products = _collapseProducts(tokens, maxAmount);
    if (products == null) return null;

    return _collapseSums(products, maxAmount);
  }

  /// Memecah `2500x3` menjadi `['2500', 'x', '3']`.
  ///
  /// Bentuk yang diterima selalu berselang-seling angka dan operator, dimulai
  /// dan diakhiri angka. Selain itu dianggap salah ketik.
  static List<String>? _tokenize(String source) {
    final text = source.replaceAll(' ', '');
    if (text.isEmpty) return null;

    final tokens = <String>[];
    final buffer = StringBuffer();

    for (final character in text.split('')) {
      if (_isDigit(character)) {
        buffer.write(character);
      } else if (_operators.contains(character)) {
        // Operator harus punya angka di sebelah kirinya.
        if (buffer.isEmpty) return null;
        tokens.add(buffer.toString());
        buffer.clear();
        tokens.add(character);
      } else {
        return null;
      }
    }

    // Ungkapan yang berakhir dengan operator belum selesai diketik.
    if (buffer.isEmpty) return null;
    tokens.add(buffer.toString());

    return tokens;
  }

  /// Perkalian dan pembagian dikerjakan lebih dulu, sesuai kebiasaan berhitung.
  static List<String>? _collapseProducts(List<String> tokens, int maxAmount) {
    final stack = <String>[];
    var index = 0;

    while (index < tokens.length) {
      final token = tokens[index];

      if (token != multiply && token != divide) {
        stack.add(token);
        index += 1;
        continue;
      }

      if (stack.isEmpty || index + 1 >= tokens.length) return null;

      final left = int.tryParse(stack.removeLast());
      final right = int.tryParse(tokens[index + 1]);
      if (left == null || right == null) return null;

      int value;
      if (token == multiply) {
        value = left * right;
      } else {
        if (right == 0) return null;
        value = (left / right).round();
      }
      if (value.abs() > maxAmount) return null;

      stack.add('$value');
      index += 2;
    }

    return stack;
  }

  /// Sisa penjumlahan dan pengurangan, dikerjakan dari kiri ke kanan.
  static int? _collapseSums(List<String> tokens, int maxAmount) {
    final first = int.tryParse(tokens.first);
    if (first == null) return null;

    // Angka tunggal tanpa operator tidak melewati loop di bawah, jadi batasnya
    // diperiksa di sini juga. Tanpa ini `1000000000000` lolos apa adanya.
    if (first.abs() > maxAmount) return null;

    var total = first;
    var index = 1;

    while (index < tokens.length) {
      if (index + 1 >= tokens.length) return null;
      final operator = tokens[index];
      final value = int.tryParse(tokens[index + 1]);
      if (value == null) return null;

      total = operator == '+' ? total + value : total - value;
      if (total.abs() > maxAmount) return null;
      index += 2;
    }

    return total;
  }
}
