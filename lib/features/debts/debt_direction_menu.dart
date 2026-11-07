import 'package:flutter/material.dart';

import '../../domain/debt_direction.dart';
import 'debt_visuals.dart';

/// Menu dua arah yang muncul saat tombol `+` halaman Hutang ditekan.
///
/// SPEC H-2: tombol `+` **tidak langsung membuka form**. Ia lebih dulu
/// menawarkan dua arah, berurutan dari atas: **Memberi** (lingkaran merah,
/// panah ganda ke bawah) lalu **Menerima** (lingkaran oranye, panah ganda ke
/// atas). Urutannya mengikuti urutan `DebtDirection.values`.
Future<DebtDirection?> showDebtDirectionMenu(BuildContext context) {
  return showModalBottomSheet<DebtDirection>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final direction in DebtDirection.values)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: debtDirectionColor(direction),
                child: Icon(debtDirectionIcon(direction), color: Colors.white),
              ),
              title: Text(direction.label),
              onTap: () => Navigator.of(sheetContext).pop(direction),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
