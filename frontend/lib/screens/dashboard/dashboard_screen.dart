import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stat_kpi_card.dart';
import 'widgets/attendance_chart_card.dart';
import 'widgets/course_pie_chart_card.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.stats == null) {
          return const LoadingIndicator(message: 'Loading CampusTrack analytics...');
        }

        if (provider.errorMessage != null && provider.stats == null) {
          return ErrorStateView(
            message: provider.errorMessage!,
            onRetry: () => provider.loadDashboard(refresh: true),
          );
        }

        final stats = provider.stats;
        if (stats == null) {
          return const Center(child: Text('No dashboard data available.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDashboard(refresh: true),
          color: AppTheme.indigoAccent,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Header title
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'College Administration Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navyPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Real-time student attendance and academic tracking',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Cards Grid (Responsive layout)
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 600 ? 2 : 2);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: constraints.maxWidth >= 600 ? 1.5 : 1.35,
                    children: [
                      StatKpiCard(
                        title: 'Total Students',
                        value: stats.totalStudents.toString(),
                        icon: Icons.people_alt_rounded,
                        iconColor: AppTheme.indigoAccent,
                        subtitle: '${stats.activeStudents} Active Enrollment',
                        onTap: () => widget.onNavigateTab?.call(1),
                      ),
                      StatKpiCard(
                        title: 'Class Attendance',
                        value: '${stats.overallAttendancePct}%',
                        icon: Icons.fact_check_rounded,
                        iconColor: stats.overallAttendancePct >= 75 ? AppTheme.successGreen : AppTheme.errorRed,
                        subtitle: '${stats.totalAttendanceRecords} Sessions Logged',
                        onTap: () => widget.onNavigateTab?.call(2),
                      ),
                      StatKpiCard(
                        title: 'Average Marks',
                        value: '${stats.avgMarksPct}%',
                        icon: Icons.grade_rounded,
                        iconColor: const Color(0xFF0284C7),
                        subtitle: '${stats.totalMarksRecords} Exam Submissions',
                        onTap: () => widget.onNavigateTab?.call(3),
                      ),
                      StatKpiCard(
                        title: 'Attendance Defaulters',
                        value: stats.lowAttendanceCount.toString(),
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppTheme.errorRed,
                        iconBgColor: AppTheme.errorBg,
                        subtitle: '< 75% Attendance Alert',
                        onTap: () => widget.onNavigateTab?.call(4),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Quick Actions Row
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUICK ACTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildActionButton(
                            icon: Icons.person_add_rounded,
                            label: 'Register Student',
                            color: AppTheme.indigoAccent,
                            onTap: () => widget.onNavigateTab?.call(1),
                          ),
                          _buildActionButton(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Mark Attendance',
                            color: AppTheme.successGreen,
                            onTap: () => widget.onNavigateTab?.call(2),
                          ),
                          _buildActionButton(
                            icon: Icons.edit_note_rounded,
                            label: 'Record Exam Marks',
                            color: const Color(0xFF0284C7),
                            onTap: () => widget.onNavigateTab?.call(3),
                          ),
                          _buildActionButton(
                            icon: Icons.analytics_rounded,
                            label: 'View Defaulters Report',
                            color: AppTheme.errorRed,
                            onTap: () => widget.onNavigateTab?.call(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Charts Layout (Side-by-side on wide screens, stacked on phones)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AttendanceChartCard(
                            statusBreakdown: stats.statusBreakdown,
                            overallPct: stats.overallAttendancePct,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CoursePieChartCard(
                            courseDistribution: stats.courseDistribution,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      AttendanceChartCard(
                        statusBreakdown: stats.statusBreakdown,
                        overallPct: stats.overallAttendancePct,
                      ),
                      const SizedBox(height: 12),
                      CoursePieChartCard(
                        courseDistribution: stats.courseDistribution,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
