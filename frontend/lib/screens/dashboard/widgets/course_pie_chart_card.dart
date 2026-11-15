import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/app_theme.dart';
import '../../../models/report_models.dart';

class CoursePieChartCard extends StatefulWidget {
  final List<CourseCount> courseDistribution;

  const CoursePieChartCard({super.key, required this.courseDistribution});

  @override
  State<CoursePieChartCard> createState() => _CoursePieChartCardState();
}

class _CoursePieChartCardState extends State<CoursePieChartCard> {
  int _touchedIndex = -1;

  final List<Color> _palette = const [
    Color(0xFF4338CA), // Indigo
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF059669), // Emerald Green
    Color(0xFFD97706), // Amber
    Color(0xFF7C3AED), // Purple
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.courseDistribution.fold<int>(0, (sum, item) => sum + item.count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Enrollment Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.navyPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Students per Academic Program',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            if (total == 0)
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text('No student enrollment data available.'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: List.generate(widget.courseDistribution.length, (i) {
                            final isTouched = i == _touchedIndex;
                            final fontSize = isTouched ? 14.0 : 11.0;
                            final radius = isTouched ? 56.0 : 48.0;
                            final item = widget.courseDistribution[i];
                            final pct = (item.count / total * 100).round();
                            final color = _palette[i % _palette.length];

                            return PieChartSectionData(
                              color: color,
                              value: item.count.toDouble(),
                              title: '$pct%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(widget.courseDistribution.length, (i) {
                        final item = widget.courseDistribution[i];
                        final color = _palette[i % _palette.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.course,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.count}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
