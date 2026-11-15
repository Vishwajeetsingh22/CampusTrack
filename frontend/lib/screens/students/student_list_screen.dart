import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/student_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/loading_indicator.dart';
import 'student_detail_screen.dart';
import 'student_form_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _courses = [
    'All',
    'Computer Science',
    'Information Technology',
    'Electronics',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: AppTheme.surfaceWhite,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by student name, roll no, or email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) => provider.setSearchQuery(val),
                    ),
                    const SizedBox(height: 10),

                    // Course Filter Chips
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _courses.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final c = _courses[i];
                          final isSelected = provider.selectedCourse == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: isSelected,
                            selectedColor: AppTheme.indigoSoftBg,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.indigoAccent : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) provider.setCourseFilter(c);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content List
              Expanded(
                child: _buildContent(context, provider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const StudentFormScreen()),
              );
            },
            backgroundColor: AppTheme.indigoAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Student'),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, StudentProvider provider) {
    if (provider.isLoading && provider.students.isEmpty) {
      return const LoadingIndicator(message: 'Loading registered students...');
    }

    if (provider.errorMessage != null && provider.students.isEmpty) {
      return ErrorStateView(
        message: provider.errorMessage!,
        onRetry: () => provider.loadStudents(refresh: true),
      );
    }

    if (provider.students.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline_rounded,
        title: 'No Students Found',
        message: provider.searchQuery.isNotEmpty
            ? 'No student matches "${provider.searchQuery}". Try adjusting your search query.'
            : 'No students have been enrolled in the database yet.',
        actionLabel: 'Enroll First Student',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const StudentFormScreen()),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadStudents(refresh: true),
      color: AppTheme.indigoAccent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: provider.students.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final student = provider.students[index];
          return _buildStudentCard(context, student, provider);
        },
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student, StudentProvider provider) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => StudentDetailScreen(student: student),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.indigoSoftBg,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.indigoAccent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navyPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: student.active ? AppTheme.successBg : AppTheme.errorBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            student.active ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: student.active ? AppTheme.successGreen : AppTheme.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Text(
                            student.studentId,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navyPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${student.course} • Sem ${student.semester}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.how_to_reg_rounded, size: 22, color: AppTheme.successGreen),
                tooltip: 'Quick Mark Attendance',
                onPressed: () => _showQuickMarkAttendanceSheet(context, student),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) async {
                  if (val == 'attendance') {
                    _showQuickMarkAttendanceSheet(context, student);
                  } else if (val == 'view') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => StudentDetailScreen(student: student)),
                    );
                  } else if (val == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => StudentFormScreen(student: student)),
                    );
                  } else if (val == 'delete') {
                    final confirm = await ConfirmDialog.show(
                      context: context,
                      title: 'Delete Student?',
                      content: 'Are you sure you want to remove "${student.name}" (${student.studentId})?\n\nThis will safely cascade-delete all related attendance logs and examination marks to prevent broken database references.',
                    );
                    if (confirm) {
                      final ok = await provider.deleteStudent(student.studentId);
                      if (context.mounted) {
                        if (ok) {
                          Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Student deleted successfully.' : (provider.errorMessage ?? 'Delete failed.')),
                            backgroundColor: ok ? AppTheme.navyPrimary : AppTheme.errorRed,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'attendance',
                    child: Row(
                      children: [
                        Icon(Icons.how_to_reg_rounded, size: 18, color: AppTheme.successGreen),
                        SizedBox(width: 8),
                        Text('Mark Attendance'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 18, color: AppTheme.indigoAccent),
                        SizedBox(width: 8),
                        Text('View Academic 360°'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Text('Edit Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorRed),
                        SizedBox(width: 8),
                        Text('Delete Student', style: TextStyle(color: AppTheme.errorRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickMarkAttendanceSheet(BuildContext context, StudentModel student) {
    DateTime selectedDate = DateTime.now();
    String selectedSubject = 'NoSQL Databases';
    String selectedStatus = 'Present';
    final remarksController = TextEditingController();
    bool isSaving = false;

    final subjects = [
      'NoSQL Databases',
      'Cloud Computing',
      'Mobile Application Dev',
      'Operating Systems',
      'Computer Networks',
      'Software Engineering',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mark Student Attendance',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${student.name} • ${student.studentId}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.indigoAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Subject Selector
                    const Text('SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(),
                      ),
                      items: subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedSubject = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    const Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.cardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('EEE, dd MMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.indigoAccent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Chips
                    const Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip('Present', AppTheme.successGreen, selectedStatus == 'Present', () {
                          setSheetState(() => selectedStatus = 'Present');
                        }),
                        const SizedBox(width: 10),
                        _buildStatusChip('Absent', AppTheme.errorRed, selectedStatus == 'Absent', () {
                          setSheetState(() => selectedStatus = 'Absent');
                        }),
                        const SizedBox(width: 10),
                        _buildStatusChip('Late', AppTheme.warningAmber, selectedStatus == 'Late', () {
                          setSheetState(() => selectedStatus = 'Late');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Remarks
                    const Text('OPTIONAL REMARKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Approved medical leave or on time',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                final attProv = Provider.of<AttendanceProvider>(context, listen: false);
                                final payload = {
                                  'student_id': student.studentId,
                                  'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                                  'subject': selectedSubject,
                                  'status': selectedStatus,
                                  'remarks': remarksController.text.trim(),
                                };

                                final success = await attProv.createAttendance(payload);
                                if (context.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                  if (success) {
                                    Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Attendance recorded for ${student.name} (${student.studentId})!'),
                                        backgroundColor: AppTheme.navyPrimary,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(attProv.errorMessage ?? 'Failed to record attendance.'),
                                        backgroundColor: AppTheme.errorRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Record Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String label, Color color, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
