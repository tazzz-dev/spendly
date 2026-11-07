import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../domain/app_preferences.dart';
import '../../domain/theme_choice.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_inbox_button.dart';
import '../notifications/notification_settings_screen.dart';
import 'sync_screen.dart';
import '../transactions/sepran_import_screen.dart';
import '../transactions/sepran_json_import_screen.dart';
import 'reminder_scheduler.dart';
import 'settings_localizations.dart';

/// Halaman Pengaturan. SPEC §5.12 dan ST-1: delapan butir Sepran, ditambah satu
/// butir **Impor dari Sepran** (SPEC X-6) yang tidak ada di Sepran.
///
/// Sejak tab Pengaturan diganti tab Scan AI, halaman ini dibuka lewat ikon
/// gerigi di kiri atas tiap tab. Karena itu ia membawa `Scaffold` sendiri.
///
/// Butir yang modul di belakangnya belum dibangun (pembelian, backup) tetap
/// tampil di daftar supaya urutan layar sesuai Sepran; menekannya hanya
/// memberitahu bahwa fiturnya belum hadir. Lihat SPEC O-9 dan B-9.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membungkus diri dengan lokalisasi bahasa pilihan. SPEC ST-5 dan G-7.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: const [NotificationInboxButton()],
      ),
      body: const SettingsLocalizations(child: _SettingsBody()),
    );
  }
}

/// Isi tab Setting yang sudah berada di dalam lokalisasi.
class _SettingsBody extends ConsumerWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.settingsLoadFailed('$error')),
        ),
      ),
      data: (prefs) => _SettingsList(prefs: prefs),
    );
  }
}

/// Daftar setelan. Delapan butir, urutannya SPEC §5.12.
class _SettingsList extends ConsumerStatefulWidget {
  const _SettingsList({required this.prefs});

  final AppPreferences prefs;

  @override
  ConsumerState<_SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends ConsumerState<_SettingsList> {
  @override
  void initState() {
    super.initState();
    // Selaraskan jadwal pengingat begitu layar ini tampil, supaya setelan yang
    // tersimpan dan jadwal di sistem tidak pernah berbeda (SPEC ST-6).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyReminder(widget.prefs);
    });
  }

  @override
  void didUpdateWidget(_SettingsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final before = oldWidget.prefs;
    final after = widget.prefs;
    final changed =
        before.reminderEnabled != after.reminderEnabled ||
        before.reminderTime != after.reminderTime ||
        before.language != after.language;
    if (changed) _applyReminder(after);
  }

  /// Menyampaikan setelan pengingat ke penjadwal notifikasi sistem.
  Future<void> _applyReminder(AppPreferences prefs) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    final granted = await ref
        .read(reminderSchedulerProvider)
        .sync(
          enabled: prefs.reminderEnabled,
          clock: ReminderClock.parseOrDefault(prefs.reminderTime),
          title: l10n.settingsReminder,
          body: l10n.settingsReminderSubtitle,
        );
    if (granted || !mounted) return;

    // Izin ditolak: kembalikan sakelar ke mati supaya layar tidak berbohong.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsReminderPermissionDenied)),
    );
    await ref.read(settingsProvider.notifier).setReminderEnabled(false);
  }

  /// Memilih sumber impor: Excel (lama) atau JSON dari HP (X-12).
  ///
  /// Impor Excel dipertahankan apa adanya. JSON ditawarkan sebagai pilihan
  /// terpisah karena berkasnya juga membawa saldo tiap rekening.
  Future<void> _pickImportSource(BuildContext context) async {
    final navigator = Navigator.of(context);
    final target = await showModalBottomSheet<Widget>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Excel (.xlsx)'),
              subtitle: const Text('Ekspor Sepran: transaksi saja'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(const SepranImportScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.data_object_outlined),
              title: const Text('JSON (.json)'),
              subtitle: const Text(
                'Dari HP Sepran: transaksi dan saldo tiap rekening',
              ),
              onTap: () =>
                  Navigator.of(sheetContext)
                      .pop(const SepranJsonImportScreen()),
            ),
          ],
        ),
      ),
    );

    if (target == null) return;
    await navigator.push<void>(MaterialPageRoute(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    return ListView(
      children: [
        ListTile(
          // SPEC O-7. Aktif setelah modul pembelian dibangun.
          leading: const Icon(Icons.restore),
          title: Text(l10n.settingsRestorePurchase),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _notAvailableYet(context),
        ),
        ListTile(
          // SPEC O-5. Aktif setelah modul iklan dan Pro dibangun (SPEC O-9:
          // keduanya dilewati di versi pertama).
          leading: const Icon(Icons.block),
          title: Text(l10n.settingsRemoveAds),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _notAvailableYet(context),
        ),
        SwitchListTile(
          // SPEC ST-3 dan G-2: sakelar, aktif secara bawaan.
          secondary: const Icon(Icons.calculate_outlined),
          title: Text(l10n.settingsShowDecimals),
          subtitle: Text(l10n.settingsShowDecimalsExample(money.rupiah(10000))),
          value: prefs.showDecimals,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).setShowDecimals(value),
        ),
        ListTile(
          // SPEC B-9: backup pertama kita nanti lokal ke berkas.
          leading: const Icon(Icons.backup_outlined),
          title: Text(l10n.settingsBackupRestore),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _notAvailableYet(context),
        ),
        ListTile(
          // SPEC X-6 dan X-12. Menyalin data Sepran sekali jalan — bukan
          // tautan. Dua sumber berkas: Excel (transaksi saja) dan JSON (dari
          // HP, lengkap dengan saldo tiap rekening).
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Impor dari Sepran'),
          subtitle: const Text(
            'Salin dari berkas Excel (.xlsx) atau JSON (.json)',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickImportSource(context),
        ),
        ListTile(
          key: const Key('open_sync_settings'),
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Sinkronisasi & Akun'),
          subtitle: const Text('Opsional: cadangkan ke cloud dan buka di web'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const SyncScreen())),
        ),
        ListTile(
          // Auto-Capture Notifikasi: izin akses Android dan pemetaan rekening.
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Notifikasi Otomatis'),
          subtitle: const Text(
            'Inbox transaksi dari notifikasi bank dan dompet digital',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen(),
            ),
          ),
        ),
        ListTile(
          // SPEC B-7.
          leading: const Icon(Icons.delete_forever_outlined),
          title: Text(l10n.settingsDeleteAll),
          onTap: () => _confirmDeleteAll(context, ref),
        ),
        SwitchListTile(
          // SPEC ST-6: aktifkan pengingat, lalu pilih jamnya lewat baris
          // "Kapan" di bawah.
          secondary: const Icon(Icons.alarm_outlined),
          title: Text(l10n.settingsReminder),
          subtitle: Text(l10n.settingsReminderSubtitle),
          value: prefs.reminderEnabled,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).setReminderEnabled(value),
        ),
        if (prefs.reminderEnabled)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.settingsReminderWhen),
            subtitle: Text(prefs.reminderTime),
            contentPadding: const EdgeInsets.only(left: 24, right: 16),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickReminderTime(context, ref),
          ),
        ListTile(
          // SPEC ST-4.
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.settingsTheme),
          subtitle: Text(_themeLabel(l10n, prefs.theme)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickTheme(context, ref),
        ),
        ListTile(
          // SPEC ST-5 dan G-7.
          leading: const Icon(Icons.translate_outlined),
          title: Text(l10n.settingsLanguage),
          subtitle: Text(prefs.language.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickLanguage(context, ref),
        ),
        // Ruang agar baris terakhir tidak menempel bilah navigasi.
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Nama tema yang tampil, dari berkas bahasa. SPEC G-6 dan G-7.
String _themeLabel(AppLocalizations l10n, AppTheme theme) => switch (theme) {
  AppTheme.blue => l10n.themeBlue,
  AppTheme.pink => l10n.themePink,
  AppTheme.purple => l10n.themePurple,
  AppTheme.dark => l10n.themeDark,
};

/// Catatan bahwa modul di belakangnya belum dibangun.
void _notAvailableYet(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).settingsUnavailable)),
  );
}

/// SPEC ST-6: memilih jam pengingat ("Kapan").
Future<void> _pickReminderTime(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(settingsProvider).value ?? const AppPreferences();
  final clock = ReminderClock.parseOrDefault(prefs.reminderTime);
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: clock.hour, minute: clock.minute),
  );
  if (picked == null || !context.mounted) return;

  await ref
      .read(settingsProvider.notifier)
      .setReminderTime(ReminderClock(picked.hour, picked.minute).text);
}

/// SPEC ST-4: memilih satu dari empat tema berwarna.
Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(settingsProvider).value ?? const AppPreferences();
  final l10n = AppLocalizations.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10n.settingsTheme),
      children: [
        for (final theme in AppTheme.values)
          _ChoiceTile(
            selected: prefs.theme == theme,
            title: _themeLabel(l10n, theme),
            color: appThemeSpecs[theme]!.seed,
            onTap: () {
              ref.read(themeProvider.notifier).select(theme);
              Navigator.of(dialogContext).pop();
            },
          ),
      ],
    ),
  );
}

/// SPEC ST-5: memilih bahasa.
Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(settingsProvider).value ?? const AppPreferences();
  final l10n = AppLocalizations.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10n.settingsLanguage),
      children: [
        for (final language in AppLanguage.values)
          _ChoiceTile(
            selected: prefs.language == language,
            title: language.label,
            onTap: () {
              ref.read(settingsProvider.notifier).setLanguage(language);
              Navigator.of(dialogContext).pop();
            },
          ),
      ],
    ),
  );
}

/// Satu baris pilihan di dialog. Dibuat sendiri alih-alih `RadioListTile`:
/// cukup tanda milih di ujung, tanpa widget yang sedang menua.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.title,
    required this.onTap,
    this.color,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: color == null
          ? null
          : Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
      title: Text(title),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
      onTap: onTap,
    );
  }
}

/// SPEC B-7: konfirmasi tegas sebelum mengosongkan basis data.
Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.settingsDeleteAll),
      content: Text(l10n.settingsDeleteAllBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.settingsCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.settingsDelete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  await ref.read(settingsRepositoryProvider).clearAllData();
  messenger.showSnackBar(SnackBar(content: Text(l10n.settingsDeleteAllDone)));
}
