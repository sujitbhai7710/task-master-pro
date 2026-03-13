import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();
  
  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> _headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String?> _getToken() async {
    return await _storage.getToken();
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.health}'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? fullName,
    String? dateOfBirth,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.register}'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'name': name.trim(),
        'full_name': fullName?.trim(),
        'date_of_birth': dateOfBirth,
      }),
    ).timeout(const Duration(seconds: 30));
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.login}'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 30));
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw ApiException(message: 'No authentication token', statusCode: 401);
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConfig.me}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    
    return _handleResponse(response);
  }

  // Password Recovery endpoints
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.verifyEmail}'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    ).timeout(const Duration(seconds: 30));
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifySecurityAnswers({
    required String email,
    required String fullName,
    required String dateOfBirth,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.verifySecurity}'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'date_of_birth': dateOfBirth,
      }),
    ).timeout(const Duration(seconds: 30));
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.resetPassword}'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'new_password': newPassword,
      }),
    ).timeout(const Duration(seconds: 30));
    
    return _handleResponse(response);
  }

  // Task endpoints
  Future<List<Task>> getTasks() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConfig.tasks}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    
    final tasks = data['tasks'] as List? ?? [];
    return tasks.map((t) => Task.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<Task> getTask(String taskId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConfig.task(taskId)}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return Task.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<Task> createTask(Map<String, dynamic> taskData) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.tasks}'),
      headers: _headers(token: token),
      body: jsonEncode(taskData),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return Task.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<Task> updateTask(String taskId, Map<String, dynamic> taskData) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl${ApiConfig.task(taskId)}'),
      headers: _headers(token: token),
      body: jsonEncode(taskData),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return Task.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<void> deleteTask(String taskId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl${ApiConfig.task(taskId)}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    _handleResponse(response);
  }

  // Subtask endpoints
  Future<List<SubTask>> getSubtasks(String taskId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConfig.subtasks(taskId)}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    
    final subtasks = data['subtasks'] as List? ?? [];
    return subtasks.map((s) => SubTask.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<SubTask> createSubtask(String taskId, Map<String, dynamic> subtaskData) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.subtasks(taskId)}'),
      headers: _headers(token: token),
      body: jsonEncode(subtaskData),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return SubTask.fromJson(data['subtask'] as Map<String, dynamic>);
  }

  Future<SubTask> updateSubtask(String subtaskId, Map<String, dynamic> subtaskData) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl${ApiConfig.subtask(subtaskId)}'),
      headers: _headers(token: token),
      body: jsonEncode(subtaskData),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return SubTask.fromJson(data['subtask'] as Map<String, dynamic>);
  }

  Future<void> deleteSubtask(String subtaskId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl${ApiConfig.subtask(subtaskId)}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    _handleResponse(response);
  }

  // Category endpoints
  Future<List<Category>> getCategories() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConfig.categories}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    
    final categories = data['categories'] as List? ?? [];
    return categories.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConfig.categories}'),
      headers: _headers(token: token),
      body: jsonEncode(categoryData),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return Category.fromJson(data['category'] as Map<String, dynamic>);
  }

  Future<Category> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl${ApiConfig.category(categoryId)}'),
      headers: _headers(token: token),
      body: jsonEncode(categoryData),
    ).timeout(const Duration(seconds: 30));
    final data = _handleResponse(response);
    return Category.fromJson(data['category'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String categoryId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl${ApiConfig.category(categoryId)}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    _handleResponse(response);
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConfig.statistics}'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'An error occurred';
        throw ApiException(
          message: errorMsg.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      // Handle JSON parse errors
      throw ApiException(
        message: 'Failed to parse server response',
        statusCode: response.statusCode,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
