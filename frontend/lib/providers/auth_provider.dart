import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  static const String _keyToken = 'campustrack_auth_token';
  static const String _keyUserData = 'campustrack_user_data';

  Future<void> checkAuthSession() async {
    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_keyToken);
      final savedUserJson = prefs.getString(_keyUserData);

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        ApiService.setAuthToken(savedToken);

        if (savedUserJson != null) {
          try {
            _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
          } catch (_) {}
        }

        // Validate session with live backend /api/auth/me
        try {
          final liveUser = await _authService.getMe();
          _currentUser = liveUser;
          await prefs.setString(_keyUserData, jsonEncode(liveUser.toJson()));
        } catch (e) {
          // Token might have expired
          await logout();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(identifier, password);
      _token = result['token'] as String;
      _currentUser = result['user'] as UserModel;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      await prefs.setString(_keyUserData, jsonEncode(_currentUser!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(data);
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'data': response['data'], 'message': response['message']};
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.message};
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyEmail(token);
      if (result.containsKey('token') && result.containsKey('user')) {
        _token = result['token'] as String;
        _currentUser = UserModel.fromJson(result['user'] as Map<String, dynamic>);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, _token!);
        await prefs.setString(_keyUserData, jsonEncode(_currentUser!.toJson()));
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    try {
      await _authService.resendVerification(email);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      await _authService.resetPassword(token, newPassword);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    ApiService.setAuthToken(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserData);
    } catch (_) {}

    notifyListeners();
  }
}
