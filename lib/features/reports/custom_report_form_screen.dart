import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../data/providers.dart';
import '../../domain/report_rules.dart';
import '../../domain/saved_report.dart';

/// Membuka form rekap kustom. Tanpa [initial] berarti menambah. SPEC L-8.
Future<void> openCustomReportForm(
  BuildContext context, {
  SavedReport? initial,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => CustomReportFormScreen(initial: initial)),
  );
}

/// Form tambah dan ubah rekap kustom. SPEC L-8.
///
/// Validasi: nama wajib diisi, dan tanggal akhir tidak boleh lebih kecil dari
/// tanggal awal.
class CustomReportFormScreen extends ConsumerStatefulWidget {
  const CustomReportFormScreen({super.key, this.initial});

  final SavedReport? initial;

  @override
  ConsumerState<CustomReportFormScreen> createState() =>
      _CustomReportFormScreenState();
}

class _CustomReportFormScreenState
    extends ConsumerState<CustomReportFormScreen> {
  late final TextEditingController _name;
  late String _start;
  late String _end;
  bool _busy = false;

  SavedReport? get _initial => widget.initial;
  bool get _isEditing => _initial != null;

  @override
  void initState() {
    super.initState();
    final initial = _initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _start = initial?.startDate ?? AppDate.today();
    _end = initial?.endDate ?? AppDate.today();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Ubah Rekap' : 'Rekap Baru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama Rekap',
              hintText: 'Contoh: Liburan Akhir Tahun',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLength: ReportRules.maxCustomNameLength,
          ),
          const SizedBox(height: 8),
          _DateField(
            label: 'Tanggal Mulai',
            value: _start,
            onPick: () => _pickDate(isStart: true),
          ),
          const SizedBox(height: 16),
          _DateField(
            label: 'Tanggal Selesai',
            value: _end,
            onPick: () => _pickDate(isStart: false),
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
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = AppDate.parseKey(isStart ? _start : _end);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      final key = AppDate.key(picked);
      if (isStart) {
        _start = key;
      } else {
        _end = key;
      }
    });
  }

  Future<void> _save() async {
    final message = ReportRules.validateCustom(
      name: _name.text,
      start: _start,
      end: _end,
    );
    final messenger = ScaffoldMessenger.of(context);
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final repository = ref.read(reportRepositoryProvider);
    final navigator = Navigator.of(context);
    final initial = _initial;

    setState(() => _busy = true);

    try {
      if (initial == null) {
        await repository.createCustomReport(
          name: _name.text,
          startDate: _start,
          endDate: _end,
        );
      } else {
        await repository.updateCustomReport(
          id: initial.id,
          name: _name.text,
          startDate: _start,
          endDate: _end,
        );
      }
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
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final String value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(AppDate.readable(value)),
      ),
    );
  }
}
