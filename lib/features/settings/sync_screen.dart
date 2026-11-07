import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/dates.dart';
import '../../data/sync/sync_config.dart';
import '../../data/sync/sync_providers.dart';
import '../../data/sync/sync_service.dart';

/// Halaman **Sinkronisasi & Akun**.
///
/// Satu-satunya pintu masuk fitur cloud. Sebelum halaman ini dibuka, plugin
/// Supabase belum dimuat sama sekali; pengguna yang mencatat secara lokal tidak
/// membayar biaya cold start untuk fitur yang tidak dipakainya.
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sinkronisasi & Akun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LocalFirstCard(),
          const SizedBox(height: 12),
          if (!SyncConfig.isConfigured)
            const _NotConfiguredCard()
          else ...[
            if (_busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            session.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorCard(
                message: '$error',
                onRetry: () => ref.invalidate(authSessionProvider),
              ),
              data: (user) => user == null
                  ? _SignedOutView(
                      busy: _busy,
                      onSignIn: () => _run(() async {
                        await ref.read(syncActionsProvider).signInWithGoogle();
                        // Sesi datang lewat stream; tidak ada hasil sinkron di
                        // sini.
                        return null;
                      }, success: 'Halaman login Google dibuka.'),
                    )
                  : _SignedInView(
                      user: user,
                      busy: _busy,
                      onSync: () =>
                          _run(() => ref.read(syncActionsProvider).syncNow()),
                      onSignOut: _busy
                          ? null
                          : () => _run(() async {
                              await ref.read(syncActionsProvider).signOut();
                              return null;
                            }, success: 'Sudah keluar. Data lokal tetap ada.'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menjalankan satu tindakan sambil menampilkan status sibuk dan pesan hasil.
  ///
  /// Bila akun yang masuk berbeda dari akun yang terakhir dipakai, data lokal
  /// tidak digabung diam-diam: pengguna diminta memutuskan lebih dulu.
  Future<void> _run(
    Future<SyncOutcome?> Function() action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final outcome = await action();
      if (!mounted) return;
      if (outcome != null) {
        _showMessage(
          'Sinkronisasi selesai: ${outcome.pushed} baris dikirim, '
          '${outcome.pulled} baris diperbarui.',
        );
      } else if (success != null) {
        _showMessage(success);
      }
    } on SyncAccountMismatch {
      if (!mounted) return;
      final adopt = await _confirmAdoptAccount();
      if (adopt == true && mounted) {
        try {
          final outcome = await ref
              .read(syncActionsProvider)
              .adoptAccountAndSync();
          if (!mounted) return;
          _showMessage(
            'Data lokal digabungkan: ${outcome.pushed} baris dikirim, '
            '${outcome.pulled} baris diperbarui.',
          );
        } catch (error) {
          if (mounted) _showMessage(_readableError(error), isError: true);
        }
      }
    } catch (error) {
      if (mounted) _showMessage(_readableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmAdoptAccount() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akun berbeda'),
        content: const Text(
          'Basis data di perangkat ini terakhir disinkronkan dengan akun '
          'Google lain. Data lokal tidak dihapus.\n\n'
          'Pilih "Pakai akun ini" untuk menggabungkan seluruh data lokal ke '
          'akun yang sekarang. Bila tidak yakin, keluar lalu masuk dengan akun '
          'sebelumnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('sync_adopt_account'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pakai akun ini'),
          ),
        ],
      ),
    );
  }

  String _readableError(Object error) {
    if (error is SyncException) return error.message;
    if (error is AuthException) return 'Login gagal: ${error.message}';
    return 'Terjadi kesalahan: $error';
  }

  void _showMessage(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }
}

class _LocalFirstCard extends StatelessWidget {
  const _LocalFirstCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokal tetap yang utama',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pencatatan berjalan penuh tanpa akun. Login Google hanya '
              'menambahkan salinan cloud supaya data yang sama bisa dibuka di '
              'perangkat lain atau di versi web.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotConfiguredCard extends StatelessWidget {
  const _NotConfiguredCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Belum aktif di build ini',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(SyncConfig.missingConfigHint),
            const SizedBox(height: 12),
            Text(
              'Aplikasi tetap bisa dipakai seperti biasa. Tidak ada data yang '
              'dikirim ke mana pun.',
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

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.busy, required this.onSignIn});

  final bool busy;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Masuk untuk menyinkronkan',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan akun Google yang sama di ponsel dan di web. Data yang '
              'sudah ada di perangkat ini akan diunggah pada sinkronisasi '
              'pertama.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('sync_sign_in'),
              onPressed: busy ? null : onSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Masuk dengan Google'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Di web, halaman login terbuka di tab ini dan kembali ke '
                        'alamat aplikasi setelah selesai.'
                  : 'Di ponsel, login dibuka di peramban lalu kembali ke '
                        'aplikasi secara otomatis.',
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

class _SignedInView extends ConsumerWidget {
  const _SignedInView({
    required this.user,
    required this.busy,
    required this.onSync,
    required this.onSignOut,
  });

  final User user;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastSync = ref.watch(lastSyncProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_circle)),
            title: Text(user.email ?? 'Akun Google'),
            subtitle: Text(
              user.email == null ? 'ID ${user.id}' : 'Tersambung ke Supabase',
            ),
            trailing: TextButton(
              key: const Key('sync_sign_out'),
              onPressed: onSignOut,
              child: const Text('Keluar'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sinkronisasi dua arah',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Perubahan terbaru menang. Baris yang dihapus di satu '
                  'perangkat juga dihapus di perangkat lain.',
                ),
                const SizedBox(height: 12),
                lastSync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) =>
                      const Text('Waktu sinkronisasi belum dibaca.'),
                  data: (at) => Text(
                    at == null
                        ? 'Belum pernah disinkronkan dari perangkat ini.'
                        : 'Terakhir: ${AppDate.readable(AppDate.key(at))} '
                              '${AppDate.timeKey(at)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('sync_now'),
                  onPressed: busy ? null : onSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sinkronkan sekarang'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Catatan: sinkronisasi memakai jam perangkat. Pastikan tanggal '
              'dan jam ponsel benar agar perubahan terbaru tidak kalah oleh '
              'perubahan lama.',
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sinkronisasi tidak dapat disiapkan',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
