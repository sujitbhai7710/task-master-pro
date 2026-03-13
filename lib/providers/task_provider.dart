import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/offline_data_service.dart';

class TaskProvider extends ChangeNotifier {
  final OfflineDataService _offlineData = OfflineDataService();
  
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
      final taskMaps = _offlineData.getTasks();
      _tasks = taskMaps.map((t) {
        // Convert subtasks
        final subtaskMaps = t['subtasks'] as List? ?? [];
        final subtasks = subtaskMaps.map((s) => SubTask.fromJson(Map<String, dynamic>.from(s))).toList();
        final task = Task.fromJson(Map<String, dynamic>.from(t));
        return Task(
          id: task.id,
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          categoryId: task.categoryId,
          dueDate: task.dueDate,
          startTime: task.startTime,
          endTime: task.endTime,
          isRecurring: task.isRecurring,
          recurrencePattern: task.recurrencePattern,
          recurrenceInterval: task.recurrenceInterval,
          recurrenceEndDate: task.recurrenceEndDate,
          reminderEnabled: task.reminderEnabled,
          reminderTime: task.reminderTime,
          reminderType: task.reminderType,
          position: task.position,
          tags: task.tags,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
          subtasks: subtasks,
        );
      }).toList();
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
      final categoryMaps = _offlineData.getCategories();
      _categories = categoryMaps.map((c) => Category.fromJson(Map<String, dynamic>.from(c))).toList();
      notifyListeners();
      debugPrint('Loaded ${_categories.length} categories');
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = _offlineData.getStatistics();
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
      final taskMap = _offlineData.createTask(taskData);
      final subtaskMaps = taskMap['subtasks'] as List? ?? [];
      final subtasks = subtaskMaps.map((s) => SubTask.fromJson(Map<String, dynamic>.from(s))).toList();
      final task = Task.fromJson(Map<String, dynamic>.from(taskMap));
      final fullTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        categoryId: task.categoryId,
        dueDate: task.dueDate,
        startTime: task.startTime,
        endTime: task.endTime,
        isRecurring: task.isRecurring,
        recurrencePattern: task.recurrencePattern,
        recurrenceInterval: task.recurrenceInterval,
        recurrenceEndDate: task.recurrenceEndDate,
        reminderEnabled: task.reminderEnabled,
        reminderTime: task.reminderTime,
        reminderType: task.reminderType,
        position: task.position,
        tags: task.tags,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        subtasks: subtasks,
      );
      _tasks.insert(0, fullTask);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return fullTask;
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
      final taskMap = _offlineData.updateTask(taskId, taskData);
      final subtaskMaps = taskMap['subtasks'] as List? ?? [];
      final subtasks = subtaskMaps.map((s) => SubTask.fromJson(Map<String, dynamic>.from(s))).toList();
      final task = Task.fromJson(Map<String, dynamic>.from(taskMap));
      final fullTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        categoryId: task.categoryId,
        dueDate: task.dueDate,
        startTime: task.startTime,
        endTime: task.endTime,
        isRecurring: task.isRecurring,
        recurrencePattern: task.recurrencePattern,
        recurrenceInterval: task.recurrenceInterval,
        recurrenceEndDate: task.recurrenceEndDate,
        reminderEnabled: task.reminderEnabled,
        reminderTime: task.reminderTime,
        reminderType: task.reminderType,
        position: task.position,
        tags: task.tags,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        subtasks: subtasks,
      );
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = fullTask;
        _applyFilters();
      }
      _isLoading = false;
      notifyListeners();
      return fullTask;
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
      _offlineData.deleteTask(taskId);
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
      final taskMap = _offlineData.getTask(taskId);
      if (taskMap == null) return null;
      final subtaskMaps = taskMap['subtasks'] as List? ?? [];
      final subtasks = subtaskMaps.map((s) => SubTask.fromJson(Map<String, dynamic>.from(s))).toList();
      final task = Task.fromJson(Map<String, dynamic>.from(taskMap));
      return Task(
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        categoryId: task.categoryId,
        dueDate: task.dueDate,
        startTime: task.startTime,
        endTime: task.endTime,
        isRecurring: task.isRecurring,
        recurrencePattern: task.recurrencePattern,
        recurrenceInterval: task.recurrenceInterval,
        recurrenceEndDate: task.recurrenceEndDate,
        reminderEnabled: task.reminderEnabled,
        reminderTime: task.reminderTime,
        reminderType: task.reminderType,
        position: task.position,
        tags: task.tags,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        subtasks: subtasks,
      );
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
      final subtaskMap = _offlineData.createSubtask(taskId, data);
      final subtask = SubTask.fromJson(Map<String, dynamic>.from(subtaskMap));
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
      _offlineData.updateSubtask(subtaskId, subtaskData);
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
      _offlineData.deleteSubtask(subtaskId);
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
      final categoryMap = _offlineData.createCategory(categoryData);
      final category = Category.fromJson(Map<String, dynamic>.from(categoryMap));
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
      final categoryMap = _offlineData.updateCategory(categoryId, categoryData);
      final updatedCategory = Category.fromJson(Map<String, dynamic>.from(categoryMap));
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
      _offlineData.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      // Update tasks that had this category
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
    // No longer needed - offline mode
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
    
    if (errorString.contains('Not authenticated')) {
      return 'Please log in to continue.';
    }
    
    if (errorString.contains('Exception: ')) {
      return errorString.replaceFirst('Exception: ', '');
    }
    
    return 'An error occurred. Please try again.';
  }
}
