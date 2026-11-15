import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/marks_model.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/marks_service.dart';
import '../../services/student_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_indicator.dart';
import '../attendance/mark_attendance_screen.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentService _studentService = StudentService();
  final AttendanceService _attendanceService = AttendanceService();
  final MarksService _marksService = MarksService();

  late StudentModel _student;
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<AttendanceModel> _attendanceRecords = [];
  List<MarksModel> _marksRecords = [];

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _tabController = TabController(length: 2, vsync: this);
    _loadStudentDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentDetails() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _studentService.getStudentSummary(_student.studentId),
        _attendanceService.getAttendanceRecords(studentId: _student.studentId),
        _marksService.getMarks(studentId: _student.studentId),
      ]);

      if (mounted) {
        setState(() {
          _summary = futures[0];
          _attendanceRecords = futures[1]['records'] as List<AttendanceModel>;
          _marksRecords = futures[2]['records'] as List<MarksModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attData = _summary?['attendance'] as Map<String, dynamic>?;
    final marksData = _summary?['academics'] as Map<String, dynamic>?;

    final attPct = (attData?['percentage'] is num) ? (attData!['percentage'] as num).toDouble() : 0.0;
    final isDefaulter = attPct < 75.0 && (attData?['total_classes'] ?? 0) > 0;
    final avgMarks = (marksData?['average_percentage'] is num) ? (marksData!['average_percentage'] as num).toDouble() : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_rounded, color: AppTheme.successGreen),
            tooltip: 'Mark Attendance',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => MarkAttendanceScreen(initialStudentId: _student.studentId),
                ),
              );
              _loadStudentDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => StudentFormScreen(student: _student),
                ),
              );
              _loadStudentDetails();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading student academic records...')
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profile Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundColor: AppTheme.indigoAccent,
                                        child: Text(
                                          _student.name.isNotEmpty ? _student.name[0].toUpperCase() : 'S',
                                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _student.name,
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: _student.active ? AppTheme.successBg : AppTheme.errorBg,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: _student.active ? AppTheme.successGreen : AppTheme.errorRed),
                                                  ),
                                                  child: Text(
                                                    _student.active ? 'ACTIVE' : 'INACTIVE',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _student.active ? AppTheme.successGreen : AppTheme.errorRed,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_student.studentId} • ${_student.course} • Sem ${_student.semester}',
                                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.email_outlined, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(_student.email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Divider(),
                                  const SizedBox(height: 10),

                                  // KPI Mini-Cards
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMiniStat(
                                          title: 'ATTENDANCE',
                                          value: '$attPct%',
                                          subtitle: isDefaulter ? 'DEFICIT (<75%)' : 'REGULAR',
                                          color: isDefaulter ? AppTheme.errorRed : AppTheme.successGreen,
                                          bgColor: isDefaulter ? AppTheme.errorBg : AppTheme.successBg,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildMiniStat(
                                          title: 'AVG SCORE',
                                          value: '$avgMarks%',
                                          subtitle: '${marksData?['total_assessments'] ?? 0} Exams Taken',
                                          color: const Color(0xFF0284C7),
                                          bgColor: const Color(0xFFF0F9FF),
                                        ),
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
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.indigoAccent,
                        labelColor: AppTheme.indigoAccent,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: [
                          Tab(text: 'Attendance (${_attendanceRecords.length})'),
                          Tab(text: 'Exam Marks (${_marksRecords.length})'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Attendance Tab
                  _attendanceRecords.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.fact_check_outlined,
                          title: 'No Attendance Records',
                          message: 'No attendance logs have been recorded for this student yet.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, idx) {
                            final item = _attendanceRecords[idx];
                            Color statusColor = AppTheme.successGreen;
                            if (item.status == 'Absent') statusColor = AppTheme.errorRed;
                            if (item.status == 'Late') statusColor = AppTheme.warningOrange;

                            return Card(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.calendar_today_rounded, size: 18, color: statusColor),
                                ),
                                title: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  '${item.date}${item.remarks != null && item.remarks!.isNotEmpty ? ' • ${item.remarks}' : ''}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                  // Marks Tab
                  _marksRecords.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.grade_outlined,
                          title: 'No Examination Records',
                          message: 'No exam marks have been submitted for this student yet.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _marksRecords.length,
                          itemBuilder: (context, idx) {
                            final m = _marksRecords[idx];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(m.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text('${m.exam} Assessment', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${m.marksObtained.toStringAsFixed(1)} / ${m.maxMarks.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.navyPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${m.percentage}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: m.percentage >= 75 ? AppTheme.successGreen : (m.percentage >= 50 ? AppTheme.indigoAccent : AppTheme.errorRed),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surfaceWhite,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
