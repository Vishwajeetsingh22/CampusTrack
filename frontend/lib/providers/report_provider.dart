import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceReportItem> _attendanceReport = [];
  List<SubjectAttendanceItem> _subjectAttendanceReport = [];
  List<SubjectPerformanceItem> _performanceSubjects = [];
  Map<String, dynamic> _performanceOverall = {};
  List<DefaulterStudentModel> _defaultersReport = [];
  List<StudentRankingModel> _rankingsReport = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<AttendanceReportItem> get attendanceReport => _attendanceReport;
  List<SubjectAttendanceItem> get subjectAttendanceReport => _subjectAttendanceReport;
  List<SubjectPerformanceItem> get performanceSubjects => _performanceSubjects;
  Map<String, dynamic> get performanceOverall => _performanceOverall;
  List<DefaulterStudentModel> get defaultersReport => _defaultersReport;
  List<StudentRankingModel> get rankingsReport => _rankingsReport;

  Future<void> loadAllReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _reportService.getAttendanceReport(),
        _reportService.getPerformanceReport(),
        _reportService.getLowAttendanceReport(),
        _reportService.getRankings(),
        _reportService.getSubjectAttendanceReport(),
      ]);

      _attendanceReport = futures[0] as List<AttendanceReportItem>;
      final perfData = futures[1] as Map<String, dynamic>;
      _performanceSubjects = perfData['subjects'] as List<SubjectPerformanceItem>;
      _performanceOverall = perfData['overall_summary'] as Map<String, dynamic>;
      _defaultersReport = futures[2] as List<DefaulterStudentModel>;
      _rankingsReport = futures[3] as List<StudentRankingModel>;
      _subjectAttendanceReport = futures[4] as List<SubjectAttendanceItem>;

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendanceReport({String? course, int? semester}) async {
    try {
      _attendanceReport = await _reportService.getAttendanceReport(course: course, semester: semester);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPerformanceReport({String? course, String? exam}) async {
    try {
      final perfData = await _reportService.getPerformanceReport(course: course, exam: exam);
      _performanceSubjects = perfData['subjects'] as List<SubjectPerformanceItem>;
      _performanceOverall = perfData['overall_summary'] as Map<String, dynamic>;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadDefaultersReport({double threshold = 75.0}) async {
    try {
      _defaultersReport = await _reportService.getLowAttendanceReport(threshold: threshold);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadRankings({String? course, int? semester}) async {
    try {
      _rankingsReport = await _reportService.getRankings(course: course, semester: semester);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
