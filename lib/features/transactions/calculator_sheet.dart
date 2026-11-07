import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../domain/calculator.dart';

/// Membuka kalkulator dan mengembalikan hasilnya.
///
/// Mengembalikan null bila pengguna menutupnya tanpa memilih. SPEC G-3.
Future<int?> showCalculator(BuildContext context, {int? initial}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CalculatorSheet(initial: initial),
  );
}

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet({this.initial});

  final int? initial;

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  late String _expression;

  @override
  void initState() {
    super.initState();
    _expression = widget.initial == null ? '' : '${widget.initial}';
  }

  int? get _result => MoneyCalculator.evaluate(_expression);

  bool get _endsWithOperator =>
      _expression.isNotEmpty &&
      MoneyCalculator.isOperator(_expression.substring(_expression.length - 1));

  void _appendDigit(String digit) => setState(() => _expression += digit);

  void _appendOperator(String operator) {
    setState(() {
      if (_expression.isEmpty) return;
      // Menekan dua operator berturut-turut mengganti yang pertama, bukan
      // menumpuknya — perilaku yang sama dengan kalkulator biasa.
      if (_endsWithOperator) {
        _expression =
            _expression.substring(0, _expression.length - 1) + operator;
      } else {
        _expression += operator;
      }
    });
  }

  void _clear() => setState(() => _expression = '');

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
    });
  }

  /// Menekan `=` memindahkan hasilnya ke baris ungkapan, sehingga bisa
  /// dilanjutkan dengan hitungan berikutnya.
  void _commit() {
    final value = _result;
    if (value == null) return;
    setState(() => _expression = '$value');
  }

  void _use() {
    final value = _result;
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = MoneyFormat(showDecimals: false);
    final result = _result;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression.isEmpty ? '0' : _expression,
                    key: const Key('calculator_expression'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result == null ? '—' : money.rupiah(result),
                    key: const Key('calculator_result'),
                    style: theme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _row([
              _Key(label: 'C', onTap: _clear, tone: _KeyTone.muted),
              _Key(label: '⌫', onTap: _backspace, tone: _KeyTone.muted),
              _Key(
                label: '÷',
                onTap: () => _appendOperator(MoneyCalculator.divide),
              ),
              _Key(
                label: '×',
                onTap: () => _appendOperator(MoneyCalculator.multiply),
              ),
            ]),
            _row([
              _digit('7'),
              _digit('8'),
              _digit('9'),
              _Key(label: '−', onTap: () => _appendOperator('-')),
            ]),
            _row([
              _digit('4'),
              _digit('5'),
              _digit('6'),
              _Key(label: '+', onTap: () => _appendOperator('+')),
            ]),
            _row([
              _digit('1'),
              _digit('2'),
              _digit('3'),
              _Key(label: '=', onTap: _commit),
            ]),
            Row(
              children: [
                Expanded(flex: 2, child: _digit('0')),
                Expanded(child: _digit('000')),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('calculator_use'),
              onPressed: result == null ? null : _use,
              child: const Text('Gunakan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _digit(String digit) =>
      _Key(label: digit, onTap: () => _appendDigit(digit));

  Widget _row(List<Widget> keys) =>
      Row(children: [for (final key in keys) Expanded(child: key)]);
}

enum _KeyTone { normal, muted }

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.tone = _KeyTone.normal,
  });

  final String label;
  final VoidCallback onTap;
  final _KeyTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 56,
        child: FilledButton.tonal(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: tone == _KeyTone.muted
                ? scheme.surfaceContainerHighest
                : null,
            textStyle: Theme.of(context).textTheme.titleLarge,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
