import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _studentService = StudentService();

  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalCount = 0;

  // Filters
  String _searchQuery = '';
  String _selectedCourse = 'All';
  int? _selectedSemester;
  bool? _selectedActive;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;
  String get selectedCourse => _selectedCourse;
  int? get selectedSemester => _selectedSemester;
  bool? get selectedActive => _selectedActive;

  Future<void> loadStudents({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _studentService.getStudents(
        search: _searchQuery,
        course: _selectedCourse != 'All' ? _selectedCourse : null,
        semester: _selectedSemester,
        active: _selectedActive,
      );
      _students = result['students'] as List<StudentModel>;
      _totalCount = result['total'] as int? ?? _students.length;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadStudents(refresh: true);
  }

  void setCourseFilter(String course) {
    _selectedCourse = course;
    loadStudents(refresh: true);
  }

  void setSemesterFilter(int? semester) {
    _selectedSemester = semester;
    loadStudents(refresh: true);
  }

  void setActiveFilter(bool? active) {
    _selectedActive = active;
    loadStudents(refresh: true);
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCourse = 'All';
    _selectedSemester = null;
    _selectedActive = null;
    loadStudents(refresh: true);
  }

  Future<bool> createStudent(StudentModel student) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _studentService.createStudent(student);
      _students.insert(0, created);
      _totalCount += 1;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(String identifier, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _studentService.updateStudent(identifier, data);
      final idx = _students.indexWhere((s) => s.studentId == identifier || s.id == identifier);
      if (idx != -1) {
        _students[idx] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String identifier) async {
    try {
      await _studentService.deleteStudent(identifier);
      _students.removeWhere((s) => s.studentId == identifier || s.id == identifier);
      _totalCount = (_totalCount > 0) ? _totalCount - 1 : 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
