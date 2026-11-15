import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceModel> _records = [];
  AttendanceSummaryModel? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _selectedDate;
  String _selectedSubject = 'All';
  String _selectedStatus = 'All';
  String? _selectedStudentId;

  List<AttendanceModel> get records => _records;
  AttendanceSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedDate => _selectedDate;
  String get selectedSubject => _selectedSubject;
  String get selectedStatus => _selectedStatus;
  String? get selectedStudentId => _selectedStudentId;

  Future<void> loadAttendance({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.getAttendanceRecords(
        studentId: _selectedStudentId,
        date: _selectedDate,
        subject: _selectedSubject != 'All' ? _selectedSubject : null,
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );
      _records = result['records'] as List<AttendanceModel>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummary({String? studentId}) async {
    try {
      _summary = await _attendanceService.getAttendanceSummary(studentId: studentId);
      notifyListeners();
    } catch (e) {
      // Keep previous summary if error
    }
  }

  void setDateFilter(String? date) {
    _selectedDate = date;
    loadAttendance(refresh: true);
  }

  void setSubjectFilter(String subject) {
    _selectedSubject = subject;
    loadAttendance(refresh: true);
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    loadAttendance(refresh: true);
  }

  void setStudentIdFilter(String? studentId) {
    _selectedStudentId = studentId;
    loadAttendance(refresh: true);
  }

  void resetFilters() {
    _selectedDate = null;
    _selectedSubject = 'All';
    _selectedStatus = 'All';
    _selectedStudentId = null;
    loadAttendance(refresh: true);
  }

  Future<bool> markAttendance(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _attendanceService.recordAttendance(data);
      _records.insert(0, created);
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

  Future<bool> createAttendance(Map<String, dynamic> data) => markAttendance(data);

  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _attendanceService.updateAttendance(id, data);
      final idx = _records.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _records[idx] = updated;
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

  Future<bool> deleteAttendance(String id) async {
    try {
      await _attendanceService.deleteAttendance(id);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
