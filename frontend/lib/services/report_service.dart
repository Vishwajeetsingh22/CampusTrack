import '../config/api_config.dart';
import '../models/report_models.dart';
import 'api_service.dart';

class ReportService {
  Future<DashboardStatsModel> getDashboardStats() async {
    final response = await ApiService.get(ApiConfig.dashboard);
    return DashboardStatsModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<AttendanceReportItem>> getAttendanceReport({String? course, int? semester}) async {
    final queryParams = <String, String>{};
    if (course != null && course.isNotEmpty && course != 'All') {
      queryParams['course'] = course;
    }
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }

    final uri = Uri.parse(ApiConfig.reportAttendance).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());
    final rawList = response['data'] as List? ?? [];
    return rawList.map((e) => AttendanceReportItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getPerformanceReport({String? course, String? exam}) async {
    final queryParams = <String, String>{};
    if (course != null && course.isNotEmpty && course != 'All') {
      queryParams['course'] = course;
    }
    if (exam != null && exam.isNotEmpty && exam != 'All') {
      queryParams['exam'] = exam;
    }

    final uri = Uri.parse(ApiConfig.reportPerformance).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());
    final data = response['data'] as Map<String, dynamic>? ?? {};

    final rawSubjects = data['subjects'] as List? ?? [];
    final subjects = rawSubjects.map((e) => SubjectPerformanceItem.fromJson(e as Map<String, dynamic>)).toList();
    final overallSummary = data['overall_summary'] as Map<String, dynamic>? ?? {};

    return {
      'subjects': subjects,
      'overall_summary': overallSummary,
    };
  }

  Future<List<DefaulterStudentModel>> getLowAttendanceReport({double threshold = 75.0}) async {
    final uri = Uri.parse(ApiConfig.reportLowAttendance).replace(
      queryParameters: {'threshold': threshold.toString()},
    );
    final response = await ApiService.get(uri.toString());
    final rawList = response['data'] as List? ?? [];
    return rawList.map((e) => DefaulterStudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StudentRankingModel>> getRankings({String? course, int? semester}) async {
    final queryParams = <String, String>{};
    if (course != null && course.isNotEmpty && course != 'All') {
      queryParams['course'] = course;
    }
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }

    final uri = Uri.parse(ApiConfig.reportRankings).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());
    final rawList = response['data'] as List? ?? [];
    return rawList.map((e) => StudentRankingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SubjectAttendanceItem>> getSubjectAttendanceReport({String? course}) async {
    final queryParams = <String, String>{};
    if (course != null && course.isNotEmpty && course != 'All') {
      queryParams['course'] = course;
    }
    final uri = Uri.parse(ApiConfig.reportSubjectAttendance).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());
    final rawList = response['data'] as List? ?? [];
    return rawList.map((e) => SubjectAttendanceItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
