import '../config/api_config.dart';
import '../models/attendance_model.dart';
import 'api_service.dart';

class AttendanceService {
  Future<Map<String, dynamic>> getAttendanceRecords({
    String? studentId,
    String? date,
    String? subject,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (studentId != null && studentId.isNotEmpty) {
      queryParams['student_id'] = studentId;
    }
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }
    if (subject != null && subject.isNotEmpty && subject != 'All') {
      queryParams['subject'] = subject;
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(ApiConfig.attendance).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());

    final rawList = response['data'] as List? ?? [];
    final records = rawList.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>)).toList();

    return {
      'records': records,
      'total': response['total'] ?? records.length,
      'count': response['count'] ?? records.length,
    };
  }

  Future<AttendanceModel> recordAttendance(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.attendance, data);
    return AttendanceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AttendanceModel> updateAttendance(String id, Map<String, dynamic> data) async {
    final url = '${ApiConfig.attendance}/$id';
    final response = await ApiService.put(url, data);
    return AttendanceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAttendance(String id) async {
    final url = '${ApiConfig.attendance}/$id';
    await ApiService.delete(url);
  }

  Future<AttendanceSummaryModel> getAttendanceSummary({
    String? studentId,
    String? subject,
    String? date,
  }) async {
    final queryParams = <String, String>{};
    if (studentId != null && studentId.isNotEmpty) {
      queryParams['student_id'] = studentId;
    }
    if (subject != null && subject.isNotEmpty && subject != 'All') {
      queryParams['subject'] = subject;
    }
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final uri = Uri.parse(ApiConfig.attendanceSummary).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());
    return AttendanceSummaryModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
