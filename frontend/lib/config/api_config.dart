import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  // Configurable base URL for development and testing
  static String? _customBaseUrl;

  static void setBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _customBaseUrl = trimmed;
  }

  /// Base API URL.
  /// For Android Emulator: uses http://10.0.2.2:5000/api
  /// For Windows Desktop / Web: uses http://127.0.0.1:5000/api
  /// For Physical Phones on LAN: set via setBaseUrl("http://YOUR_PC_IP:5000/api")
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Standard Android Emulator loopback alias for Windows host
      return 'http://10.0.2.2:5000/api';
    }

    return 'http://127.0.0.1:5000/api';
  }

  // Endpoints relative to the baseUrl
  static String get health => '$baseUrl/health';
  static String get dashboard => '$baseUrl/dashboard';
  static String get students => '$baseUrl/students';
  static String get attendance => '$baseUrl/attendance';
  static String get attendanceSummary => '$baseUrl/attendance/summary';
  static String get marks => '$baseUrl/marks';
  static String get marksSummary => '$baseUrl/marks/summary';
  static String get reportAttendance => '$baseUrl/reports/attendance';
  static String get reportSubjectAttendance => '$baseUrl/reports/subject-attendance';
  static String get reportPerformance => '$baseUrl/reports/performance';
  static String get reportLowAttendance => '$baseUrl/reports/low-attendance';
  static String get reportRankings => '$baseUrl/reports/rankings';
  static String get reportUnified => '$baseUrl/reports/unified';

  // Authentication & Profile Endpoints
  static String get authRegister => '$baseUrl/auth/register';
  static String get authLogin => '$baseUrl/auth/login';
  static String get authVerifyEmail => '$baseUrl/auth/verify-email';
  static String get authResendVerification => '$baseUrl/auth/resend-verification';
  static String get authForgotPassword => '$baseUrl/auth/forgot-password';
  static String get authResetPassword => '$baseUrl/auth/reset-password';
  static String get authMe => '$baseUrl/auth/me';
}
