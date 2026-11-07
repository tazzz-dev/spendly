import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/debt_record.dart';
import '../../domain/debt_rules.dart';
import '../../domain/debt_totals.dart';
import 'debt_detail_screen.dart';
import 'debt_direction_menu.dart';
import 'debt_entry_form_screen.dart';
import 'debt_form_screen.dart';
import 'debt_providers.dart';
import 'debt_target_form_screen.dart';
import 'debt_visuals.dart';

/// Dua cara menyajikan data yang sama. H-16.
enum _DebtMode { normal, target }

/// Halaman Hutang: **Normal | Target**, dua total, kotak pencarian, lalu daftar.
/// SPEC H-1, H-3, H-5, H-8, dan H-16 sampai H-29.
///
/// Memakai `Scaffold` sendiri walau sudah berada di dalam kerangka lima tab:
/// hanya dengan begitu tombol tambah bisa mengambang tepat di atas bilah
/// navigasi. Bilah judul tetap milik kerangka.
class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// H-16: mode terakhir tidak perlu diingat lintas peluncuran, jadi cukup
  /// disimpan di state layar.
  _DebtMode _mode = _DebtMode.normal;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(debtRecordsProvider);
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal membaca data: $error'),
          ),
        ),
        data: (list) => Column(
          children: [
            _ModeSelector(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            Expanded(
              child: _mode == _DebtMode.normal
                  ? _NormalTab(
                      records: list,
                      query: _query,
                      money: money,
                      search: _search,
                      onSearch: (value) => setState(() => _query = value),
                      onTap: _openDetail,
                    )
                  : _TargetTab(
                      records: list,
                      query: _query,
                      money: money,
                      search: _search,
                      onSearch: (value) => setState(() => _query = value),
                      onTap: _openDetail,
                      onPay: _openPayment,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _mode == _DebtMode.normal
          ? FloatingActionButton(
              onPressed: _openAddMenu,
              tooltip: 'Tambah hutang',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: _openTargetForm,
              tooltip: 'Buat target baru',
              icon: const Icon(Icons.add),
              label: const Text('Target Baru'),
              // Tema memberi CircleBorder untuk FAB biasa; FAB meluas harus
              // kapsul supaya labelnya tidak terpotong.
              shape: const StadiumBorder(),
            ),
    );
  }

  /// SPEC H-2: tombol `+` di tab Normal lebih dulu menawarkan dua arah.
  Future<void> _openAddMenu() async {
    final direction = await showDebtDirectionMenu(context);
    if (direction == null || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => DebtFormScreen(direction: direction)),
    );
  }

  /// FAB tab Target langsung membuka form target (H-20/§6.3).
  Future<void> _openTargetForm() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const DebtTargetFormScreen()),
    );
  }

  Future<void> _openDetail(DebtRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => DebtDetailScreen(debtId: record.id)),
    );
  }

  /// H-21: pembayaran dari kartu Target memakai arah otomatis dan rekening
  /// wajib.
  Future<void> _openPayment(DebtRecord record) async {
    final direction = record.targetDirection;
    if (direction == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            DebtEntryFormScreen(debtId: record.id, targetDirection: direction),
      ),
    );
  }
}

/// Pemilih mode **Normal | Target**: bingkai biru tipis, pilihan aktif terisi
/// penuh. H-16.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final _DebtMode mode;
  final ValueChanged<_DebtMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            _ModeButton(
              key: const Key('debt-mode-normal'),
              label: 'Normal',
              selected: mode == _DebtMode.normal,
              onTap: () => onChanged(_DebtMode.normal),
            ),
            _ModeButton(
              key: const Key('debt-mode-target'),
              label: 'Target',
              selected: mode == _DebtMode.target,
              onTap: () => onChanged(_DebtMode.target),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- Normal

class _NormalTab extends StatelessWidget {
  const _NormalTab({
    required this.records,
    required this.query,
    required this.money,
    required this.search,
    required this.onSearch,
    required this.onTap,
  });

  final List<DebtRecord> records;
  final String query;
  final MoneyFormat money;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ValueChanged<DebtRecord> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dua total di kepala halaman dihitung dari seluruh catatan, bukan dari
        // hasil pencarian: keduanya menggambarkan posisi keseluruhan.
        _TotalsHeader(totals: DebtTotals.of(records), money: money),
        _SearchField(controller: search, onChanged: onSearch),
        const Divider(height: 1),
        Expanded(
          child: _RecordList(
            records: filterDebtRecords(records, query),
            hasAny: records.isNotEmpty,
            money: money,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

/// Kepala tab Normal: **Menerima** (hijau, bertanda `+`) dan **Memberi** (tanpa
/// tanda). Keduanya tidak pernah disatukan. SPEC H-1.
class _TotalsHeader extends StatelessWidget {
  const _TotalsHeader({required this.totals, required this.money});

  final DebtTotals totals;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('Menerima', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '+${money.plain(totals.receiving)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: debtTotalReceiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Memberi', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    money.plain(totals.giving),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.hasAny,
    required this.money,
    required this.onTap,
  });

  final List<DebtRecord> records;
  final bool hasAny;
  final MoneyFormat money;
  final ValueChanged<DebtRecord> onTap;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            hasAny
                ? 'Tidak ada catatan yang cocok'
                : 'Belum ada catatan hutang',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: records.length + 1,
      itemBuilder: (context, index) {
        if (index == records.length) {
          // Ruang agar baris terakhir tidak tertutup tombol tambah.
          return const SizedBox(height: 88);
        }
        return _RecordTile(
          record: records[index],
          money: money,
          onTap: () => onTap(records[index]),
        );
      },
    );
  }
}

/// Satu baris daftar Normal: nama (tebal), keterangan, dan nominal. SPEC H-5.
///
/// Keterangan kosong tertulis "Tanpa keterangan". Catatan bertarget diberi
/// badge kecil "Target" (H-19), tetapi nominalnya tetap `net` entri (H-4).
class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.money,
    required this.onTap,
  });

  final DebtRecord record;
  final MoneyFormat money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Row(
        children: [
          Flexible(
            child: Text(
              record.partyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (record.hasTarget) ...[
            const SizedBox(width: 8),
            _DebtBadge(
              key: Key('target-badge-${record.id}'),
              label: DebtRules.targetBadge,
            ),
          ],
        ],
      ),
      subtitle: Text(
        record.noteLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        debtRecordAmountText(money, record),
        style: theme.textTheme.titleSmall?.copyWith(
          color: debtRecordAmountColor(record),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ------------------------------------------------------------------- Target

class _TargetTab extends StatelessWidget {
  const _TargetTab({
    required this.records,
    required this.query,
    required this.money,
    required this.search,
    required this.onSearch,
    required this.onTap,
    required this.onPay,
  });

  final List<DebtRecord> records;
  final String query;
  final MoneyFormat money;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ValueChanged<DebtRecord> onTap;
  final ValueChanged<DebtRecord> onPay;

  @override
  Widget build(BuildContext context) {
    final targets = sortDebtTargets(records);
    final visible = filterDebtRecords(targets, query);

    return Column(
      children: [
        _TargetTotalsHeader(totals: DebtTargetTotals.of(targets), money: money),
        _SearchField(controller: search, onChanged: onSearch),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? _TargetEmpty(hasAny: targets.isNotEmpty)
              : ListView.builder(
                  itemCount: visible.length + 1,
                  itemBuilder: (context, index) {
                    if (index == visible.length) {
                      return const SizedBox(height: 96);
                    }
                    final record = visible[index];
                    return _TargetCard(
                      key: Key('target-card-${record.id}'),
                      record: record,
                      money: money,
                      onTap: () => onTap(record),
                      onPay: () => onPay(record),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Dua kartu total sisa yang terpisah dan tidak pernah dijumlahkan. H-20.
class _TargetTotalsHeader extends StatelessWidget {
  const _TargetTotalsHeader({required this.totals, required this.money});

  final DebtTargetTotals totals;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _TotalCard(
              key: const Key('target-total-owe'),
              label: 'Total sisa utang',
              value: money.rupiah(totals.owe),
              color: debtSummaryGiveColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TotalCard(
              key: const Key('target-total-owed'),
              label: 'Total sisa piutang',
              value: money.rupiah(totals.owed),
              color: debtSummaryReceiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu kartu target: nama, badge Lunas, terbayar/target, progress bar, sisa,
/// dan tombol Bayar. §6.3.
class _TargetCard extends StatelessWidget {
  const _TargetCard({
    super.key,
    required this.record,
    required this.money,
    required this.onTap,
    required this.onPay,
  });

  final DebtRecord record;
  final MoneyFormat money;
  final VoidCallback onTap;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = record.progress!;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.partyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (progress.isSettled) ...[
                    const SizedBox(width: 8),
                    const _DebtBadge(
                      label: DebtRules.settledStatus,
                      color: debtSummaryReceiveColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                debtTargetPaidText(money, progress),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      debtTargetStatusText(money, progress),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Bayar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetEmpty extends StatelessWidget {
  const _TargetEmpty({required this.hasAny});

  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasAny ? 'Tidak ada target yang cocok' : 'Belum ada target utang',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (!hasAny) ...[
              const SizedBox(height: 6),
              Text(
                'Tekan Target Baru untuk membuat target pertama.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Bersama

/// Badge kecil berlatar tipis untuk "Target" dan "Lunas".
class _DebtBadge extends StatelessWidget {
  const _DebtBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Kotak Pencarian dengan ikon mikrofon. SPEC H-8.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Pencarian',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            // SPEC H-8 menyebut pencarian dengan suara. Pengenalan suara belum
            // kita miliki (lihat laporan), jadi ikonnya ditampilkan apa adanya
            // dan menjelaskan keadaannya ketika ditekan.
            icon: const Icon(Icons.mic_none),
            tooltip: 'Pencarian dengan suara',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pencarian dengan suara belum tersedia'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
