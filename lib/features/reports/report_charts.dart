import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/palette.dart';
import '../../core/money.dart';
import '../../domain/asset_trend.dart';
import '../../domain/report_breakdown.dart';

/// Warna bagian grafik. Dipakai berurutan, berulang bila bagiannya lebih banyak.
///
/// Urutannya milik [AppPalette.chart] supaya grafik memakai keluarga warna yang
/// sama dengan antarmuka. Licensi `fl_chart` MIT, sesuai SPEC L-12 — bukan
/// Syncfusion komersial.
const List<Color> reportPalette = AppPalette.chart;

/// Grafik lingkaran rincian, dengan keterangan warnanya di bawah. SPEC L-2 dan
/// L-11.
class BreakdownPieChart extends StatelessWidget {
  const BreakdownPieChart({
    super.key,
    required this.items,
    required this.money,
  });

  final List<BreakdownItem> items;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                for (var index = 0; index < items.length; index++)
                  PieChartSectionData(
                    value: items[index].amount.toDouble(),
                    color: reportPalette[index % reportPalette.length],
                    radius: 54,
                    title: '${(items[index].share * 100).round()}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 200),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < items.length; index++)
          _LegendRow(
            color: reportPalette[index % reportPalette.length],
            item: items[index],
            money: money,
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.item,
    required this.money,
  });

  final Color color;
  final BreakdownItem item;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(money.rupiah(item.amount), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Grafik garis Tren Aset. SPEC L-6.
class AssetTrendChart extends StatelessWidget {
  const AssetTrendChart({super.key, required this.points, required this.money});

  final List<AssetTrendPoint> points;
  final MoneyFormat money;

  static final DateFormat _axisDate = DateFormat('d MMM', 'id_ID');

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Belum cukup data untuk menggambar tren.'),
      );
    }

    final values = points.map((point) => point.balance).toList();
    var minY = values.reduce((a, b) => a < b ? a : b).toDouble();
    var maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (minY == maxY) {
      // Garis datar tetap butuh ruang di atas dan bawah agar terlihat.
      minY -= 1;
      maxY += 1;
    }
    final interval = ((maxY - minY) / 4).clamp(1, double.infinity).toDouble();
    final labelEvery = (points.length / 4).ceil().clamp(1, points.length);

    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: interval,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: interval,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _compact(value),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % labelEvery != 0 && index != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _axisDate.format(DateTime.parse(points[index].date)),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: false,
              barWidth: 2,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
              spots: [
                for (var index = 0; index < points.length; index++)
                  FlSpot(index.toDouble(), points[index].balance.toDouble()),
              ],
            ),
          ],
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// `1,2 jt` — cukup untuk sumbu grafik, bukan untuk nilai uang penuh.
  static String _compact(double value) {
    final magnitude = value.abs();
    if (magnitude >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} M';
    }
    if (magnitude >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (magnitude >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} rb';
    }
    return value.toStringAsFixed(0);
  }
}
