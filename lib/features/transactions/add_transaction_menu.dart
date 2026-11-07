import 'package:flutter/material.dart';

import '../../domain/tx_kind.dart';
import 'tx_visuals.dart';

/// Tiga pilihan yang muncul saat tombol `+` di halaman Transaksi ditekan.
///
/// Urutannya disalin dari Sepran: **Pindah Saldo, Pemasukan, Pengeluaran**
/// (SPEC T-14). Koreksi Saldo tidak ada di sini — jenis itu dicapai dari
/// halaman Rekening (SPEC T-15 dan K-6).
enum AddTransactionChoice { transfer, income, expense }

Future<AddTransactionChoice?> showAddTransactionMenu(BuildContext context) {
  return showModalBottomSheet<AddTransactionChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Choice(
            label: 'Pindah Saldo',
            icon: txKindIcon(TxKind.transferOut),
            color: txNeutralColor,
            onTap: () =>
                Navigator.of(sheetContext).pop(AddTransactionChoice.transfer),
          ),
          _Choice(
            label: 'Pemasukan',
            icon: txKindIcon(TxKind.income),
            color: txIncomeColor,
            onTap: () =>
                Navigator.of(sheetContext).pop(AddTransactionChoice.income),
          ),
          _Choice(
            label: 'Pengeluaran',
            icon: txKindIcon(TxKind.expense),
            color: txExpenseColor,
            onTap: () =>
                Navigator.of(sheetContext).pop(AddTransactionChoice.expense),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
