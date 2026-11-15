import '../config/api_config.dart';
import '../models/student_model.dart';
import 'api_service.dart';

class StudentService {
  Future<Map<String, dynamic>> getStudents({
    String? search,
    String? course,
    int? semester,
    bool? active,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (course != null && course.trim().isNotEmpty && course != 'All') {
      queryParams['course'] = course.trim();
    }
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }
    if (active != null) {
      queryParams['active'] = active.toString();
    }

    final uri = Uri.parse(ApiConfig.students).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());

    final rawList = response['data'] as List? ?? [];
    final students = rawList.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();

    return {
      'students': students,
      'total': response['total'] ?? students.length,
      'count': response['count'] ?? students.length,
      'page': response['page'] ?? page,
    };
  }

  Future<StudentModel> getStudent(String identifier) async {
    final url = '${ApiConfig.students}/$identifier';
    final response = await ApiService.get(url);
    return StudentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<StudentModel> createStudent(StudentModel student) async {
    final response = await ApiService.post(ApiConfig.students, student.toJson());
    return StudentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<StudentModel> updateStudent(String identifier, Map<String, dynamic> fields) async {
    final url = '${ApiConfig.students}/$identifier';
    final response = await ApiService.put(url, fields);
    return StudentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStudent(String identifier) async {
    final url = '${ApiConfig.students}/$identifier';
    await ApiService.delete(url);
  }

  Future<Map<String, dynamic>> getStudentSummary(String identifier) async {
    final url = '${ApiConfig.students}/$identifier/summary';
    final response = await ApiService.get(url);
    return response['data'] as Map<String, dynamic>? ?? {};
  }
}
