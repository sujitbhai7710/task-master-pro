import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;
  String? _categoryFilter;
  String _searchQuery = '';
  Map<String, dynamic>? _statistics;

  List<Task> get tasks => _filteredTasks.isEmpty && _searchQuery.isEmpty && _statusFilter == null && _categoryFilter == null 
      ? _tasks : _filteredTasks;
  List<Task> get allTasks => _tasks;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;
  Map<String, dynamic>? get statistics => _statistics;

  int get pendingCount => _tasks.where((t) => t.status == 'pending' || t.status == 'todo').length;
  int get completedCount => _tasks.where((t) => t.status == 'completed').length;
  int get todayCount => _tasks.where((t) => t.isToday).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  
  // Kanban helpers
  List<Task> get todoTasks => _tasks.where((t) => t.status == 'todo' || t.status == 'pending').toList();
  List<Task> get inProgressTasks => _tasks.where((t) => t.status == 'in_progress').toList();
  List<Task> get reviewTasks => _tasks.where((t) => t.status == 'review').toList();
  List<Task> get doneTasks => _tasks.where((t) => t.status == 'completed').toList();

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _api.getTasks();
      _applyFilters();
      debugPrint('Loaded ${_tasks.length} tasks');
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error loading tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _api.getCategories();
      notifyListeners();
      debugPrint('Loaded ${_categories.length} categories');
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await _api.getStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> fetchTasks() async {
    await loadTasks();
  }

  Future<void> fetchStatistics() async {
    await loadStatistics();
  }

  Future<Task?> createTask(Map<String, dynamic> taskData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final task = await _api.createTask(taskData);
      _tasks.insert(0, task);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return task;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Task?> updateTask(String taskId, Map<String, dynamic> taskData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedTask = await _api.updateTask(taskId, taskData);
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _applyFilters();
      }
      _isLoading = false;
      notifyListeners();
      return updatedTask;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Task?> getTask(String taskId) async {
    try {
      return await _api.getTask(taskId);
    } catch (e) {
      debugPrint('Error getting task: $e');
      return null;
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    return getTask(taskId);
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    return await updateTask(taskId, {'status': status}) != null;
  }

  // Subtask operations
  Future<SubTask?> createSubtask(Map<String, dynamic> subtaskData) async {
    try {
      final taskId = subtaskData['task_id'] as String;
      final data = Map<String, dynamic>.from(subtaskData);
      data.remove('task_id');
      final subtask = await _api.createSubtask(taskId, data);
      await loadTasks();
      return subtask;
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSubtask(String subtaskId, Map<String, dynamic> subtaskData) async {
    try {
      await _api.updateSubtask(subtaskId, subtaskData);
      await loadTasks();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubtask(String subtaskId) async {
    try {
      await _api.deleteSubtask(subtaskId);
      await loadTasks();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Category operations
  Future<Category?> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final category = await _api.createCategory(categoryData);
      _categories.add(category);
      notifyListeners();
      return category;
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
      return null;
    }
  }
  
  Future<Category?> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    try {
      final updatedCategory = await _api.updateCategory(categoryId, categoryData);
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }
      return updatedCategory;
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _api.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      await loadTasks();
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Category? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Filtering
  void setStatusFilter(String? status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setCategoryFilter(String? categoryId) {
    _categoryFilter = categoryId;
    _applyFilters();
  }

  void setFilterStatus(String status) {
    setStatusFilter(status == 'all' ? null : status);
  }

  void setFilterCategory(String? categoryId) {
    setCategoryFilter(categoryId);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    _searchQuery = '';
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      if (_statusFilter != null && task.status != _statusFilter) return false;
      if (_categoryFilter != null && task.categoryId != _categoryFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!task.title.toLowerCase().contains(query) &&
            !(task.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Token management (for compatibility)
  void setToken(String token) {
    // Token is managed by StorageService in ApiService
  }
  
  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadTasks(),
      loadCategories(),
      loadStatistics(),
    ]);
  }
  
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('SocketException') || 
        errorString.contains('Connection refused') ||
        errorString.contains('Connection timed out')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    
    if (errorString.contains('FormatException')) {
      return 'Invalid server response. Please try again.';
    }
    
    if (errorString.contains('ApiException')) {
      final match = RegExp(r'message:\s*([^,)]+)').firstMatch(errorString);
      if (match != null) {
        return match.group(1)?.trim() ?? 'An error occurred';
      }
    }
    
    return 'An error occurred. Please try again.';
  }
}
