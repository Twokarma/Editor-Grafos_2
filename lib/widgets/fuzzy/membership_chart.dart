import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/fuzzy/fuzzy_variable.dart';

/// Grafica las funciones de pertenencia de una variable.
///
/// - [marker]: línea vertical con el valor actual.
/// - [aggX] / [aggMu]: área de salida agregada (Mamdani).
class MembershipChart extends StatelessWidget {
  final FuzzyVariable variable;
  final double? marker;
  final List<double>? aggX;
  final List<double>? aggMu;
  final double height;

  const MembershipChart({
    super.key,
    required this.variable,
    this.marker,
    this.aggX,
    this.aggMu,
    this.height = 180,
  });

  static const List<Color> palette = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.brown,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final terms = variable.terms.entries.toList();
    final span = variable.max - variable.min;

    if (terms.isEmpty || span <= 0) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'Agrega términos para ver la gráfica',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    const n = 200;
    final bars = <LineChartBarData>[];

    for (int i = 0; i < terms.length; i++) {
      final mf = terms[i].value;
      final spots = List<FlSpot>.generate(n + 1, (k) {
        final x = variable.min + span * k / n;
        return FlSpot(x, mf.eval(x));
      });
      bars.add(LineChartBarData(
        spots: spots,
        isCurved: false,
        color: palette[i % palette.length],
        barWidth: 2,
        dotData: const FlDotData(show: false),
      ));
    }

    final ax = aggX;
    final am = aggMu;
    if (ax != null && am != null && ax.length == am.length && ax.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: [for (int k = 0; k < ax.length; k++) FlSpot(ax[k], am[k])],
        isCurved: false,
        color: Colors.black54,
        barWidth: 1.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.black.withValues(alpha: 0.12),
        ),
      ));
    }

    final m = marker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 14),
            child: LineChart(
              LineChartData(
                minX: variable.min,
                maxX: variable.max,
                minY: 0,
                maxY: 1.1,
                lineBarsData: bars,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 0.5,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: span / 4,
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: m == null
                      ? []
                      : [
                          VerticalLine(
                            x: m.clamp(variable.min, variable.max).toDouble(),
                            color: Colors.red,
                            strokeWidth: 2,
                            dashArray: const [6, 4],
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (int i = 0; i < terms.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: palette[i % palette.length],
                  ),
                  const SizedBox(width: 4),
                  Text(terms[i].key, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}