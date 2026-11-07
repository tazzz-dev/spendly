import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/tx_kind.dart';
import '../../domain/tx_rules.dart';
import '../../domain/tx_suggestion.dart';

/// Deretan chip saran di bawah field Judul dan Kategori. SPEC T-20.
///
/// Tampilannya sengaja **satu baris** saja: saat field masih kosong hanya
/// beberapa saran teratas yang terlihat, dan begitu pengguna mengetik daftarnya
/// menyempit mengikuti teks itu — seperti kolom pencarian. Dengan begitu form
/// tidak langsung dibanjiri semua pilihan.
class SuggestionChips extends ConsumerWidget {
  const SuggestionChips({
    super.key,
    required this.type,
    required this.kind,
    required this.onSelected,
    this.query = '',
    this.initialCount = SuggestionRules.initialVisibleCount,
    this.fallback = const [],
  });

  /// [SuggestionRules.titleType] atau [SuggestionRules.categoryType].
  final String type;

  /// Saran dipisah per jenis transaksi. SPEC C-3.
  final TxKind kind;

  final ValueChanged<String> onSelected;

  /// Teks yang sedang diketik di field. Bila kosong, hanya [initialCount] saran
  /// pertama yang ditampilkan; bila berisi, saran disaring mirip pencarian.
  final String query;

  /// Berapa chip yang terlihat sebelum pengguna mulai mengetik.
  final int initialCount;

  /// Saran tambahan yang dipakai bila riwayat belum punya saran untuk jenis
  /// ini. Dipakai layar Scan AI agar kategori umum tetap bisa dipilih.
  final List<String> fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(
      suggestionsProvider(SuggestionQuery(type: type, kind: kind)),
    );

    final names = <String>[
      for (final suggestion in suggestions.value ?? const <TxSuggestion>[])
        suggestion.name,
      ...fallback,
    ];
    final unique = <String>[];
    for (final name in names) {
      final value = name.trim();
      if (value.isEmpty) continue;
      if (unique.any(
        (existing) => existing.toLowerCase() == value.toLowerCase(),
      )) {
        continue;
      }
      unique.add(value);
    }
    if (unique.isEmpty) return const SizedBox.shrink();

    final typed = query.trim().toLowerCase();
    final visible = typed.isEmpty
        ? unique.take(initialCount).toList(growable: false)
        : unique
              .where((name) => name.toLowerCase().contains(typed))
              .take(SuggestionRules.visibleCount)
              .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              ActionChip(
                // SPEC T-20: chip biru penuh dengan teks putih.
                backgroundColor: scheme.primary,
                labelStyle: TextStyle(color: scheme.onPrimary),
                label: Text(visible[index]),
                onPressed: () => onSelected(visible[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
