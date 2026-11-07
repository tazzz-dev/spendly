import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/transaction_entry.dart';
import 'transaction_detail_screen.dart';

/// Halaman **Riwayat**: seluruh transaksi, dikelompokkan per hari.
/// SPEC §5.9 dan F-1 sampai F-4.
///
/// Sepran hanya mencari pada keterangan dan nama rekening (F-2, F-3). Kita
/// menambah judul dan kategori (F-4) karena murah dan sangat terasa.
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  static final DateFormat _dayNumber = DateFormat('d');
  static final DateFormat _monthYear = DateFormat('MM yyyy');
  static final DateFormat _weekday = DateFormat('EEEE', 'id_ID');

  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// Jumlah baris yang diminta. Dinaikkan bertahap, tidak sekaligus.
  int _limit = 200;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      historyTransactionsProvider(HistoryQuery(search: _query, limit: _limit)),
    );
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: Column(
        children: [
          _SearchBar(
            controller: _search,
            onChanged: (value) => setState(() {
              _query = value.trim();
              _limit = 200;
            }),
          ),
          Expanded(
            child: entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal membaca riwayat: $error'),
                ),
              ),
              data: (rows) => _buildList(rows, money),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TransactionEntry> rows, MoneyFormat money) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _query.isEmpty
                ? 'Belum ada transaksi'
                : 'Tidak ada hasil untuk "$_query"',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final children = <Widget>[];
    String? currentDate;

    // Jumlah per hari dihitung sekali, bukan diulang untuk setiap baris.
    final totals = <String, int>{};
    for (final entry in rows) {
      totals[entry.date] = (totals[entry.date] ?? 0) + entry.amount;
    }

    for (final entry in rows) {
      if (entry.date != currentDate) {
        currentDate = entry.date;
        children.add(
          _DayHeader(
            date: currentDate,
            total: totals[currentDate] ?? 0,
            money: money,
          ),
        );
      }
      children.add(
        _HistoryTile(
          entry: entry,
          money: money,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(entry: entry),
            ),
          ),
        ),
      );
    }

    // Bila jumlah baris mencapai batas, kemungkinan besar masih ada lagi.
    if (rows.length >= _limit) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: TextButton(
              key: const Key('history_load_more'),
              onPressed: () => setState(() => _limit += 200),
              child: const Text('Muat lebih banyak'),
            ),
          ),
        ),
      );
    }

    return ListView(children: [...children, const SizedBox(height: 24)]);
  }
}

/// Kolom pencarian di bawah bilah judul.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Pencarian',
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Kepala satu hari: angka tanggal besar, bulan-tahun dan nama hari kecil,
/// lalu jumlah hari itu di kanan.
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.total,
    required this.money,
  });

  final String date;
  final int total;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = AppDate.parseKey(date);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              _TransactionHistoryScreenState._dayNumber.format(parsed),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _TransactionHistoryScreenState._monthYear.format(parsed),
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _TransactionHistoryScreenState._weekday.format(parsed),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
          const Spacer(),
          Text(_signedAmount(total, money), style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Satu baris riwayat: kategori tebal, judul abu-abu, nominal, panah.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.money,
    required this.onTap,
  });

  final TransactionEntry entry;
  final MoneyFormat money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = entry.secondaryLabel;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.primaryLabel,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (secondary.isNotEmpty)
                    Text(
                      secondary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _signedAmount(entry.amount, money),
              style: theme.textTheme.bodyMedium,
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

String _signedAmount(int amount, MoneyFormat money) {
  final sign = amount < 0 ? '-' : '';
  return '$sign${money.plain(amount.abs())}';
}
