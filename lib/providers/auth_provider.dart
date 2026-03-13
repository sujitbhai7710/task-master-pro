import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/offline_data_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final OfflineDataService _offlineData = OfflineDataService();
  
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
      // Initialize offline data service
      await _offlineData.init();
      
      // Check if user is already logged in
      final userData = await _offlineData.getCurrentUser();
      if (userData != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
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
      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        _error = 'Please enter email and password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Try offline login
      final userData = await _offlineData.loginUser(
        email: email.trim(),
        password: password,
      );

      if (userData != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password. Please try again or sign up.';
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
      // Validate input
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

      // Register user offline
      final userData = await _offlineData.registerUser(
        email: email.trim(),
        password: password,
        name: name.trim(),
      );

      if (userData != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'This email is already registered. Please login instead.';
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
    await _offlineData.logout();
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
    
    // Handle common error cases
    if (errorString.contains('SocketException') || 
        errorString.contains('Connection refused') ||
        errorString.contains('Connection timed out') ||
        errorString.contains('Network is unreachable')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    
    if (errorString.contains('FormatException')) {
      return 'Invalid response. Please try again.';
    }

    // Extract message from ApiException
    if (errorString.contains('ApiException')) {
      final match = RegExp(r'message:\s*([^,)]+)').firstMatch(errorString);
      if (match != null) {
        return match.group(1)?.trim() ?? 'An error occurred';
      }
    }
    
    // Return a cleaned up version of the error
    if (errorString.startsWith('Exception: ')) {
      return errorString.replaceFirst('Exception: ', '');
    }
    
    return 'An error occurred. Please try again.';
  }
}
