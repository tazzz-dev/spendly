import 'debt_direction.dart';

/// Arah **pokok** sebuah catatan yang punya target.
///
/// Ini berbeda dari [DebtDirection]: [DebtDirection] menentukan tanda satu
/// entri, sedangkan [DebtTargetDirection] menentukan siapa yang berutang pada
/// catatan itu. Pembayaran selalu bergerak ke arah sebaliknya:
///
/// - `owe` (saya berutang) → pembayaran adalah entri **Memberi** (negatif);
/// - `owed` (orang berutang ke saya) → pembayaran adalah entri **Menerima**
///   (positif).
///
/// Murni: tanpa Flutter, tanpa drift. Lihat USULAN-HUTANG-TARGET §4.1.
enum DebtTargetDirection {
  owe('owe', 'Saya berutang', DebtDirection.give),
  owed('owed', 'Orang berutang ke saya', DebtDirection.receive);

  const DebtTargetDirection(
    this.storageValue,
    this.label,
    this.paymentDirection,
  );

  /// Nilai yang disimpan di `debts.target_direction`.
  final String storageValue;

  /// Sebutan di form target.
  final String label;

  /// Arah tanda entri pembayaran untuk target ini.
  final DebtDirection paymentDirection;

  /// Membaca nilai dari basis data. Nilai asing dianggap null supaya data lama
  /// yang belum bertarget tetap aman.
  static DebtTargetDirection? fromStorage(String? value) {
    for (final direction in values) {
      if (direction.storageValue == value) return direction;
    }
    return null;
  }
}
