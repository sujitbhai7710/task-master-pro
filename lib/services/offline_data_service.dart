import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first data service that stores everything locally
/// Works completely offline with SharedPreferences
class OfflineDataService {
  static const String _usersKey = 'offline_users';
  static const String _tasksKey = 'offline_tasks';
  static const String _subtasksKey = 'offline_subtasks';
  static const String _categoriesKey = 'offline_categories';
  static const String _currentUserKey = 'current_user_id';

  late SharedPreferences _prefs;

  // In-memory caches
  Map<String, Map<String, dynamic>> _usersCache = {};
  Map<String, List<Map<String, dynamic>>> _tasksCache = {};
  Map<String, List<Map<String, dynamic>>> _subtasksCache = {};
  Map<String, List<Map<String, dynamic>>> _categoriesCache = {};
  String? _currentUserId;

  // Singleton pattern
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;
  OfflineDataService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    // Load users
    final usersJson = _prefs.getString(_usersKey);
    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
      _usersCache = decoded.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    }

    // Load current user
    _currentUserId = _prefs.getString(_currentUserKey);

    // Load tasks
    final tasksJson = _prefs.getString(_tasksKey);
    if (tasksJson != null) {
      final decoded = jsonDecode(tasksJson) as Map<String, dynamic>;
      _tasksCache = decoded.map((k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()));
    }

    // Load subtasks
    final subtasksJson = _prefs.getString(_subtasksKey);
    if (subtasksJson != null) {
      final decoded = jsonDecode(subtasksJson) as Map<String, dynamic>;
      _subtasksCache = decoded.map((k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()));
    }

    // Load categories
    final categoriesJson = _prefs.getString(_categoriesKey);
    if (categoriesJson != null) {
      final decoded = jsonDecode(categoriesJson) as Map<String, dynamic>;
      _categoriesCache = decoded.map((k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()));
    }
  }

  Future<void> _saveToDisk() async {
    await _prefs.setString(_usersKey, jsonEncode(_usersCache));
    await _prefs.setString(_tasksKey, jsonEncode(_tasksCache));
    await _prefs.setString(_subtasksKey, jsonEncode(_subtasksCache));
    await _prefs.setString(_categoriesKey, jsonEncode(_categoriesCache));
    if (_currentUserId != null) {
      await _prefs.setString(_currentUserKey, _currentUserId!);
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + (DateTime.now().microsecond % 1000)).toString();
  }

  // ============ USER METHODS ============

  String? getCurrentUserId() => _currentUserId;

  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    // Check if email already exists
    for (final user in _usersCache.values) {
      if ((user['email'] as String).toLowerCase() == email.toLowerCase()) {
        return null; // Email already registered
      }
    }

    final userId = _generateId();
    final now = DateTime.now().toIso8601String();

    final user = {
      'id': userId,
      'email': email.toLowerCase(),
      'password': password, // In production, hash this
      'name': name,
      'avatar': null,
      'created_at': now,
      'updated_at': now,
    };

    _usersCache[userId] = user;
    _currentUserId = userId;
    
    // Initialize empty lists for this user
    _tasksCache[userId] = [];
    _categoriesCache[userId] = [];
    _subtasksCache[userId] = [];

    await _saveToDisk();

    // Return user without password
    return {
      'id': userId,
      'email': email.toLowerCase(),
      'name': name,
      'avatar': null,
      'created_at': now,
    };
  }

  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    for (final user in _usersCache.values) {
      if ((user['email'] as String).toLowerCase() == email.toLowerCase() &&
          user['password'] == password) {
        _currentUserId = user['id'];
        await _saveToDisk();
        
        return {
          'id': user['id'],
          'email': user['email'],
          'name': user['name'],
          'avatar': user['avatar'],
          'created_at': user['created_at'],
        };
      }
    }
    return null; // Invalid credentials
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUserId == null) return null;
    final user = _usersCache[_currentUserId];
    if (user == null) return null;
    
    return {
      'id': user['id'],
      'email': user['email'],
      'name': user['name'],
      'avatar': user['avatar'],
      'created_at': user['created_at'],
    };
  }

  Future<void> logout() async {
    _currentUserId = null;
    await _prefs.remove(_currentUserKey);
  }

  // ============ TASK METHODS ============

  List<Map<String, dynamic>> getTasks() {
    if (_currentUserId == null) return [];
    return _tasksCache[_currentUserId] ?? [];
  }

  Map<String, dynamic>? getTask(String taskId) {
    final tasks = getTasks();
    for (final task in tasks) {
      if (task['id'] == taskId) {
        // Add subtasks to task
        task['subtasks'] = getSubtasksForTask(taskId);
        return task;
      }
    }
    return null;
  }

  Map<String, dynamic> createTask(Map<String, dynamic> taskData) {
    if (_currentUserId == null) throw Exception('Not authenticated');
    
    final taskId = _generateId();
    final now = DateTime.now().toIso8601String();
    
    final task = {
      'id': taskId,
      'user_id': _currentUserId,
      'title': taskData['title'] ?? '',
      'description': taskData['description'],
      'status': taskData['status'] ?? 'pending',
      'priority': taskData['priority'] ?? 'medium',
      'category_id': taskData['category_id'],
      'due_date': taskData['due_date'],
      'start_time': taskData['start_time'],
      'end_time': taskData['end_time'],
      'is_recurring': taskData['is_recurring'] ?? false,
      'recurrence_pattern': taskData['recurrence_pattern'],
      'recurrence_interval': taskData['recurrence_interval'],
      'recurrence_end_date': taskData['recurrence_end_date'],
      'reminder_enabled': taskData['reminder_enabled'] ?? false,
      'reminder_time': taskData['reminder_time'],
      'reminder_type': taskData['reminder_type'],
      'position': taskData['position'] ?? 0,
      'tags': taskData['tags'],
      'created_at': now,
      'updated_at': now,
      'subtasks': [],
    };
    
    _tasksCache[_currentUserId]!.add(task);
    _saveToDisk();
    
    return task;
  }

  Map<String, dynamic> updateTask(String taskId, Map<String, dynamic> updates) {
    if (_currentUserId == null) throw Exception('Not authenticated');
    
    final tasks = _tasksCache[_currentUserId]!;
    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i]['id'] == taskId) {
        tasks[i] = {
          ...tasks[i],
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        };
        _saveToDisk();
        tasks[i]['subtasks'] = getSubtasksForTask(taskId);
        return tasks[i];
      }
    }
    throw Exception('Task not found');
  }

  void deleteTask(String taskId) {
    if (_currentUserId == null) return;
    
    _tasksCache[_currentUserId]?.removeWhere((t) => t['id'] == taskId);
    
    // Also delete subtasks for this task
    _subtasksCache.remove(taskId);
    
    _saveToDisk();
  }

  // ============ SUBTASK METHODS ============

  List<Map<String, dynamic>> getSubtasksForTask(String taskId) {
    return _subtasksCache[taskId] ?? [];
  }

  Map<String, dynamic> createSubtask(String taskId, Map<String, dynamic> subtaskData) {
    if (_currentUserId == null) throw Exception('Not authenticated');
    
    final subtaskId = _generateId();
    final now = DateTime.now().toIso8601String();
    
    final subtask = {
      'id': subtaskId,
      'task_id': taskId,
      'title': subtaskData['title'] ?? '',
      'description': subtaskData['description'],
      'completed': subtaskData['completed'] ?? false,
      'position': subtaskData['position'] ?? 0,
      'due_date': subtaskData['due_date'],
      'start_time': subtaskData['start_time'],
      'end_time': subtaskData['end_time'],
      'is_recurring': subtaskData['is_recurring'] ?? false,
      'recurrence_pattern': subtaskData['recurrence_pattern'],
      'recurrence_interval': subtaskData['recurrence_interval'],
      'recurrence_end_date': subtaskData['recurrence_end_date'],
      'reminder_enabled': subtaskData['reminder_enabled'] ?? false,
      'reminder_time': subtaskData['reminder_time'],
      'reminder_type': subtaskData['reminder_type'],
      'created_at': now,
      'updated_at': now,
    };
    
    if (_subtasksCache[taskId] == null) {
      _subtasksCache[taskId] = [];
    }
    _subtasksCache[taskId]!.add(subtask);
    _saveToDisk();
    
    return subtask;
  }

  Map<String, dynamic> updateSubtask(String subtaskId, Map<String, dynamic> updates) {
    // Find the subtask in all task's subtask lists
    for (final taskId in _subtasksCache.keys) {
      final subtasks = _subtasksCache[taskId]!;
      for (int i = 0; i < subtasks.length; i++) {
        if (subtasks[i]['id'] == subtaskId) {
          subtasks[i] = {
            ...subtasks[i],
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          };
          _saveToDisk();
          return subtasks[i];
        }
      }
    }
    throw Exception('Subtask not found');
  }

  void deleteSubtask(String subtaskId) {
    for (final taskId in _subtasksCache.keys) {
      _subtasksCache[taskId]?.removeWhere((s) => s['id'] == subtaskId);
    }
    _saveToDisk();
  }

  // ============ CATEGORY METHODS ============

  List<Map<String, dynamic>> getCategories() {
    if (_currentUserId == null) return [];
    return _categoriesCache[_currentUserId] ?? [];
  }

  Map<String, dynamic> createCategory(Map<String, dynamic> categoryData) {
    if (_currentUserId == null) throw Exception('Not authenticated');
    
    final categoryId = _generateId();
    final now = DateTime.now().toIso8601String();
    
    final category = {
      'id': categoryId,
      'user_id': _currentUserId,
      'name': categoryData['name'] ?? '',
      'color': categoryData['color'] ?? '#6366f1',
      'icon': categoryData['icon'],
      'parent_id': categoryData['parent_id'],
      'position': categoryData['position'] ?? 0,
      'created_at': now,
      'updated_at': now,
    };
    
    _categoriesCache[_currentUserId]!.add(category);
    _saveToDisk();
    
    return category;
  }

  Map<String, dynamic> updateCategory(String categoryId, Map<String, dynamic> updates) {
    if (_currentUserId == null) throw Exception('Not authenticated');
    
    final categories = _categoriesCache[_currentUserId]!;
    for (int i = 0; i < categories.length; i++) {
      if (categories[i]['id'] == categoryId) {
        categories[i] = {
          ...categories[i],
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        };
        _saveToDisk();
        return categories[i];
      }
    }
    throw Exception('Category not found');
  }

  void deleteCategory(String categoryId) {
    if (_currentUserId == null) return;
    
    _categoriesCache[_currentUserId]?.removeWhere((c) => c['id'] == categoryId);
    
    // Remove category from all tasks
    final tasks = _tasksCache[_currentUserId] ?? [];
    for (final task in tasks) {
      if (task['category_id'] == categoryId) {
        task['category_id'] = null;
      }
    }
    
    _saveToDisk();
  }

  // ============ STATISTICS ============

  Map<String, dynamic> getStatistics() {
    if (_currentUserId == null) {
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'inProgress': 0,
        'highPriority': 0,
        'overdue': 0,
        'today': 0,
        'recurring': 0,
        'byCategory': [],
      };
    }
    
    final tasks = _tasksCache[_currentUserId] ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int total = tasks.length;
    int completed = tasks.where((t) => t['status'] == 'completed').length;
    int pending = tasks.where((t) => t['status'] == 'pending').length;
    int inProgress = tasks.where((t) => t['status'] == 'in_progress').length;
    int highPriority = tasks.where((t) => t['priority'] == 'high').length;
    int recurring = tasks.where((t) => t['is_recurring'] == true).length;
    
    int overdue = 0;
    int todayCount = 0;
    
    for (final task in tasks) {
      if (task['due_date'] != null && task['status'] != 'completed') {
        final dueDate = DateTime.parse(task['due_date']);
        if (dueDate.isBefore(now)) {
          overdue++;
        }
        final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        if (dueDateOnly == today) {
          todayCount++;
        }
      }
    }
    
    // By category
    final categories = _categoriesCache[_currentUserId] ?? [];
    final byCategory = categories.map((cat) {
      final count = tasks.where((t) => t['category_id'] == cat['id']).length;
      return {
        'name': cat['name'],
        'color': cat['color'],
        'count': count,
      };
    }).toList();
    
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'highPriority': highPriority,
      'overdue': overdue,
      'today': todayCount,
      'recurring': recurring,
      'byCategory': byCategory,
    };
  }
}
