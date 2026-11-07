import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/notification_draft.dart';
import '../../domain/notification_source.dart';
import '../transactions/tx_visuals.dart';
import 'notification_review_screen.dart';
import 'notification_settings_screen.dart';

/// Daftar notifikasi yang sudah lolos parser dan menunggu konfirmasi.
class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(pendingNotificationDraftsProvider);
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox Notifikasi'),
        actions: [
          IconButton(
            key: const Key('notification_inbox_refresh'),
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(context, ref),
          ),
          IconButton(
            tooltip: 'Pengaturan notifikasi',
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: drafts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal membaca inbox: $error'),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? const _EmptyInbox()
              : ListView.separated(
                  // Supaya tarik-untuk-menyegarkan tetap bekerja ketika isi
                  // daftar lebih pendek dari layar.
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _DraftTile(draft: list[index], money: money),
                ),
        ),
      ),
    );
  }

  /// Menyedot antrean native lalu memaksa daftar dan badge membaca ulang.
  ///
  /// Dua langkah itu perlu: mesin Flutter latar menulis ke basis data yang
  /// sama, tetapi stream drift di mesin utama tidak otomatis mendapat kabar
  /// dari isolate lain.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationInboxSyncProvider).sync();
      ref.invalidate(pendingNotificationCountProvider);
      ref.invalidate(pendingNotificationDraftsProvider);
      // Beri kesempatan query baru menyelesaikan putaran pertamanya.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      messenger.showSnackBar(
        const SnackBar(content: Text('Inbox dimuat ulang')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal memuat ulang: $error')),
      );
    }
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListView, bukan Center: RefreshIndicator butuh anak yang bisa digulir.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.notifications_none_outlined,
          size: 56,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada notifikasi transaksi',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Aktifkan akses notifikasi dan hubungkan rekening agar '
          'pembayaran dari aplikasi bank atau dompet digital muncul di '
          'sini untuk dikonfirmasi. Tarik ke bawah untuk memuat ulang.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.link_outlined),
            label: const Text('Hubungkan notifikasi'),
          ),
        ),
      ],
    );
  }
}

class _DraftTile extends ConsumerWidget {
  const _DraftTile({required this.draft, required this.money});

  final NotificationDraft draft;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final source = draft.source;
    final color = _sourceColor(source);
    final sign = draft.type == NotificationDraftType.income ? '+' : '-';
    final preview = draft.rawMessage.trim().isEmpty
        ? draft.rawTitle
        : draft.rawMessage.trim();
    final time = draft.time == null ? '' : ' • ${draft.time}';

    return Dismissible(
      key: ValueKey('notification_${draft.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppPalette.moneyOut.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: AppPalette.moneyOut),
      ),
      confirmDismiss: (_) async {
        try {
          await ref.read(notificationRepositoryProvider).ignore(draft.id);
          return true;
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengabaikan draft: $error')),
            );
          }
          return false;
        }
      },
      child: ListTile(
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            draft.appName.isEmpty
                ? '?'
                : draft.appName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppPalette.onAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                draft.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${money.plain(draft.amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: draft.type == NotificationDraftType.income
                    ? txSummaryIncomeColor
                    : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${AppDate.readable(draft.date)}$time • ${draft.type.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => NotificationReviewScreen(draft: draft),
          ),
        ),
      ),
    );
  }

  Color _sourceColor(NotificationSource? source) {
    if (source == null) return AppPalette.neutral;
    return AppPalette.chart[source.index % AppPalette.chart.length];
  }
}
