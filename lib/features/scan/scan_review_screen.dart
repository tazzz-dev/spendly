import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/category_guesser.dart';
import '../../domain/duplicate_transaction_finder.dart';
import '../../domain/movement.dart';
import '../../domain/mutation_source.dart';
import '../../domain/scanned_transaction.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/tx_kind.dart';
import '../../domain/tx_rules.dart';
import '../../domain/wallet_balance.dart';
import '../transactions/suggestion_chips.dart';
import '../wallets/wallet_visuals.dart';

/// Layar tinjauan hasil Scan AI.
///
/// Pengguna dapat mencentang baris, mengubah nominal, judul, kategori, tanggal,
/// arah uang, dan dompet **sebelum** apa pun ditulis ke basis data. Tidak ada
/// transaksi yang tersimpan otomatis.
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.items,
    this.sourceCount = 1,
    this.imagePaths = const [],
    this.source,
  });

  final List<ScannedTransaction> items;

  /// Jumlah gambar yang dibaca, hanya untuk teks ringkasan.
  final int sourceCount;

  /// Berkas gambar yang dipakai, untuk tombol "Lihat foto sumber". Boleh kosong
  /// (mis. saat layar dibuka langsung dari pengujian).
  final List<String> imagePaths;

  /// Sumber mutasi yang sudah dideteksi dari teks OCR. Bila null, layar ini
  /// mencoba mendeteksi sendiri dari teks mentah tiap baris.
  final MutationSource? source;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late final List<_ReviewRow> _rows;
  late final MutationSource? _source;
  List<TransactionEntry> _existing = const [];
  bool _checkingDuplicates = true;
  bool _duplicateCheckFailed = false;
  String? _duplicateWalletId;
  String? _walletId;
  bool _saving = false;
  bool _walletMissing = false;

  @override
  void initState() {
    super.initState();
    _rows = [for (final item in widget.items) _ReviewRow(item)];
    _source =
        widget.source ??
        const MutationSourceDetector().detect(
          widget.items.map((item) => item.rawText).join('\n'),
        );
    _loadExistingTransactions();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Membaca transaksi yang sudah tercatat pada rentang tanggal hasil scan,
  /// lalu menandai baris yang kemungkinan besar sudah ada.
  Future<void> _loadExistingTransactions() async {
    if (_rows.isEmpty) {
      if (mounted) setState(() => _checkingDuplicates = false);
      return;
    }

    final dates = _rows.map((row) => row.item.date).toList()..sort();
    try {
      final entries = await ref
          .read(transactionRepositoryProvider)
          .readRange(from: dates.first, until: dates.last);
      if (!mounted) return;
      setState(() {
        _existing = entries;
        _checkingDuplicates = false;
        _applyDuplicates(initial: true);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingDuplicates = false;
        _duplicateCheckFailed = true;
      });
    }
  }

  /// Menandai baris yang cocok dengan transaksi lama. Baris yang baru menjadi
  /// duplikat otomatis dilepas centangnya, kecuali pengguna sudah menyentuh
  /// centang baris itu sendiri.
  void _applyDuplicates({bool initial = false}) {
    final scope = _duplicateWalletId;
    final matches = const DuplicateTransactionFinder().find(
      scanned: [for (final row in _rows) row.current],
      existing: _existing,
      walletByScanId: {
        for (final row in _rows) row.item.id: row.walletId ?? scope,
      },
    );

    for (final row in _rows) {
      final match = matches[row.item.id];
      final wasDuplicate = row.duplicate != null;
      row.duplicate = match;
      if (row.selectionTouched) continue;
      if (match != null) {
        row.selected = false;
      } else if (!initial && wasDuplicate) {
        row.selected = true;
      }
    }
  }

  void _onRowChanged() {
    setState(_applyDuplicates);
  }

  List<_ReviewRow> get _selected =>
      _rows.where((row) => row.selected).toList(growable: false);

  /// Arah yang sama untuk semua baris, atau null bila masih campuran.
  ScannedTransactionType? get _uniformDirection {
    if (_rows.isEmpty) return null;
    final first = _rows.first.item.type;
    return _rows.every((row) => row.item.type == first) ? first : null;
  }

  void _setBulkDirection(ScannedTransactionType type) {
    setState(() {
      for (final row in _rows) {
        row.item = row.item.copyWith(type: type);
      }
      _applyDuplicates();
    });
  }

  int get _selectedTotal => _selected.fold(
    0,
    (sum, row) => sum + (MoneyInput.tryParse(row.amount.text) ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];
    final theme = Theme.of(context);
    final selectedCount = _selected.length;
    final matchedWallet = const MutationSourceDetector().matchWallet(
      _source,
      wallets,
    );
    // Dompet yang dipilih pengguna menang atas tebakan dari sumber mutasi.
    final bulkWalletId = _walletId ?? matchedWallet?.id;
    final duplicateCount = _rows.where((row) => row.duplicate != null).length;
    final uniformType = _uniformDirection;

    // Dompet baru diketahui setelah daftar rekening selesai dimuat. Ulangi
    // pencocokan supaya transaksi nominal sama di rekening lain tidak ikut
    // ditandai sebagai duplikat.
    if (bulkWalletId != _duplicateWalletId) {
      _duplicateWalletId = bulkWalletId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(_applyDuplicates);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinjau Hasil Scan'),
        actions: [
          TextButton(
            key: const Key('scan_select_all'),
            onPressed: _toggleAll,
            child: const Text('Pilih semua'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryBanner(
            imageCount: widget.sourceCount,
            itemCount: _rows.length,
            selectedCount: selectedCount,
            sourceLabel: _source?.label,
            matchedWalletName: matchedWallet?.name,
            duplicateCount: duplicateCount,
            checking: _checkingDuplicates,
            checkFailed: _duplicateCheckFailed,
            photoCount: widget.imagePaths.length,
            onViewPhotos: widget.imagePaths.isEmpty ? null : _showSourcePhotos,
          ),
          _DirectionSelector(
            selected: uniformType,
            onChanged: _setBulkDirection,
          ),
          _WalletSelector(
            wallets: wallets,
            walletId: bulkWalletId,
            hasError: _walletMissing,
            onChanged: _pickBulkWallet,
          ),
          if (_walletMissing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih dompet untuk transaksi yang akan disimpan.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: _rows.length,
              itemBuilder: (context, index) => _RowCard(
                key: ValueKey(_rows[index].item.id),
                row: _rows[index],
                wallets: wallets,
                bulkWalletId: bulkWalletId,
                onChanged: _onRowChanged,
                onDateTap: () => _pickDate(_rows[index]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$selectedCount transaksi dipilih',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      MoneyFormat(showDecimals: false).rupiah(_selectedTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const Key('scan_save'),
                onPressed: selectedCount == 0 || _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAll() {
    final allSelected = _rows.every((row) => row.selected);
    setState(() {
      for (final row in _rows) {
        // Pilihan eksplisit pengguna tidak boleh ditimpa pemeriksaan duplikat.
        row.selectionTouched = true;
        row.selected = !allSelected;
      }
    });
  }

  void _pickBulkWallet(String? value) {
    if (value == null) return;
    setState(() {
      _walletId = value;
      _walletMissing = false;
      // Dompet pilihan di atas berlaku untuk semua baris. Pengguna tetap bisa
      // mengganti satu baris lewat pemilih kecil di kartunya.
      for (final row in _rows) {
        row.walletId = value;
      }
    });
  }

  Future<void> _pickDate(_ReviewRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDate.parseKey(row.item.date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      row.item = row.item.copyWith(
        date: AppDate.key(picked),
        dateGuessed: false,
      );
      // Tanggal bisa mengubah hasil pencocokan dengan transaksi lama.
      _applyDuplicates();
    });
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected.isEmpty) return;

    final wallets = ref.read(walletBalancesProvider).value ?? const [];
    final matchedWallet = const MutationSourceDetector().matchWallet(
      _source,
      wallets,
    );
    final bulkWalletId = _walletId ?? matchedWallet?.id;

    if (bulkWalletId == null) {
      setState(() => _walletMissing = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu.')),
      );
      return;
    }

    final drafts = <TxDraft>[];
    for (final row in selected) {
      final amount = MoneyInput.tryParse(row.amount.text) ?? 0;
      final title = row.title.text.trim();
      final category = row.category.text.trim();
      final walletId = row.walletId ?? bulkWalletId;

      if (amount <= 0) {
        _warn('Nominal "${row.title.text}" belum benar.');
        return;
      }
      if (title.isEmpty) {
        _warn('Judul transaksi tidak boleh kosong.');
        return;
      }
      if (category.isEmpty) {
        _warn('Kategori "${row.title.text}" belum dipilih.');
        return;
      }

      drafts.add(
        row.item.type == ScannedTransactionType.income
            ? Movement.income(
                amount: amount,
                walletId: walletId,
                title: title,
                category: category,
                date: row.item.date,
                time: row.item.time,
                note: 'Dari Scan AI',
              )
            : Movement.expense(
                amount: amount,
                walletId: walletId,
                title: title,
                category: category,
                date: row.item.date,
                time: row.item.time,
                note: 'Dari Scan AI',
              ),
      );
    }

    // Pemeriksaan terakhir tepat sebelum menulis: membaca ulang riwayat dari
    // basis data, bukan hanya mengandalkan pemeriksaan saat layar dibuka.
    final duplicates = await _findSelectedDuplicates(selected, bulkWalletId);
    if (duplicates == null || !mounted) return;
    if (duplicates.isNotEmpty) {
      final proceed = await _confirmDuplicateSave(duplicates.length);
      if (proceed != true) {
        if (!mounted) return;
        setState(() {
          final merged = {for (final entry in _existing) entry.id: entry};
          for (final entry in duplicates.values) {
            merged[entry.id] = entry;
          }
          _existing = merged.values.toList(growable: false);
          _applyDuplicates();
          for (final row in _rows) {
            if (!duplicates.containsKey(row.item.id)) continue;
            row.selected = false;
            row.selectionTouched = true;
          }
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref
          .read(transactionRepositoryProvider)
          .createMany(drafts);
      if (!mounted) return;
      navigator.pop(count);
      messenger.showSnackBar(
        SnackBar(content: Text('$count transaksi tersimpan')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _warn('Gagal menyimpan: $error');
    }
  }

  /// Memeriksa ulang baris yang akan disimpan terhadap basis data. Mengembalikan
  /// `null` bila pemeriksaan gagal, supaya penyimpanan dibatalkan alih-alih
  /// menulis data yang belum sempat dicek.
  Future<Map<String, TransactionEntry>?> _findSelectedDuplicates(
    List<_ReviewRow> selected,
    String bulkWalletId,
  ) async {
    final dates = selected.map((row) => row.item.date).toList()..sort();
    try {
      final entries = await ref
          .read(transactionRepositoryProvider)
          .readRange(from: dates.first, until: dates.last);
      return const DuplicateTransactionFinder().find(
        scanned: [for (final row in selected) row.current],
        existing: entries,
        walletByScanId: {
          for (final row in selected) row.item.id: row.walletId ?? bulkWalletId,
        },
      );
    } catch (error) {
      if (mounted) _warn('Gagal memeriksa riwayat transaksi: $error');
      return null;
    }
  }

  Future<bool?> _confirmDuplicateSave(int count) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mungkin sudah tercatat'),
        content: Text(
          '$count transaksi yang dipilih sudah ada di riwayat dengan tanggal, '
          'arah, dan nominal yang sama. Tetap simpan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tetap simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSourcePhotos() {
    return showDialog<void>(
      context: context,
      builder: (_) => _SourcePhotoDialog(paths: widget.imagePaths),
    );
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.imageCount,
    required this.itemCount,
    required this.selectedCount,
    this.sourceLabel,
    this.matchedWalletName,
    this.duplicateCount = 0,
    this.checking = false,
    this.checkFailed = false,
    this.photoCount = 0,
    this.onViewPhotos,
  });

  final int imageCount;
  final int itemCount;
  final int selectedCount;
  final String? sourceLabel;
  final String? matchedWalletName;
  final int duplicateCount;
  final bool checking;
  final bool checkFailed;
  final int photoCount;
  final VoidCallback? onViewPhotos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onPrimaryContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: onContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$itemCount transaksi terbaca dari $imageCount gambar. '
                  'Periksa dan centang yang ingin disimpan.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onContainer,
                  ),
                ),
              ),
            ],
          ),
          if (sourceLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: onContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    matchedWalletName == null
                        ? 'Sumber terdeteksi: $sourceLabel.'
                        : 'Sumber terdeteksi: $sourceLabel. Dompet '
                              '"$matchedWalletName" dipilih otomatis.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (checking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Memeriksa riwayat transaksi...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onContainer,
                  ),
                ),
              ],
            ),
          ],
          if (checkFailed) ...[
            const SizedBox(height: 8),
            Text(
              'Riwayat tidak bisa diperiksa. Periksa manual sebelum menyimpan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (duplicateCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.content_copy,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$duplicateCount transaksi sudah ada di riwayat dan tidak '
                    'dicentang otomatis. Centang sendiri bila memang berbeda.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onViewPhotos != null && photoCount > 0) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              key: const Key('scan_view_photos'),
              onPressed: onViewPhotos,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text('Lihat foto sumber ($photoCount)'),
              style: TextButton.styleFrom(
                foregroundColor: onContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  const _DirectionSelector({required this.selected, required this.onChanged});

  /// Null berarti baris hasil scan masih campuran arahnya.
  final ScannedTransactionType? selected;
  final ValueChanged<ScannedTransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text('Arah untuk semua', style: theme.textTheme.bodySmall),
          ),
          SegmentedButton<ScannedTransactionType>(
            key: const Key('scan_direction_all'),
            segments: const [
              ButtonSegment(
                value: ScannedTransactionType.expense,
                label: Text('Keluar'),
                icon: Icon(Icons.arrow_upward, size: 16),
              ),
              ButtonSegment(
                value: ScannedTransactionType.income,
                label: Text('Masuk'),
                icon: Icon(Icons.arrow_downward, size: 16),
              ),
            ],
            selected: selected == null
                ? const <ScannedTransactionType>{}
                : {selected!},
            emptySelectionAllowed: true,
            onSelectionChanged: (value) {
              if (value.isEmpty) return;
              onChanged(value.first);
            },
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

class _WalletSelector extends StatelessWidget {
  const _WalletSelector({
    required this.wallets,
    required this.walletId,
    required this.hasError,
    required this.onChanged,
  });

  final List<WalletBalance> wallets;
  final String? walletId;
  final bool hasError;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // FormField hanya membaca `initialValue` sekali. Kunci yang ikut berubah
    // membuat dropdown ikut menampilkan dompet yang dicocokkan otomatis.
    return KeyedSubtree(
      key: ValueKey('scan_wallet_${walletId ?? ''}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: DropdownButtonFormField<String>(
          key: const Key('scan_wallet'),
          initialValue: walletId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Dompet untuk semua',
            border: const OutlineInputBorder(),
            errorText: hasError ? 'Wajib dipilih' : null,
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          items: [
            for (final wallet in wallets)
              DropdownMenuItem(
                value: wallet.id,
                child: Text(wallet.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReviewRow {
  _ReviewRow(this.item)
    : title = TextEditingController(text: item.title),
      category = TextEditingController(text: item.category),
      amount = TextEditingController(
        text: MoneyInputFormatter.formatValue(item.amount),
      );

  ScannedTransaction item;
  final TextEditingController title;
  final TextEditingController category;
  final TextEditingController amount;
  bool selected = true;
  bool selectionTouched = false;
  String? walletId;

  /// Transaksi lama yang kemungkinan besar sama dengan baris ini.
  TransactionEntry? duplicate;

  /// Nilai baris saat ini, termasuk nominal dan kategori yang sedang diketik.
  ScannedTransaction get current => item.copyWith(
    amount: MoneyInput.tryParse(amount.text) ?? 0,
    category: category.text,
  );

  void dispose() {
    title.dispose();
    category.dispose();
    amount.dispose();
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    super.key,
    required this.row,
    required this.wallets,
    required this.bulkWalletId,
    required this.onChanged,
    required this.onDateTap,
  });

  final _ReviewRow row;
  final List<WalletBalance> wallets;
  final String? bulkWalletId;
  final VoidCallback onChanged;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = row.item;
    final categories = <String>{
      item.category,
      if (item.type == ScannedTransactionType.expense)
        ...CategoryGuesser.expenseCategories
      else
        ...CategoryGuesser.incomeCategories,
    }.toList(growable: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: row.duplicate == null
          ? null
          : theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: row.selected,
                  onChanged: (value) {
                    // Pengguna boleh tetap menyimpan duplikat bila yakin.
                    row.selectionTouched = true;
                    row.selected = value ?? false;
                    onChanged();
                  },
                ),
                Expanded(
                  child: TextField(
                    key: Key('scan_title_${item.id}'),
                    controller: row.title,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Judul / merchant',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            if (row.duplicate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 0, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.content_copy,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sudah tercatat: ${_duplicateDescription(row.duplicate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: Key('scan_amount_${item.id}'),
                      controller: row.amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [MoneyInputFormatter()],
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDateTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tanggal', style: theme.textTheme.labelSmall),
                          Text(
                            item.time == null
                                ? AppDate.readable(item.date)
                                : '${AppDate.readable(item.date)} • ${item.time}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (item.dateGuessed)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Tanggal tidak terbaca dari gambar; mohon dicek.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SegmentedButton<ScannedTransactionType>(
                segments: const [
                  ButtonSegment(
                    value: ScannedTransactionType.expense,
                    label: Text('Keluar'),
                    icon: Icon(Icons.arrow_upward, size: 16),
                  ),
                  ButtonSegment(
                    value: ScannedTransactionType.income,
                    label: Text('Masuk'),
                    icon: Icon(Icons.arrow_downward, size: 16),
                  ),
                ],
                selected: {item.type},
                onSelectionChanged: (value) {
                  row.item = row.item.copyWith(type: value.first);
                  onChanged();
                },
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: TextField(
                key: Key('scan_category_${item.id}'),
                controller: row.category,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Kategori',
                  hintText: 'Ketik kategori baru',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  row.item = row.item.copyWith(category: value);
                  onChanged();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SuggestionChips(
                type: SuggestionRules.categoryType,
                kind: item.type == ScannedTransactionType.expense
                    ? TxKind.expense
                    : TxKind.income,
                query: row.category.text,
                fallback: categories,
                onSelected: (value) {
                  row.category.text = value;
                  row.item = row.item.copyWith(category: value);
                  onChanged();
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _RowWalletPicker(
                key: ValueKey(
                  'row_wallet_${item.id}_${row.walletId ?? bulkWalletId ?? ''}',
                ),
                wallets: wallets,
                value: row.walletId ?? bulkWalletId,
                onChanged: (value) {
                  row.walletId = value;
                  onChanged();
                },
              ),
            ),
            if (item.rawText.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Teks asli'),
                      content: SingleChildScrollView(
                        child: SelectableText(item.rawText),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.text_snippet_outlined, size: 16),
                  label: const Text('Lihat teks asli'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _duplicateDescription(TransactionEntry entry) {
    final title = entry.title?.trim() ?? '';
    final category = entry.category?.trim() ?? '';
    final name = title.isNotEmpty
        ? title
        : (category.isNotEmpty ? category : 'transaksi lain');
    final wallet = entry.walletName?.trim() ?? '';
    return wallet.isEmpty ? '"$name"' : '"$name" • $wallet';
  }
}

class _RowWalletPicker extends StatelessWidget {
  const _RowWalletPicker({
    super.key,
    required this.wallets,
    required this.value,
    required this.onChanged,
  });

  final List<WalletBalance> wallets;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Dompet',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
      ),
      items: [
        for (final wallet in wallets)
          DropdownMenuItem(
            value: wallet.id,
            child: Row(
              children: [
                Icon(walletIcon(wallet.type, wallet.iconKey), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(wallet.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Menampilkan foto sumber yang dipakai Scan AI. Beberapa gambar bisa digeser
/// dan setiap gambar bisa diperbesar untuk memeriksa detail mutasi.
class _SourcePhotoDialog extends StatefulWidget {
  const _SourcePhotoDialog({required this.paths});

  final List<String> paths;

  @override
  State<_SourcePhotoDialog> createState() => _SourcePhotoDialogState();
}

class _SourcePhotoDialogState extends State<_SourcePhotoDialog> {
  late final PageController _controller;
  late final List<Future<Uint8List>> _images;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _images = [for (final path in widget.paths) XFile(path).readAsBytes()];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.maxFinite,
        height: size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Foto sumber',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${_index + 1} / ${widget.paths.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                  IconButton(
                    key: const Key('scan_close_photos'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.paths.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 6,
                  child: Center(
                    child: FutureBuilder<Uint8List>(
                      future: _images[index],
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Foto tidak bisa dibuka.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final bytes = snapshot.data;
                        if (bytes == null) {
                          return const CircularProgressIndicator();
                        }
                        return Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
