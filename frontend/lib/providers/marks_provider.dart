import 'package:flutter/material.dart';
import '../models/marks_model.dart';
import '../services/marks_service.dart';

class MarksProvider extends ChangeNotifier {
  final MarksService _marksService = MarksService();

  List<MarksModel> _records = [];
  MarksSummaryModel? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String _selectedSubject = 'All';
  String _selectedExam = 'All';
  String? _selectedStudentId;

  List<MarksModel> get records => _records;
  MarksSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedSubject => _selectedSubject;
  String get selectedExam => _selectedExam;
  String? get selectedStudentId => _selectedStudentId;

  Future<void> loadMarks({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _marksService.getMarks(
        studentId: _selectedStudentId,
        subject: _selectedSubject != 'All' ? _selectedSubject : null,
        exam: _selectedExam != 'All' ? _selectedExam : null,
      );
      _records = result['records'] as List<MarksModel>;
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
      _summary = await _marksService.getMarksSummary(studentId: studentId);
      notifyListeners();
    } catch (e) {
      // Keep previous summary if error
    }
  }

  void setSubjectFilter(String subject) {
    _selectedSubject = subject;
    loadMarks(refresh: true);
  }

  void setExamFilter(String exam) {
    _selectedExam = exam;
    loadMarks(refresh: true);
  }

  void setStudentIdFilter(String? studentId) {
    _selectedStudentId = studentId;
    loadMarks(refresh: true);
  }

  void resetFilters() {
    _selectedSubject = 'All';
    _selectedExam = 'All';
    _selectedStudentId = null;
    loadMarks(refresh: true);
  }

  Future<bool> recordMarks(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _marksService.recordMarks(data);
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

  Future<bool> updateMarks(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _marksService.updateMarks(id, data);
      final idx = _records.indexWhere((m) => m.id == id);
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

  Future<bool> deleteMarks(String id) async {
    try {
      await _marksService.deleteMarks(id);
      _records.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
