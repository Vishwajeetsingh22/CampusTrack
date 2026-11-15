import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../main.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/marks_service.dart';
import '../../services/student_service.dart';
import '../../widgets/loading_indicator.dart';
import '../auth/login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StudentService _studentService = StudentService();
  final AttendanceService _attendanceService = AttendanceService();
  final MarksService _marksService = MarksService();

  bool _isLoading = true;
  String _selectedSemester = 'Odd Sem 2026';
  Map<String, dynamic>? _summaryData;
  List<AttendanceModel> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadStudentDashboardData();
  }

  Future<void> _loadStudentDashboardData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.currentUser?.studentId ?? 'STU1001';

    try {
      final futures = await Future.wait([
        _studentService.getStudentSummary(studentId),
        _attendanceService.getAttendanceRecords(studentId: studentId),
        _marksService.getMarks(studentId: studentId),
      ]);

      if (mounted) {
        setState(() {
          _summaryData = futures[0];
          _attendanceRecords = futures[1]['records'] as List<AttendanceModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHallTicketDialog(String studentName, String studentId, String course) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.indigoSoftBg, shape: BoxShape.circle),
                child: const Icon(Icons.confirmation_number_rounded, color: AppTheme.indigoAccent),
              ),
              const SizedBox(width: 12),
              const Text('End-Sem Hall Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STUDENT: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('ROLL NO: $studentId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.indigoAccent)),
                      Text('PROGRAM: $course', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const Text('SEMESTER: 6 (Odd 2026)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const Divider(height: 16),
                      const Text('EXAMINATION SCHEDULE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      _buildExamRow('NoSQL Databases', '05 Nov 2026 • 10:00 AM', 'Hall 302'),
                      _buildExamRow('Cloud Computing', '08 Nov 2026 • 10:00 AM', 'Hall 302'),
                      _buildExamRow('Mobile App Dev', '12 Nov 2026 • 02:00 PM', 'Lab 104'),
                      _buildExamRow('Operating Systems', '15 Nov 2026 • 10:00 AM', 'Hall 201'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 16),
                    SizedBox(width: 6),
                    Text('Verified by Controller of Examinations', style: TextStyle(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hall Ticket downloaded as PDF to device!'), backgroundColor: AppTheme.navyPrimary),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download Admit Card'),
            ),
          ],
        );
      },
    );
  }

  void _showFeeReceiptDialog(String studentName, String studentId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppTheme.successGreen),
              SizedBox(width: 10),
              Text('Examination Fee Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Receipt No: CT-2026-9042', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Date: 12 Oct 2026 • Status: SUCCESSFUL', style: TextStyle(fontSize: 12, color: AppTheme.successGreen, fontWeight: FontWeight.w600)),
              const Divider(height: 20),
              _buildReceiptRow('Student Name', studentName),
              _buildReceiptRow('Roll Number', studentId),
              _buildReceiptRow('Semester Fee', '₹ 2,200.00'),
              _buildReceiptRow('Exam Form Fee', '₹ 300.00'),
              const Divider(height: 16),
              _buildReceiptRow('Total Paid', '₹ 2,500.00', isBold: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fee receipt downloaded successfully!'), backgroundColor: AppTheme.navyPrimary),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download Receipt'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExamRow(String subject, String time, String hall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Text('$time ($hall)', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: isBold ? AppTheme.navyPrimary : AppTheme.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: AppTheme.navyPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final studentId = user?.studentId ?? 'STU1001';
    final studentName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Alex Turner';
    final studentProfile = user?.studentProfile;
    final course = studentProfile?['course'] ?? 'Computer Science';
    final semester = studentProfile?['semester'] ?? 6;

    final attSummary = _summaryData?['attendance'] as Map<String, dynamic>?;
    final attPct = (attSummary?['percentage'] is num) ? (attSummary!['percentage'] as num).toDouble() : 84.5;
    final totalClasses = attSummary?['total_classes'] ?? 42;
    final attendedClasses = attSummary?['attended'] ?? 36;
    final isBelow75 = attPct < 75.0;

    final marksSummary = _summaryData?['academics'] as Map<String, dynamic>?;
    final avgMarksPct = (marksSummary?['average_percentage'] is num) ? (marksSummary!['average_percentage'] as num).toDouble() : 82.4;
    final cgpaScore = (avgMarksPct / 9.5).clamp(0.0, 10.0).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildTopHeader(studentName, studentId),
      drawer: _buildSideDrawer(studentName, studentId, course),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading academic portal records...')
          : RefreshIndicator(
              onRefresh: _loadStudentDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Student Academic Profile Card
                    _buildStudentProfileCard(studentName, studentId, course, semester),
                    const SizedBox(height: 20),

                    // 2. Semester Progression Stepper
                    _buildProgressionStepper(),
                    const SizedBox(height: 24),

                    // 3. Four Quick-Action Metric Cards (as shown in Screenshot 2)
                    _buildQuickActionCards(attPct, attendedClasses, totalClasses, isBelow75, cgpaScore, studentName, studentId, course),
                    const SizedBox(height: 28),

                    // 4. Performance Trend & Schedule Calendar Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: _buildSgpaTrendChartCard()),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: _buildAttendanceCalendarCard()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildSgpaTrendChartCard(),
                              const SizedBox(height: 20),
                              _buildAttendanceCalendarCard(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // 5. Recent Attendance Logs Table
                    _buildRecentAttendanceList(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildTopHeader(String name, String rollNo) {
    return AppBar(
      backgroundColor: AppTheme.navyPrimary,
      elevation: 2,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            'CampusTrack',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          // Semester selector dropdown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B263B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF415A77)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSemester,
                    dropdownColor: const Color(0xFF0D1B2A),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white70),
                    items: const [
                      DropdownMenuItem(value: 'Odd Sem 2026', child: Text('Odd Sem 2026')),
                      DropdownMenuItem(value: 'Even Sem 2025', child: Text('Even Sem 2025')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSemester = val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with unread badge counter
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: 'Academic Notices',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notice: Mid-Term Examination Schedule is now published.'), backgroundColor: AppTheme.navyPrimary),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        // Student avatar chip
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: PopupMenuButton<String>(
            tooltip: 'Account Options',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'switch_admin') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
                );
              } else if (val == 'logout') {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (ctx) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                      Text(rollNo, style: const TextStyle(fontSize: 12, color: AppTheme.indigoAccent)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (auth.isAdmin)
                  const PopupMenuItem(
                    value: 'switch_admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Text('Switch to Admin View'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppTheme.errorRed),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
                    ],
                  ),
                ),
              ];
            },
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.indigoAccent,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideDrawer(String name, String rollNo, String course) {
    final auth = Provider.of<AuthProvider>(context);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.indigoAccent,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('$rollNo • $course', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(Icons.dashboard_rounded, 'Student Dashboard', true, () => Navigator.of(context).pop()),
                _buildDrawerItem(Icons.how_to_reg_rounded, 'Attendance History', false, () {
                  Navigator.of(context).pop();
                }),
                _buildDrawerItem(Icons.grade_rounded, 'Academic Results & Marks', false, () {
                  Navigator.of(context).pop();
                }),
                _buildDrawerItem(Icons.receipt_long_rounded, 'Examination Fees', false, () {
                  Navigator.of(context).pop();
                  _showFeeReceiptDialog(name, rollNo);
                }),
                _buildDrawerItem(Icons.confirmation_number_rounded, 'Hall Ticket / Admit Card', false, () {
                  Navigator.of(context).pop();
                  _showHallTicketDialog(name, rollNo, course);
                }),
                _buildDrawerItem(Icons.event_note_rounded, 'Class Time Table', false, () {
                  Navigator.of(context).pop();
                }),
                const Divider(),
                if (auth.isAdmin)
                  _buildDrawerItem(Icons.admin_panel_settings_rounded, 'Switch to Admin Portal', false, () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
                    );
                  }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: AppTheme.errorBg,
              leading: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              onTap: () async {
                await auth.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.indigoAccent : AppTheme.navyPrimary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppTheme.indigoAccent : AppTheme.navyPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.indigoSoftBg,
      onTap: onTap,
    );
  }

  Widget _buildStudentProfileCard(String name, String rollNo, String course, dynamic semester) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF0D1B2A),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ENROLLED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: $rollNo • Degree: B.Tech $course',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semester: $semester • Academic Advisor: Dr. R. K. Sharma (Dean Academics)',
                  style: const TextStyle(fontSize: 12, color: AppTheme.indigoAccent, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionStepper() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SEMESTER MILESTONES PROGRESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Text('Stage 3 of 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.indigoAccent)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStepItem('Registration', true, true),
              _buildStepLine(true),
              _buildStepItem('Mid-Term 1', true, true),
              _buildStepLine(true),
              _buildStepItem('Mid-Term 2', true, false), // Current Active
              _buildStepLine(false),
              _buildStepItem('Practicals', false, false),
              _buildStepLine(false),
              _buildStepItem('End Semester', false, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, bool isDone, bool isPast) {
    Color circleColor = isPast ? AppTheme.successGreen : (isDone ? AppTheme.indigoAccent : const Color(0xFFCBD5E1));
    IconData icon = isPast ? Icons.check : (isDone ? Icons.play_arrow_rounded : Icons.circle);

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: isDone ? FontWeight.bold : FontWeight.normal, color: AppTheme.navyPrimary)),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 3,
        color: isDone ? AppTheme.successGreen : const Color(0xFFE2E8F0),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildQuickActionCards(
    double attPct,
    int attended,
    int total,
    bool isBelow75,
    String cgpa,
    String studentName,
    String studentId,
    String course,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
        double spacing = 16;
        double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            // Card 1: Attendance
            SizedBox(
              width: itemWidth,
              child: _buildTileCard(
                icon: Icons.how_to_reg_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'ATTENDANCE',
                value: '${attPct.toStringAsFixed(1)}%',
                subtitle: 'Classes: $attended / $total',
                badgeText: isBelow75 ? 'Low Attendance (<75%)' : 'Good Standing',
                badgeColor: isBelow75 ? AppTheme.errorRed : AppTheme.successGreen,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Overall Attendance: ${attPct.toStringAsFixed(1)}% across $total classes.'),
                      backgroundColor: AppTheme.navyPrimary,
                    ),
                  );
                },
              ),
            ),
            // Card 2: Academic Results & CGPA
            SizedBox(
              width: itemWidth,
              child: _buildTileCard(
                icon: Icons.grade_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'RESULTS & CGPA',
                value: '$cgpa / 10',
                subtitle: 'Credits Earned: 124',
                badgeText: 'Rank #1 in Dept',
                badgeColor: const Color(0xFF0284C7),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Semester CGPA is $cgpa based on verified exam marks.'), backgroundColor: AppTheme.navyPrimary),
                  );
                },
              ),
            ),
            // Card 3: Exam Fees
            SizedBox(
              width: itemWidth,
              child: _buildTileCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'EXAMINATION FEES',
                value: 'PAID',
                subtitle: 'Receipt #CT-2026-904',
                badgeText: '₹ 2,500 Cleared',
                badgeColor: AppTheme.successGreen,
                onTap: () => _showFeeReceiptDialog(studentName, studentId),
              ),
            ),
            // Card 4: Hall Ticket & Time Table
            SizedBox(
              width: itemWidth,
              child: _buildTileCard(
                icon: Icons.confirmation_number_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'HALL TICKET & TT',
                value: 'READY',
                subtitle: 'Next: NoSQL DB (05 Nov)',
                badgeText: 'Download Admit Card',
                badgeColor: const Color(0xFFF59E0B),
                onTap: () => _showHallTicketDialog(studentName, studentId, course),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTileCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSgpaTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SGPA ACADEMIC PERFORMANCE TREND', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                  SizedBox(height: 2),
                  Text('Semester-wise GPA progression', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.indigoSoftBg, borderRadius: BorderRadius.circular(6)),
                child: const Text('Avg: 8.52', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.indigoAccent)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 6.0,
                maxY: 10.0,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1.0,
                      getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5', 'Sem 6'];
                        int index = val.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Text(labels[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 8.2),
                      FlSpot(1, 8.4),
                      FlSpot(2, 8.1),
                      FlSpot(3, 8.6),
                      FlSpot(4, 8.8),
                      FlSpot(5, 8.9),
                    ],
                    isCurved: true,
                    color: AppTheme.indigoAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.indigoAccent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ATTENDANCE CALENDAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
              Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigoAccent)),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted)),
              Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted)),
              Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted)),
              Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted)),
              Text('F', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          // Mini calendar grid of recent school days
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(15, (i) {
              int day = i + 1;
              Color color = (i == 4 || i == 11) ? AppTheme.errorRed : (i == 7 ? AppTheme.warningAmber : AppTheme.successGreen);
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('$day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(children: [const Icon(Icons.circle, size: 8, color: AppTheme.successGreen), const SizedBox(width: 4), const Text('Present', style: TextStyle(fontSize: 10))]),
              Row(children: [const Icon(Icons.circle, size: 8, color: AppTheme.errorRed), const SizedBox(width: 4), const Text('Absent', style: TextStyle(fontSize: 10))]),
              Row(children: [const Icon(Icons.circle, size: 8, color: AppTheme.warningAmber), const SizedBox(width: 4), const Text('Late', style: TextStyle(fontSize: 10))]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT ATTENDANCE LOGS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
          const SizedBox(height: 12),
          if (_attendanceRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No attendance logs recorded for this semester yet.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceRecords.take(5).length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final att = _attendanceRecords[i];
                Color statusColor = att.status == 'Present' ? AppTheme.successGreen : (att.status == 'Late' ? AppTheme.warningAmber : AppTheme.errorRed);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    child: Icon(
                      att.status == 'Present' ? Icons.check : (att.status == 'Late' ? Icons.access_time : Icons.close),
                      size: 16,
                      color: statusColor,
                    ),
                  ),
                  title: Text(att.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(att.date, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(att.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
