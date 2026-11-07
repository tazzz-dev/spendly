import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'notification_inbox_screen.dart';

/// Ikon lonceng dengan badge jumlah draft notifikasi yang menunggu.
class NotificationInboxButton extends ConsumerWidget {
  const NotificationInboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingNotificationCountProvider).value ?? 0;

    return IconButton(
      tooltip: 'Inbox notifikasi',
      onPressed: () => openNotificationInbox(context),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

Future<void> openNotificationInbox(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
  );
}
