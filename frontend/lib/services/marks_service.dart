import '../config/api_config.dart';
import '../models/marks_model.dart';
import 'api_service.dart';

class MarksService {
  Future<Map<String, dynamic>> getMarks({
    String? studentId,
    String? subject,
    String? exam,
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
    if (subject != null && subject.isNotEmpty && subject != 'All') {
      queryParams['subject'] = subject;
    }
    if (exam != null && exam.isNotEmpty && exam != 'All') {
      queryParams['exam'] = exam;
    }

    final uri = Uri.parse(ApiConfig.marks).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());

    final rawList = response['data'] as List? ?? [];
    final records = rawList.map((e) => MarksModel.fromJson(e as Map<String, dynamic>)).toList();

    return {
      'records': records,
      'total': response['total'] ?? records.length,
      'count': response['count'] ?? records.length,
    };
  }

  Future<MarksModel> recordMarks(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.marks, data);
    return MarksModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<MarksModel> updateMarks(String id, Map<String, dynamic> data) async {
    final url = '${ApiConfig.marks}/$id';
    final response = await ApiService.put(url, data);
    return MarksModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMarks(String id) async {
    final url = '${ApiConfig.marks}/$id';
    await ApiService.delete(url);
  }

  Future<MarksSummaryModel> getMarksSummary({
    String? studentId,
    String? subject,
    String? exam,
  }) async {
    final queryParams = <String, String>{};
    if (studentId != null && studentId.isNotEmpty) {
      queryParams['student_id'] = studentId;
    }
    if (subject != null && subject.isNotEmpty && subject != 'All') {
      queryParams['subject'] = subject;
    }
    if (exam != null && exam.isNotEmpty && exam != 'All') {
      queryParams['exam'] = exam;
    }

    final uri = Uri.parse(ApiConfig.marksSummary).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());
    return MarksSummaryModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
