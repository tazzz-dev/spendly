import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/report_rules.dart';

/// Halaman "Konfigurasi Rekap". SPEC L-7 dan L-14.
///
/// Tepat dua setelan, tidak lebih: **Tanggal Mulai** (pilihan hari dalam bulan,
/// bawaan 1) dan **Saldo Akumulasi** (sakelar, bawaan mati), lalu tombol Simpan.
class ReportConfigScreen extends ConsumerStatefulWidget {
  const ReportConfigScreen({super.key});

  @override
  ConsumerState<ReportConfigScreen> createState() => _ReportConfigScreenState();
}

class _ReportConfigScreenState extends ConsumerState<ReportConfigScreen> {
  /// Nilai yang sedang dipilih. Null berarti masih mengikuti setelan tersimpan;
  /// diisi begitu pengguna mengubah sesuatu, supaya perubahan tidak tertimpa
  /// oleh aliran setelan.
  int? _startDay;
  bool? _accumulate;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(reportConfigProvider).value;

    if (stored == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konfigurasi Rekap')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final startDay = _startDay ?? stored.startDay;
    final accumulate = _accumulate ?? stored.accumulateBalance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi Rekap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tanggal Mulai', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Hari pertama siklus rekap. Nilai 1 berarti mengikuti awal bulan; '
            'nilai 25 berarti periode berjalan dari tanggal 25 sampai tanggal '
            '24 bulan berikutnya.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: startDay,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (
                var day = ReportRules.minStartDay;
                day <= ReportRules.maxStartDay;
                day++
              )
                DropdownMenuItem(value: day, child: Text('$day')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _startDay = value);
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Saldo Akumulasi'),
            subtitle: const Text(
              'Hitung Saldo Awal dari seluruh pergerakan sebelum rentang.',
            ),
            value: accumulate,
            onChanged: (value) => setState(() => _accumulate = value),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _save(
                        ReportConfig(
                          startDay: startDay,
                          accumulateBalance: accumulate,
                        ),
                      ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(ReportConfig config) async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(reportSettingsRepositoryProvider).save(config);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $error')),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Konfigurasi disimpan')),
    );
  }
}
