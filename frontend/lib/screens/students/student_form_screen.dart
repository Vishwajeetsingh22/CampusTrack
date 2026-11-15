import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/student_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/student_provider.dart';

class StudentFormScreen extends StatefulWidget {
  final StudentModel? student;

  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String _selectedCourse = 'Computer Science';
  int _selectedSemester = 6;
  bool _isActive = true;
  bool _isSubmitting = false;

  final List<String> _courseOptions = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical Engineering',
    'Civil Engineering',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _idController = TextEditingController(text: s?.studentId ?? '');
    _nameController = TextEditingController(text: s?.name ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');

    if (s != null) {
      if (_courseOptions.contains(s.course)) {
        _selectedCourse = s.course;
      }
      _selectedSemester = s.semester;
      _isActive = s.active;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.student != null;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final provider = Provider.of<StudentProvider>(context, listen: false);

    bool success;
    if (_isEditMode) {
      final updateData = {
        'name': _nameController.text.trim(),
        'course': _selectedCourse,
        'department': _selectedCourse,
        'semester': _selectedSemester,
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'active': _isActive,
      };
      success = await provider.updateStudent(widget.student!.studentId, updateData);
    } else {
      final newStudent = StudentModel(
        studentId: _idController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        course: _selectedCourse,
        department: _selectedCourse,
        semester: _selectedSemester,
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        active: _isActive,
      );
      success = await provider.createStudent(newStudent);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard(refresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Student profile updated!' : 'Student registered successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save student.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Student Profile' : 'Register New Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roll Number (student_id)
              const Text('STUDENT IDENTIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idController,
                enabled: !_isEditMode,
                decoration: InputDecoration(
                  labelText: 'Student Roll No / ID *',
                  hintText: 'e.g. STU1015 or CS202601',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  filled: _isEditMode,
                  fillColor: _isEditMode ? AppTheme.scaffoldBg : AppTheme.surfaceWhite,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Student ID is required.';
                  }
                  if (val.trim().length < 3 || val.trim().length > 20) {
                    return 'Must be between 3 and 20 alphanumeric characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Aarav Sharma',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Full name must be at least 2 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Course & Semester
              const Text('ACADEMIC PROGRAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCourse,
                decoration: const InputDecoration(
                  labelText: 'Degree / Course *',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                items: _courseOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCourse = val);
                },
              ),
              const SizedBox(height: 18),

              DropdownButtonFormField<int>(
                initialValue: _selectedSemester,
                decoration: const InputDecoration(
                  labelText: 'Semester *',
                  prefixIcon: Icon(Icons.calendar_view_day_rounded),
                ),
                items: List.generate(8, (i) => i + 1)
                    .map((sem) => DropdownMenuItem(value: sem, child: Text('Semester $sem')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSemester = val);
                },
              ),
              const SizedBox(height: 18),

              // Contact Information
              const Text('CONTACT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'e.g. student@college.edu',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || !RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$").hasMatch(val.trim())) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number (Optional)',
                  hintText: 'e.g. +91-9876543210',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),

              // Active enrollment toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Enrolled & Active Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    _isActive ? 'Student is currently active in attendance & exams' : 'Student is marked inactive',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  value: _isActive,
                  activeThumbColor: AppTheme.indigoAccent,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditMode ? 'Save Changes' : 'Register Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
