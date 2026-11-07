import 'notification_source.dart';
import 'tx_kind.dart';

/// Arah uang yang terbaca dari notifikasi.
///
/// Nilai [storageValue] masuk ke kolom `notification_drafts.type`. Jangan ubah:
/// draft lama akan kehilangan artinya.
enum NotificationDraftType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  const NotificationDraftType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  /// Jenis transaksi Spendly yang setara. Notifikasi hanya boleh menjadi
  /// pemasukan atau pengeluaran; pindah saldo dan koreksi tidak pernah datang
  /// dari notifikasi bank.
  TxKind get txKind => switch (this) {
    NotificationDraftType.income => TxKind.income,
    NotificationDraftType.expense => TxKind.expense,
  };

  static NotificationDraftType fromStorage(String value) => values.firstWhere(
    (type) => type.storageValue == value,
    orElse: () =>
        throw ArgumentError('Jenis draft notifikasi tidak dikenal: "$value"'),
  );
}

/// Status pengolahan draft. Hanya draft [pending] yang tampil di inbox.
enum NotificationDraftStatus {
  pending('pending'),
  approved('approved'),
  ignored('ignored');

  const NotificationDraftStatus(this.storageValue);

  final String storageValue;

  static NotificationDraftStatus fromStorage(String value) => values.firstWhere(
    (status) => status.storageValue == value,
    orElse: () =>
        throw ArgumentError('Status draft notifikasi tidak dikenal: "$value"'),
  );
}

/// Satu notifikasi yang sudah menjadi draft, sudah dibaca dari Drift.
///
/// [amount] selalu positif. Arahnya ada di [type], dan tanda untuk transaksi
/// tetap ditentukan `Movement` saat draft disetujui.
class NotificationDraft {
  const NotificationDraft({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.rawTitle,
    required this.rawMessage,
    required this.amount,
    required this.type,
    required this.walletId,
    required this.occurredAt,
    required this.date,
    required this.time,
    required this.status,
    required this.sourceKey,
    required this.approvedTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String packageName;
  final String appName;
  final String rawTitle;
  final String rawMessage;

  /// Nominal positif, rupiah utuh.
  final int amount;

  final NotificationDraftType type;

  /// Rekening hasil pemetaan paket aplikasi, atau null bila belum dipetakan.
  final String? walletId;

  /// Waktu notifikasi muncul di Android, epoch milidetik.
  final int occurredAt;

  /// Tanggal lokal `YYYY-MM-DD`.
  final String date;

  /// Jam lokal `HH:MM`, opsional.
  final String? time;

  final NotificationDraftStatus status;

  /// Kunci idempoten untuk mencegah satu notifikasi masuk dua kali.
  final String sourceKey;

  /// Terisi setelah draft disetujui dan transaksi lahir.
  final String? approvedTransactionId;

  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  NotificationSource? get source => NotificationSource.fromPackage(packageName);

  bool get isPending => status == NotificationDraftStatus.pending;
}

/// Hubungan satu paket aplikasi dengan satu rekening Spendly.
class AccountNotificationMapping {
  const AccountNotificationMapping({
    required this.id,
    required this.packageName,
    required this.walletId,
    required this.walletName,
  });

  final String id;
  final String packageName;
  final String walletId;
  final String walletName;

  NotificationSource? get source => NotificationSource.fromPackage(packageName);
}
