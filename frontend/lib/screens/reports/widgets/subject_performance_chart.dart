import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/app_theme.dart';
import '../../../models/report_models.dart';

class SubjectPerformanceChart extends StatelessWidget {
  final List<SubjectPerformanceItem> subjects;

  const SubjectPerformanceChart({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject Comparison Analytics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navyPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Average Marks vs Pass Rate (%)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildLegendItem('Avg Score', AppTheme.indigoAccent),
                    const SizedBox(width: 12),
                    _buildLegendItem('Pass Rate', AppTheme.successGreen),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final sub = subjects[group.x.toInt()];
                        final isAvg = rodIndex == 0;
                        return BarTooltipItem(
                          '${sub.subject}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: isAvg
                                  ? 'Avg Score: ${rod.toY.toStringAsFixed(1)}%'
                                  : 'Pass Rate: ${rod.toY.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isAvg ? const Color(0xFF818CF8) : const Color(0xFF6EE7B7),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            '${val.toInt()}%',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= subjects.length) {
                            return const SizedBox.shrink();
                          }
                          final words = subjects[idx].subject.split(' ');
                          final abbr = words.map((w) => w.isNotEmpty ? w[0] : '').take(3).join();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              abbr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (val) {
                      return FlLine(
                        color: AppTheme.cardBorder,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(subjects.length, (i) {
                    final sub = subjects[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: sub.avgPercentage,
                          color: AppTheme.indigoAccent,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: sub.passPercentage,
                          color: AppTheme.successGreen,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
