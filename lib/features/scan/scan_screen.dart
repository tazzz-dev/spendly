import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/mutation_source.dart';
import '../notifications/notification_inbox_button.dart';
import '../settings/settings_button.dart';
import 'scan_providers.dart';
import 'scan_review_screen.dart';

/// Tab **Scan AI**: membaca screenshot mutasi lalu menawarkan transaksi yang
/// bisa dikonfirmasi sekaligus.
///
/// Pemindaian hanya berjalan setelah pengguna memilih gambar. Model OCR tidak
/// dimuat saat aplikasi dibuka (lihat [ocrEngineProvider]).
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String _progress = '';
  int? _lastSaved;
  String _lastOcrText = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: const Text('Scan AI'),
        actions: const [NotificationInboxButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(supported: isScanSupported),
          const SizedBox(height: 16),
          if (!isScanSupported)
            _UnsupportedCard(theme: theme)
          else ...[
            FilledButton.icon(
              key: const Key('scan_pick_images'),
              onPressed: _busy ? null : () => _pick(camera: false),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pilih gambar dari galeri'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('scan_take_photo'),
              onPressed: _busy ? null : () => _pick(camera: true),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Ambil foto layar mutasi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(_progress, style: theme.textTheme.bodySmall),
          ],
          if (_lastSaved != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text('$_lastSaved transaksi tersimpan'),
                subtitle: const Text('Buka tab Transaksi untuk melihatnya.'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Cara kerjanya', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const _Step(
            number: '1',
            title: 'Pilih satu atau beberapa gambar',
            body:
                'Screenshot riwayat DANA, OVO, GoPay, atau m-banking. '
                'Satu gambar panjang berisi banyak transaksi juga bisa.',
          ),
          const _Step(
            number: '2',
            title: 'Teks dibaca di perangkat',
            body:
                'OCR lokal (Google ML Kit) membaca teks tanpa mengunggah '
                'gambar ke server mana pun.',
          ),
          const _Step(
            number: '3',
            title: 'Periksa sebelum menyimpan',
            body:
                'Nominal, tanggal, arah uang, kategori, dan dompet bisa '
                'diubah. Hanya baris yang dicentang yang disimpan.',
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hasil baca bergantung pada kejelasan gambar. Selalu '
                      'periksa nominal dan tanggal; jangan simpan sebelum '
                      'yakin.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick({required bool camera}) async {
    List<XFile> files;
    try {
      if (camera) {
        final photo = await _picker.pickImage(source: ImageSource.camera);
        files = photo == null ? const [] : [photo];
      } else {
        files = await _picker.pickMultiImage();
      }
    } catch (error) {
      _showError('Tidak dapat membuka gambar: $error');
      return;
    }
    if (files.isEmpty || !mounted) return;

    setState(() {
      _busy = true;
      _lastSaved = null;
      _progress = 'Membaca ${files.length} gambar...';
    });

    try {
      final engine = ref.read(ocrEngineProvider);
      final buffer = StringBuffer();
      for (var index = 0; index < files.length; index++) {
        if (!mounted) return;
        setState(
          () => _progress =
              'Membaca gambar ${index + 1} dari '
              '${files.length}...',
        );
        final text = await engine.recognizeFile(files[index].path);
        buffer.writeln(text);
      }

      final rawText = buffer.toString().trim();
      _lastOcrText = rawText;

      if (!mounted) return;
      if (rawText.isEmpty) {
        setState(() => _busy = false);
        _showError('Tidak ada teks yang terbaca dari gambar.');
        return;
      }

      setState(() => _progress = 'Mengurai transaksi...');
      final items = mutationParser.parse(rawText);

      if (!mounted) return;
      setState(() => _busy = false);

      if (items.isEmpty) {
        await _showNoTransactions();
        return;
      }

      final saved = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ScanReviewScreen(
            items: items,
            sourceCount: files.length,
            imagePaths: [for (final file in files) file.path],
            source: const MutationSourceDetector().detect(rawText),
          ),
        ),
      );
      if (!mounted) return;
      if (saved != null && saved > 0) {
        setState(() => _lastSaved = saved);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Gagal membaca gambar: $error');
    }
  }

  Future<void> _showNoTransactions() async {
    final openText = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Belum ada transaksi terbaca'),
        content: const Text(
          'Teks terbaca, tetapi polanya belum dikenali sebagai transaksi. '
          'Coba gambar yang lebih jelas atau potong bagian riwayatnya saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lihat teks'),
          ),
        ],
      ),
    );
    if (openText != true || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Teks hasil OCR',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(_lastOcrText),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.supported});

  final bool supported;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 36,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 12),
          Text(
            'Catat dari screenshot',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supported
                ? 'Unggah riwayat transaksi e-wallet atau m-banking, lalu '
                      'konfirmasi hasilnya. Tidak perlu mengetik satu per satu.'
                : 'Pemindaian gambar berjalan di aplikasi Android/iOS. '
                      'Versi web tetap bisa dipakai untuk mengelola data yang '
                      'sudah tersinkron.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedCard extends StatelessWidget {
  const _UnsupportedCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hanya di ponsel', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Mesin OCR lokal tidak tersedia di peramban. Buka Spendly di '
              'Android atau iOS untuk memindai gambar; hasilnya akan muncul '
              'di web setelah sinkronisasi.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              number,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
