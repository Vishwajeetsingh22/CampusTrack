import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/marks_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/marks_provider.dart';
import '../../providers/student_provider.dart';

class MarksFormScreen extends StatefulWidget {
  final MarksModel? marks;

  const MarksFormScreen({super.key, this.marks});

  @override
  State<MarksFormScreen> createState() => _MarksFormScreenState();
}

class _MarksFormScreenState extends State<MarksFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentId;
  String _selectedSubject = 'NoSQL Databases';
  String _selectedExam = 'Mid-Term';
  late TextEditingController _obtainedController;
  late TextEditingController _maxController;
  bool _isSubmitting = false;

  final List<String> _subjects = [
    'NoSQL Databases',
    'Cloud Computing',
    'Mobile Application Dev',
    'Operating Systems',
    'Computer Networks',
    'Software Engineering',
  ];

  final List<String> _exams = [
    'Mid-Term',
    'Final',
    'Assignment 1',
    'Assignment 2',
    'Quiz 1',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.marks;
    _selectedStudentId = m?.studentId;
    if (m != null) {
      if (_subjects.contains(m.subject)) _selectedSubject = m.subject;
      if (_exams.contains(m.exam)) _selectedExam = m.exam;
    }
    _obtainedController = TextEditingController(text: m != null ? m.marksObtained.toString() : '');
    _maxController = TextEditingController(text: m != null ? m.maxMarks.toString() : '100');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProv = Provider.of<StudentProvider>(context, listen: false);
      if (studentProv.students.isEmpty) {
        studentProv.loadStudents();
      } else if (_selectedStudentId == null && studentProv.students.isNotEmpty) {
        setState(() => _selectedStudentId = studentProv.students.first.studentId);
      }
    });
  }

  @override
  void dispose() {
    _obtainedController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.marks != null;

  double get _calculatedPercentage {
    final obt = double.tryParse(_obtainedController.text) ?? 0.0;
    final max = double.tryParse(_maxController.text) ?? 100.0;
    if (max <= 0) return 0.0;
    final pct = (obt / max) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  Future<void> _submitMarks() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<MarksProvider>(context, listen: false);

    final obt = double.parse(_obtainedController.text.trim());
    final max = double.parse(_maxController.text.trim());

    bool success;
    if (_isEditMode && widget.marks?.id != null) {
      final updateData = {
        'marks_obtained': obt,
        'max_marks': max,
        'subject': _selectedSubject,
        'exam': _selectedExam,
      };
      success = await provider.updateMarks(widget.marks!.id!, updateData);
    } else {
      final payload = {
        'student_id': _selectedStudentId!,
        'subject': _selectedSubject,
        'exam': _selectedExam,
        'marks_obtained': obt,
        'max_marks': max,
      };
      success = await provider.recordMarks(payload);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Exam marks updated!' : 'Exam marks recorded successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to record marks.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = Provider.of<StudentProvider>(context).students;
    final pct = _calculatedPercentage;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Exam Marks' : 'Record Exam Marks'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Selection
              const Text('STUDENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              if (_isEditMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.marks!.studentName ?? widget.marks!.studentId} (${widget.marks!.studentId})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else if (students.isEmpty)
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
                  initialValue: _selectedStudentId ?? (students.isNotEmpty ? students.first.studentId : null),
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

              // Subject & Exam
              const Text('ASSESSMENT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
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
              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                initialValue: _selectedExam,
                decoration: const InputDecoration(
                  labelText: 'Exam / Assessment Type *',
                  prefixIcon: Icon(Icons.assignment_rounded),
                ),
                items: _exams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedExam = val);
                },
              ),

              const SizedBox(height: 20),

              // Scores Input
              const Text('MARKS EVALUATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _obtainedController,
                      decoration: const InputDecoration(
                        labelText: 'Marks Obtained *',
                        hintText: 'e.g. 85',
                        prefixIcon: Icon(Icons.grade_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null) return 'Invalid number';
                        if (numVal < 0) return 'Cannot be negative';
                        final maxVal = double.tryParse(_maxController.text.trim()) ?? 100;
                        if (numVal > maxVal) return 'Exceeds maximum';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Marks *',
                        hintText: 'e.g. 100',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null) return 'Invalid number';
                        if (numVal <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Dynamic Percentage Preview Card
              Card(
                color: pct >= 75 ? AppTheme.successBg : (pct >= 50 ? AppTheme.indigoSoftBg : AppTheme.errorBg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calculated Percentage',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navyPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pct >= 75 ? 'First Class with Distinction' : (pct >= 50 ? 'Second Class' : 'Remedial / Low Score'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: pct >= 75 ? AppTheme.successGreen : (pct >= 50 ? AppTheme.indigoAccent : AppTheme.errorRed),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: pct >= 75 ? AppTheme.successGreen : (pct >= 50 ? AppTheme.indigoAccent : AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMarks,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditMode ? 'Update Marks' : 'Save Exam Marks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
