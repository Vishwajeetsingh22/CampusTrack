import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/app_theme.dart';
import '../../../models/report_models.dart';

class AttendanceThresholdChart extends StatelessWidget {
  final List<AttendanceReportItem> attendanceList;

  const AttendanceThresholdChart({super.key, required this.attendanceList});

  @override
  Widget build(BuildContext context) {
    if (attendanceList.isEmpty) return const SizedBox.shrink();

    // Show up to the top 10 students in the chart to keep bars readable
    final displayList = attendanceList.take(10).toList();

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
                      'Attendance vs 75% Threshold',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navyPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Student attendance % with mandatory cutoff',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.horizontal_rule_rounded, size: 14, color: AppTheme.errorRed),
                      SizedBox(width: 4),
                      Text(
                        '75% Cutoff',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 75.0,
                        color: AppTheme.errorRed,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 6, bottom: 2),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorRed,
                          ),
                          labelResolver: (line) => '75% Min',
                        ),
                      ),
                    ],
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final student = displayList[group.x.toInt()];
                        final isDefaulter = student.attendancePct < 75.0;
                        return BarTooltipItem(
                          '${student.name}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${student.studentId} • ${student.attendancePct}% (${isDefaulter ? "Deficit" : "Normal"})',
                              style: TextStyle(
                                color: isDefaulter ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
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
                          if (idx < 0 || idx >= displayList.length) {
                            return const SizedBox.shrink();
                          }
                          final roll = displayList[idx].studentId.replaceAll(RegExp(r'[^0-9]'), '');
                          final label = roll.length >= 3 ? roll.substring(roll.length - 3) : roll;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label.isNotEmpty ? label : displayList[idx].studentId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
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
                  barGroups: List.generate(displayList.length, (i) {
                    final item = displayList[i];
                    final isDeficit = item.attendancePct < 75.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: item.attendancePct,
                          color: isDeficit ? AppTheme.errorRed : AppTheme.successGreen,
                          width: 14,
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
}
