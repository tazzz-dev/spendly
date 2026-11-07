import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/daily_summary.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/wallet_balance.dart';
import '../notifications/notification_inbox_button.dart';
import '../settings/settings_button.dart';
import 'add_transaction_menu.dart';
import 'export_dialog.dart';
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';
import 'transaction_history_screen.dart';
import 'transaction_visuals.dart';
import 'transfer_form_screen.dart';

/// Daftar transaksi satu hari, dengan ringkasan harian dan tombol tambah.
/// SPEC T-10 sampai T-14.
///
/// Sama seperti daftar rekening, layar ini memakai `Scaffold` sendiri supaya
/// tombol tambah bisa mengambang tepat di atas bilah navigasi kerangka.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  /// Kunci tanggal `YYYY-MM-DD`, bukan `DateTime`, supaya tidak ada pergeseran
  /// zona waktu. Lihat SPEC G-4.
  String _date = AppDate.today();

  /// Bila terisi, daftar hanya menampilkan transaksi milik dompet ini.
  String? _walletFilterId;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(dayTransactionsProvider(_date));
    final wallets =
        ref.watch(walletBalancesProvider).value ?? const <WalletBalance>[];
    // SPEC ST-3: ikut setelan "Tampilkan Angka Desimal", jangan dipatok.
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      // Dua ikon kanan atas, seperti Sepran: ekspor (SPEC X-1) dan riwayat
      // (SPEC F-1). Bilah judul dibuat di sini, bukan di kerangka, karena
      // hanya tab ini yang memerlukannya.
      appBar: AppBar(
        leading: const SettingsButton(),
        title: const Text('Transaksi'),
        actions: [
          const NotificationInboxButton(),
          IconButton(
            tooltip: 'Ekspor data',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => showExportDialog(context),
          ),
          IconButton(
            tooltip: 'Riwayat',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const TransactionHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _DayHeader(
            date: _date,
            onPrevious: () => _shiftDay(-1),
            onNext: () => _shiftDay(1),
            onPick: _pickDate,
          ),
          if (wallets.length > 1)
            _WalletFilterBar(
              wallets: wallets,
              selectedId: _walletFilterId,
              onSelected: (value) => setState(() => _walletFilterId = value),
            ),
          Expanded(
            child: entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal membaca transaksi: $error'),
                ),
              ),
              data: (rows) {
                final visible = _walletFilterId == null
                    ? rows
                    : rows
                          .where((entry) => entry.walletId == _walletFilterId)
                          .toList(growable: false);
                return _DayBody(
                  entries: visible,
                  money: money,
                  onTap: _openDetail,
                  emptyLabel: _walletFilterId == null
                      ? 'Belum ada transaksi'
                      : 'Tidak ada transaksi di dompet ini',
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMenu,
        tooltip: 'Tambah transaksi',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _shiftDay(int days) {
    setState(() => _date = AppDate.shift(_date, days));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDate.parseKey(_date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = AppDate.key(picked));
  }

  /// Menu `+` berisi **tiga** pilihan saja, dari atas: Pindah Saldo, Pemasukan,
  /// Pengeluaran. SPEC T-14, T-15, dan S-8. Koreksi Saldo tidak ada di sini;
  /// jenis itu dicapai dari halaman Rekening (SPEC T-15 dan K-6).
  Future<void> _openAddMenu() async {
    final choice = await showAddTransactionMenu(context);
    if (choice == null || !mounted) return;

    await switch (choice) {
      AddTransactionChoice.transfer => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TransferFormScreen(initialDate: _date),
        ),
      ),
      AddTransactionChoice.income => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TransactionFormScreen(
            mode: TxFormMode.income,
            initialDate: _date,
          ),
        ),
      ),
      AddTransactionChoice.expense => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TransactionFormScreen(
            mode: TxFormMode.expense,
            initialDate: _date,
          ),
        ),
      ),
    };
  }

  /// Menekan satu baris membuka **halaman detail**, bukan lembar aksi.
  ///
  /// Dari sana seluruh isi catatan terlihat, dan pengguna memilih mengubah
  /// (pensil), menyalin, atau menghapus (tempat sampah). SPEC T-5 dan T-7.
  Future<void> _openDetail(TransactionEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TransactionDetailScreen(entry: entry)),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // SPEC T-12: `<` dan `>` mengapit tanggal dan berfungsi pindah hari.
          IconButton(
            key: const Key('day_previous'),
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Hari sebelumnya',
          ),
          Expanded(
            child: TextButton.icon(
              key: const Key('day_pick'),
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today, size: 16),
              // SPEC T-12: kepala menampilkan hari, mis. `Min, 18 Okt 2026`.
              label: Text(AppDate.weekdayReadable(date)),
            ),
          ),
          IconButton(
            key: const Key('day_next'),
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Hari berikutnya',
          ),
        ],
      ),
    );
  }
}

class _WalletFilterBar extends StatelessWidget {
  const _WalletFilterBar({
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
  });

  final List<WalletBalance> wallets;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: const Key('wallet_filter_all'),
              label: const Text('Semua'),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final wallet in wallets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('wallet_filter_${wallet.id}'),
                label: Text(wallet.name),
                selected: selectedId == wallet.id,
                onSelected: (_) => onSelected(wallet.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayBody extends StatelessWidget {
  const _DayBody({
    required this.entries,
    required this.money,
    required this.onTap,
    this.emptyLabel = 'Belum ada transaksi',
  });

  final List<TransactionEntry> entries;
  final MoneyFormat money;
  final ValueChanged<TransactionEntry> onTap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final summary = DailySummary.of(entries);
    final theme = Theme.of(context);

    return ListView(
      children: [
        _SummaryCard(summary: summary, money: money),
        const Divider(height: 1),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(emptyLabel, style: theme.textTheme.bodyMedium),
            ),
          ),
        for (final entry in entries)
          _EntryTile(entry: entry, money: money, onTap: () => onTap(entry)),
        // Ruang agar baris terakhir tidak tertutup tombol tambah.
        const SizedBox(height: 88),
      ],
    );
  }
}

/// Kartu tiga kolom: Pemasukan, Pengeluaran, Selisih. SPEC T-12.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.money});

  final DailySummary summary;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _SummaryCell(
              label: 'Pemasukan',
              value: money.rupiah(summary.income),
              // SPEC T-12: kolom Pemasukan hijau, sama seperti Sepran.
              color: TxColors.positive,
            ),
            _SummaryCell(
              label: 'Pengeluaran',
              value: money.rupiah(summary.expense),
            ),
            _SummaryCell(
              label: 'Selisih',
              // SPEC T-17: tanpa tanda minus. Keputusannya ada di DailySummary.
              value: money.rupiah(summary.difference),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu baris transaksi.
///
/// SPEC T-11: kategori sebagai baris utama (tebal), judul sebagai baris kedua
/// (abu-abu). Pindah saldo dan koreksi saldo memakai sebutan jenisnya
/// menggantikan kategori, lihat `TransactionEntry.primaryLabel`.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
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
    final color = TxColors.of(entry.kind);
    // Nominal mengikuti Sepran: positif hijau, negatif ikut warna teks.
    final amountColor = TxColors.amountOf(entry.kind);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(TxColors.icon(entry.kind), color: color, size: 20),
      ),
      title: Text(
        entry.primaryLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: entry.secondaryLabel.isEmpty
          ? null
          : Text(
              entry.secondaryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            signedAmount(
              entry.kind,
              entry.magnitude,
              money.plain(entry.magnitude),
            ),
            style: theme.textTheme.titleSmall?.copyWith(color: amountColor),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
