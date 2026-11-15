import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await ApiService.post(
      ApiConfig.authLogin,
      {
        'identifier': identifier.trim(),
        'password': password,
      },
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      ApiService.setAuthToken(token);
      return {'token': token, 'user': user};
    } else {
      throw ApiException(response['error'] ?? 'Authentication failed');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.authRegister, data);
    if (response is Map<String, dynamic> && response['success'] == true) {
      return response;
    } else {
      throw ApiException(response['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await ApiService.post(
      ApiConfig.authVerifyEmail,
      {'token': token.trim()},
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      if (data.containsKey('token')) {
        ApiService.setAuthToken(data['token'] as String);
      }
      return data;
    } else {
      throw ApiException(response['error'] ?? 'Verification failed');
    }
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    final response = await ApiService.post(
      ApiConfig.authResendVerification,
      {'email': email.trim()},
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      return response;
    } else {
      throw ApiException(response['error'] ?? 'Failed to resend verification email');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiService.post(
      ApiConfig.authForgotPassword,
      {'email': email.trim()},
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      return response;
    } else {
      throw ApiException(response['error'] ?? 'Failed to process password reset');
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final response = await ApiService.post(
      ApiConfig.authResetPassword,
      {
        'token': token.trim(),
        'new_password': newPassword,
      },
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      return response;
    } else {
      throw ApiException(response['error'] ?? 'Failed to reset password');
    }
  }

  Future<UserModel> getMe() async {
    final response = await ApiService.get(ApiConfig.authMe);
    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      throw ApiException(response['error'] ?? 'Failed to fetch current user profile');
    }
  }
}
