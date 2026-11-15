import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/student_provider.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String? initialStudentId;

  const MarkAttendanceScreen({super.key, this.initialStudentId});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentId;
  DateTime _selectedDate = DateTime.now();
  String _selectedSubject = 'NoSQL Databases';
  String _selectedStatus = 'Present';
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _subjects = [
    'NoSQL Databases',
    'Cloud Computing',
    'Mobile Application Dev',
    'Operating Systems',
    'Computer Networks',
    'Software Engineering',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProv = Provider.of<StudentProvider>(context, listen: false);
      if (studentProv.students.isEmpty) {
        studentProv.loadStudents();
      } else if (_selectedStudentId == null && studentProv.students.isNotEmpty) {
        setState(() {
          _selectedStudentId = studentProv.students.first.studentId;
        });
      }
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.indigoAccent,
              onPrimary: Colors.white,
              onSurface: AppTheme.navyPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    final payload = {
      'student_id': _selectedStudentId!,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'subject': _selectedSubject,
      'status': _selectedStatus,
      'remarks': _remarksController.text.trim(),
    };

    final success = await provider.markAttendance(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance marked $_selectedStatus for $_selectedStudentId!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to record attendance.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = Provider.of<StudentProvider>(context).students;

    // Ensure _selectedStudentId is reliably set if students are available
    if (students.isNotEmpty) {
      final exists = students.any((s) => s.studentId == _selectedStudentId);
      if (!exists) {
        _selectedStudentId = widget.initialStudentId != null &&
                students.any((s) => s.studentId == widget.initialStudentId)
            ? widget.initialStudentId
            : students.first.studentId;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Selector
              const Text('STUDENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              if (students.isEmpty)
                TextFormField(
                  initialValue: _selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: 'Student Roll No / ID *',
                    hintText: 'e.g. STU1001',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (val) => _selectedStudentId = val.trim().toUpperCase(),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: 'Select Student *',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  items: students.map((s) {
                    return DropdownMenuItem(
                      value: s.studentId,
                      child: Text('${s.name} (${s.studentId})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStudentId = val);
                  },
                ),

              const SizedBox(height: 20),

              // Date Picker
              const Text('SESSION DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppTheme.indigoAccent, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navyPrimary),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subject Dropdown
              const Text('COURSE / SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),

              const SizedBox(height: 24),

              // Attendance Status Selector Pills
              const Text('ATTENDANCE STATUS *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Present',
                      value: 'Present',
                      color: AppTheme.successGreen,
                      bgColor: AppTheme.successBg,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Absent',
                      value: 'Absent',
                      color: AppTheme.errorRed,
                      bgColor: AppTheme.errorBg,
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusPill(
                      label: 'Late',
                      value: 'Late',
                      color: AppTheme.warningOrange,
                      bgColor: AppTheme.warningBg,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Optional Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Notes (Optional)',
                  hintText: 'e.g. On time, medical leave, transit delay...',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAttendance,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Record Attendance'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? Colors.white : color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
