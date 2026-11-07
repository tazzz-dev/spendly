/// Notifikasi mentah yang dikirim lapisan Android ke Dart.
///
/// Sengaja hanya berisi teks dan waktu. Parsing, pemetaan rekening, dan
/// penulisan ke Drift seluruhnya terjadi di Dart supaya aturannya hanya ada di
/// satu tempat dan bisa diuji tanpa HP.
class CapturedNotification {
  const CapturedNotification({
    required this.id,
    required this.packageName,
    required this.title,
    required this.message,
    required this.postedAt,
  });

  /// ID antrean native. Dipakai untuk menghapus event setelah berhasil diolah.
  final String id;

  final String packageName;
  final String title;
  final String message;

  /// Waktu notifikasi muncul, epoch milidetik.
  final int postedAt;

  factory CapturedNotification.fromMap(Map<Object?, Object?> map) {
    return CapturedNotification(
      id: _text(map['id']),
      packageName: _text(map['packageName']),
      title: _text(map['title']),
      message: _text(map['message']),
      postedAt: _integer(map['postedAt']),
    );
  }

  /// Kunci idempoten. Notifikasi yang diposting ulang dengan teks dan waktu
  /// sama tidak boleh menjadi dua draft.
  String get sourceKey =>
      '$packageName|$postedAt|${title.trim()}|${message.trim()}';

  bool get isValid =>
      id.isNotEmpty &&
      packageName.isNotEmpty &&
      postedAt > 0 &&
      (title.trim().isNotEmpty || message.trim().isNotEmpty);

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static int _integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
