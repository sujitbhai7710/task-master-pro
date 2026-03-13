import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await _api.getCurrentUser();
        if (response['user'] != null) {
          _user = User.fromJson(response['user']);
          _isAuthenticated = true;
        } else {
          await _storage.clearAll();
          _user = null;
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await _storage.clearAll();
      _user = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.trim().isEmpty || password.isEmpty) {
        _error = 'Please enter email and password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _api.login(
        email: email.trim(),
        password: password,
      );

      if (response['user'] != null && response['token'] != null) {
        _user = User.fromJson(response['user']);
        await _storage.saveToken(response['token']);
        await _storage.saveUserId(_user!.id);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.trim().isEmpty) {
        _error = 'Please enter your email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _error = 'Please enter a password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (name.trim().isEmpty) {
        _error = 'Please enter your name';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _api.register(
        email: email.trim(),
        password: password,
        name: name.trim(),
      );

      if (response['user'] != null && response['token'] != null) {
        _user = User.fromJson(response['user']);
        await _storage.saveToken(response['token']);
        await _storage.saveUserId(_user!.id);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('SocketException') || 
        errorString.contains('Connection refused') ||
        errorString.contains('Connection timed out') ||
        errorString.contains('Network is unreachable')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    
    if (errorString.contains('FormatException')) {
      return 'Invalid server response. Please try again.';
    }

    if (errorString.contains('HandshakeException') ||
        errorString.contains('CertificateException')) {
      return 'Secure connection failed. Please try again.';
    }

    if (errorString.contains('HttpException')) {
      return 'Server error. Please try again later.';
    }

    if (errorString.contains('ApiException')) {
      final match = RegExp(r'message:\s*([^,)]+)').firstMatch(errorString);
      if (match != null) {
        return match.group(1)?.trim() ?? 'An error occurred';
      }
    }

    if (errorString.contains('Invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    if (errorString.contains('Email already registered')) {
      return 'This email is already registered. Please login instead.';
    }

    if (errorString.startsWith('Exception: ')) {
      return errorString.replaceFirst('Exception: ', '');
    }

    return 'An error occurred. Please try again.';
  }
}
