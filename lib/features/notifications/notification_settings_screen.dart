import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../data/notification_access.dart';
import '../../data/providers.dart';
import '../../domain/notification_draft.dart';
import '../../domain/notification_source.dart';
import '../../domain/wallet_balance.dart';
import '../transactions/wallet_picker_sheet.dart';
import 'notification_inbox_screen.dart';

/// Pengaturan akses notifikasi Android dan pemetaan aplikasi ke rekening.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationAccessProvider);
      // Antrean yang tertinggal saat mesin latar tidak tersedia ikut disedot
      // begitu pengguna kembali ke aplikasi.
      ref.read(notificationInboxSyncProvider).sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(notificationAccessProvider);
    final mappings = ref.watch(notificationMappingsProvider).value ?? const [];
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];
    final pendingCount = ref.watch(pendingNotificationCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi Otomatis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          access.when(
            loading: () => const _AccessCard.loading(),
            error: (error, _) => _AccessCard(
              granted: false,
              connected: false,
              error: '$error',
              onOpenSettings: _openAndroidSettings,
            ),
            data: (status) => _AccessCard(
              granted: status.granted,
              connected: status.connected,
              onOpenSettings: _openAndroidSettings,
            ),
          ),
          const SizedBox(height: 12),
          _BackgroundSurvivalCard(
            onOpenBattery: _openBatterySettings,
            onOpenAppInfo: _openAppInfoSettings,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(pendingCount > 99 ? '99+' : '$pendingCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            title: const Text('Inbox Notifikasi'),
            subtitle: Text(
              pendingCount == 0
                  ? 'Tidak ada draft yang menunggu'
                  : '$pendingCount draft menunggu konfirmasi',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const NotificationInboxScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          Text(
            'Hubungkan Rekening',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih rekening Spendly untuk setiap aplikasi. Notifikasi dari '
            'aplikasi itu akan langsung memakai rekening tersebut.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final source in NotificationSource.values)
            _SourceTile(
              source: source,
              mapping: _mappingFor(source, mappings),
              wallets: wallets,
              onPick: () => _pickMapping(source, mappings),
              onClear: () => _clearMapping(source),
            ),
          const SizedBox(height: 24),
          Text(
            'Spendly hanya membaca notifikasi dari aplikasi di atas, tanpa '
            'mengirim teksnya ke server. Nominal dan arah uang dibaca luring '
            'oleh aturan di perangkat.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _openAndroidSettings() async {
    await const NotificationAccess().openSettings();
    if (!mounted) return;
    ref.invalidate(notificationAccessProvider);
  }

  Future<void> _openBatterySettings() async {
    await const NotificationAccess().openBatterySettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pilih Spendly lalu izinkan aktivitas latar belakang.'),
      ),
    );
  }

  Future<void> _openAppInfoSettings() async {
    await const NotificationAccess().openAppSettings();
  }

  AccountNotificationMapping? _mappingFor(
    NotificationSource source,
    List<AccountNotificationMapping> mappings,
  ) {
    for (final mapping in mappings) {
      if (source.packages.contains(mapping.packageName)) return mapping;
    }
    return null;
  }

  Future<void> _pickMapping(
    NotificationSource source,
    List<AccountNotificationMapping> mappings,
  ) async {
    if (!mounted) return;
    final current = _mappingFor(source, mappings);
    final picked = await showWalletPicker(
      context,
      selectedId: current?.walletId,
      title: 'Rekening untuk ${source.appName}',
    );
    if (picked == null || !mounted) return;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      for (final packageName in source.packages) {
        await repository.setMapping(
          packageName: packageName,
          walletId: picked.id,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pemetaan: $error')),
      );
    }
  }

  Future<void> _clearMapping(NotificationSource source) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      for (final packageName in source.packages) {
        await repository.clearMapping(packageName);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pemetaan: $error')),
      );
    }
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.granted,
    required this.connected,
    required this.onOpenSettings,
    this.error,
  });

  const _AccessCard.loading()
    : granted = false,
      connected = false,
      onOpenSettings = null,
      error = null;

  final bool granted;
  final bool connected;
  final VoidCallback? onOpenSettings;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = granted && connected;
    final title = active
        ? 'Akses notifikasi aktif'
        : 'Akses notifikasi belum aktif';
    final subtitle = error != null
        ? 'Status tidak dapat dibaca: $error'
        : granted && !connected
        ? 'Izin sudah diberikan, tetapi layanan belum terhubung. '
              'Coba buka pengaturan lalu kembali.'
        : active
        ? 'Spendly dapat membaca notifikasi dari aplikasi yang '
              'didukung.'
        : 'Aktifkan Spendly di pengaturan akses notifikasi Android.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: active ? AppPalette.positive : AppPalette.moneyOut,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodySmall),
            if (!active) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka Pengaturan Android'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackgroundSurvivalCard extends StatelessWidget {
  const _BackgroundSurvivalCard({
    required this.onOpenBattery,
    required this.onOpenAppInfo,
  });

  final VoidCallback onOpenBattery;
  final VoidCallback onOpenAppInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.battery_saver_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Agar tetap berjalan saat aplikasi ditutup',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Android bisa menghentikan layanan latar untuk menghemat '
              'baterai. Izinkan Spendly berjalan di latar belakang dan, bila '
              'ada, nyalakan "Mulai otomatis" di Info Aplikasi.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenBattery,
                  icon: const Icon(Icons.battery_charging_full, size: 18),
                  label: const Text('Optimasi baterai'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenAppInfo,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Info aplikasi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Xiaomi/MIUI: Pengaturan › Aplikasi › Spendly › Mulai otomatis. '
              'Oppo/Realme: Pengaturan › Baterai › Optimasi aplikasi. '
              'Samsung: Pengaturan › Baterai › Batas penggunaan latar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.mapping,
    required this.wallets,
    required this.onPick,
    required this.onClear,
  });

  final NotificationSource source;
  final AccountNotificationMapping? mapping;
  final List<WalletBalance> wallets;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.chart[source.index % AppPalette.chart.length];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          source.index < 3 ? Icons.account_balance : Icons.phone_android,
          color: AppPalette.onAccent,
          size: 20,
        ),
      ),
      title: Text(source.appName),
      subtitle: Text(
        mapping == null ? 'Belum terhubung' : mapping!.walletName,
        style: TextStyle(
          color: mapping == null
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mapping != null)
            IconButton(
              tooltip: 'Lepas pemetaan',
              icon: const Icon(Icons.link_off),
              onPressed: onClear,
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: wallets.isEmpty ? null : onPick,
    );
  }
}
