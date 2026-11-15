import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/report_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/attendance_threshold_chart.dart';
import 'widgets/subject_performance_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadAllReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reports & Analytics'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.indigoAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  text: 'Attendance (${provider.attendanceReport.length})',
                ),
                Tab(
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  text: 'Subject Stats (${provider.performanceSubjects.length})',
                ),
                Tab(
                  icon: const Icon(Icons.leaderboard_rounded, size: 18),
                  text: 'Rankings (${provider.rankingsReport.length})',
                ),
                Tab(
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  text: 'Defaulters <75% (${provider.defaultersReport.length})',
                ),
              ],
            ),
          ),
          body: provider.isLoading && provider.attendanceReport.isEmpty
              ? const LoadingIndicator(message: 'Generating MongoDB aggregation reports...')
              : provider.errorMessage != null && provider.attendanceReport.isEmpty
                  ? ErrorStateView(
                      message: provider.errorMessage!,
                      onRetry: () => provider.loadAllReports(),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAttendanceTab(provider),
                        _buildPerformanceTab(provider),
                        _buildRankingsTab(provider),
                        _buildDefaultersTab(provider),
                      ],
                    ),
        );
      },
    );
  }

  // 1. Attendance Report Tab
  Widget _buildAttendanceTab(ReportProvider provider) {
    final list = provider.attendanceReport;
    if (list.isEmpty) {
      return const EmptyStateView(
        icon: Icons.fact_check_outlined,
        title: 'No Attendance Data',
        message: 'No student attendance records to summarize.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAllReports(),
      color: AppTheme.indigoAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AttendanceThresholdChart(attendanceList: list),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Student Attendance Roster',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyPrimary,
                  ),
                ),
                Text(
                  'Late = 0.5 Credit Rule',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          ...list.map((item) {
            final isLow = item.attendancePct < 75.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isLow ? AppTheme.errorBg : AppTheme.successBg,
                      child: Text(
                        '${item.attendancePct.round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLow ? AppTheme.errorRed : AppTheme.successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${item.studentId} • ${item.course} • Sem ${item.semester}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            'Present: ${item.presentCount} | Absent: ${item.absentCount} | Late: ${item.lateCount} (${item.totalClasses} total)',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLow ? AppTheme.errorBg : AppTheme.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLow ? 'DEFICIT' : 'REGULAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isLow ? AppTheme.errorRed : AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 2. Subject Performance Tab
  Widget _buildPerformanceTab(ReportProvider provider) {
    final subjects = provider.performanceSubjects;
    final overall = provider.performanceOverall;

    if (subjects.isEmpty) {
      return const EmptyStateView(
        icon: Icons.bar_chart_rounded,
        title: 'No Performance Data',
        message: 'No exam scores recorded yet for subject analytics.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAllReports(),
      color: AppTheme.indigoAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Metric Card
          Card(
            color: AppTheme.navyPrimary,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWhiteStat('Overall Class Avg', '${overall['overall_avg'] ?? 0.0}%'),
                  _buildWhiteStat('Highest Mark', '${overall['highest_score'] ?? 0.0}%'),
                  _buildWhiteStat('Total Tests', '${overall['total_assessments'] ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Subject Performance Visual Chart
          SubjectPerformanceChart(subjects: subjects),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Individual Subject Statistics',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
            ),
          ),
          const SizedBox(height: 8),

          // Subject List
          ...subjects.map((sub) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(sub.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.successBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            'Pass: ${sub.passPercentage}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSubStat('Average', '${sub.avgPercentage}%', AppTheme.indigoAccent),
                        _buildSubStat('Highest', '${sub.maxPercentage}%', AppTheme.successGreen),
                        _buildSubStat('Lowest', '${sub.minPercentage}%', AppTheme.errorRed),
                        _buildSubStat('Students', '${sub.studentCount}', AppTheme.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 3. Rankings Leaderboard Tab
  Widget _buildRankingsTab(ReportProvider provider) {
    final rankings = provider.rankingsReport;
    if (rankings.isEmpty) {
      return const EmptyStateView(
        icon: Icons.leaderboard_rounded,
        title: 'No Rankings Available',
        message: 'Student rankings will be computed once exam marks are recorded.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAllReports(),
      color: AppTheme.indigoAccent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rankings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final r = rankings[i];
          Widget leadingWidget;

          if (r.rank == 1) {
            leadingWidget = const CircleAvatar(
              backgroundColor: Color(0xFFFEF3C7),
              child: Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 22),
            );
          } else if (r.rank == 2) {
            leadingWidget = const CircleAvatar(
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.workspace_premium_rounded, color: Color(0xFF64748B), size: 22),
            );
          } else if (r.rank == 3) {
            leadingWidget = const CircleAvatar(
              backgroundColor: Color(0xFFFFEDD5),
              child: Icon(Icons.military_tech_rounded, color: Color(0xFFC2410C), size: 22),
            );
          } else {
            leadingWidget = CircleAvatar(
              backgroundColor: AppTheme.scaffoldBg,
              child: Text('#${r.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyPrimary)),
            );
          }

          return Card(
            child: ListTile(
              leading: leadingWidget,
              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${r.studentId} • ${r.course} • Sem ${r.semester}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${r.avgPercentage}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.indigoAccent),
                  ),
                  const Text('Average', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. Defaulters Tab (<75% Alert)
  Widget _buildDefaultersTab(ReportProvider provider) {
    final defaulters = provider.defaultersReport;
    if (defaulters.isEmpty) {
      return const EmptyStateView(
        icon: Icons.verified_user_rounded,
        title: 'Zero Attendance Defaulters!',
        message: 'All registered students currently maintain >= 75% attendance.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAllReports(),
      color: AppTheme.indigoAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.errorBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${defaulters.length} students are below the mandatory 75% attendance requirement and require official notice.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ...defaulters.map((d) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.errorBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            'Shortfall: -${d.shortfall}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${d.studentId} • ${d.course} • Sem ${d.semester}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Current Rate: ${d.attendancePct}% (${d.totalClasses} sessions)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorRed),
                        ),
                      ],
                    ),
                    if (d.email.isNotEmpty || d.phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (d.email.isNotEmpty) ...[
                            const Icon(Icons.email_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(d.email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                          if (d.phone.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(d.phone, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWhiteStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
