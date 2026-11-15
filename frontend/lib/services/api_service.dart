import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiService {
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<dynamic> get(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 12),
      );
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network communication error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach CampusTrack backend server at $url ($e)');
    }
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach CampusTrack backend server ($e)');
    }
  }

  static Future<dynamic> put(String url, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach CampusTrack backend server ($e)');
    }
  }

  static Future<dynamic> delete(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.delete(uri, headers: _headers).timeout(
        const Duration(seconds: 12),
      );
      return _processResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach CampusTrack backend server ($e)');
    }
  }

  static dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String errorMsg = 'HTTP ${response.statusCode} error occurred.';
    if (decoded is Map) {
      if (decoded['error'] != null) {
        errorMsg = decoded['error'].toString();
      } else if (decoded['message'] != null) {
        errorMsg = decoded['message'].toString();
      }
    }

    throw ApiException(
      errorMsg,
      statusCode: response.statusCode,
      details: decoded,
    );
  }
}
