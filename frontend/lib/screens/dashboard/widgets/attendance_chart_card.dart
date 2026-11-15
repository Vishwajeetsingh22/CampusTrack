import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/app_theme.dart';
import '../../../models/report_models.dart';

class AttendanceChartCard extends StatelessWidget {
  final List<StatusCount> statusBreakdown;
  final double overallPct;

  const AttendanceChartCard({
    super.key,
    required this.statusBreakdown,
    required this.overallPct,
  });

  @override
  Widget build(BuildContext context) {
    int present = 0;
    int absent = 0;
    int late = 0;

    for (var s in statusBreakdown) {
      if (s.status == 'Present') present = s.count;
      if (s.status == 'Absent') absent = s.count;
      if (s.status == 'Late') late = s.count;
    }

    final maxVal = [present, absent, late].reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxVal > 0 ? (maxVal * 1.25).ceilToDouble() : 10.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      'Attendance Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navyPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Present vs Absent vs Late Logs',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: overallPct >= 75 ? AppTheme.successBg : AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: overallPct >= 75 ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ),
                  child: Text(
                    '$overallPct% Overall',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: overallPct >= 75 ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label = '';
                        switch (group.x) {
                          case 0:
                            label = 'Present';
                            break;
                          case 1:
                            label = 'Absent';
                            break;
                          case 2:
                            label = 'Late';
                            break;
                        }
                        return BarTooltipItem(
                          '$label: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.successGreen)),
                              );
                            case 1:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Absent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
                              );
                            case 2:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Late', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warningOrange)),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: present.toDouble(),
                          color: AppTheme.successGreen,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: absent.toDouble(),
                          color: AppTheme.errorRed,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: late.toDouble(),
                          color: AppTheme.warningOrange,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
