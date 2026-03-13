import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storage;
  
  static const String _tokenKey = 'auth_token';
  
  User? _currentUser;
  bool _isInitialized = false;
  
  AuthService({
    ApiService? apiService,
    FlutterSecureStorage? storage,
  }) : _apiService = apiService ?? ApiService(),
       _storage = StorageService();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get token => _currentUser != null ? 'authenticated' : null;

  Future<void> initialize() async {
    try {
      final savedToken = await _storage.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        final userData = await _apiService.getCurrentUser();
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      await _storage.deleteToken();
    }
    _isInitialized = true;
  }

  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final data = await _apiService.register(
      email: email,
      password: password,
      name: name,
    );
    
    final token = data['token'] as String;
    final user = User.fromJson(data['user']);
    
    await _storage.saveToken(token);
    _currentUser = user;
    return user;
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiService.login(
      email: email,
      password: password,
    );
    
    final token = data['token'] as String;
    final user = User.fromJson(data['user']);
    
    await _storage.saveToken(token);
    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    _currentUser = null;
  }

  Future<void> refreshToken() async {
    try {
      final userData = await _apiService.getCurrentUser();
      _currentUser = User.fromJson(userData);
    } catch (e) {
      await logout();
      rethrow;
    }
  }
}
