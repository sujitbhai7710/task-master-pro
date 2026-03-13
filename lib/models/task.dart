import 'subtask.dart';

class Task {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String? startTime;
  final String? endTime;
  final bool isRecurring;
  final String? recurrencePattern;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final bool reminderEnabled;
  final DateTime? reminderTime;
  final String? reminderType;
  final int position;
  final String? tags;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SubTask> subtasks;
  final Category? category;

  Task({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.description,
    this.status = 'pending',
    this.priority = 'medium',
    this.dueDate,
    this.startTime,
    this.endTime,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.reminderEnabled = false,
    this.reminderTime,
    this.reminderType,
    this.position = 0,
    this.tags,
    this.estimatedMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.category,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'],
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null 
          ? DateTime.tryParse(json['due_date']) 
          : null,
      startTime: json['start_time'],
      endTime: json['end_time'],
      isRecurring: json['is_recurring'] == 1 || json['is_recurring'] == true,
      recurrencePattern: json['recurrence_pattern'],
      recurrenceInterval: json['recurrence_interval'],
      recurrenceEndDate: json['recurrence_end_date'] != null 
          ? DateTime.tryParse(json['recurrence_end_date']) 
          : null,
      reminderEnabled: json['reminder_enabled'] == 1 || json['reminder_enabled'] == true,
      reminderTime: json['reminder_time'] != null 
          ? DateTime.tryParse(json['reminder_time']) 
          : null,
      reminderType: json['reminder_type'],
      position: json['position'] ?? 0,
      tags: json['tags'],
      estimatedMinutes: json['estimated_minutes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      subtasks: json['subtasks'] != null 
          ? (json['subtasks'] as List).map((s) => SubTask.fromJson(s)).toList()
          : [],
      category: json['category'] != null 
          ? Category.fromJson(json['category'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_pattern': recurrencePattern,
      'recurrence_interval': recurrenceInterval,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime?.toIso8601String(),
      'reminder_type': reminderType,
      'position': position,
      'tags': tags,
      'estimated_minutes': estimatedMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? startTime,
    String? endTime,
    bool? isRecurring,
    String? recurrencePattern,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    bool? reminderEnabled,
    DateTime? reminderTime,
    String? reminderType,
    int? position,
    String? tags,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubTask>? subtasks,
    Category? category,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderType: reminderType ?? this.reminderType,
      position: position ?? this.position,
      tags: tags ?? this.tags,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
      category: category ?? this.category,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == 'completed') return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && 
           dueDate!.month == now.month && 
           dueDate!.day == now.day;
  }

  bool get isTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year && 
           dueDate!.month == tomorrow.month && 
           dueDate!.day == tomorrow.day;
  }

  double get progress {
    if (subtasks.isEmpty) return status == 'completed' ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.completed).length;
    return completed / subtasks.length;
  }
}

class Category {
  final String id;
  final String userId;
  final String name;
  final String color;
  final String icon;
  final String? parentId;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    this.color = '#6366f1',
    this.icon = 'folder',
    this.parentId,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#6366f1',
      icon: json['icon'] ?? 'folder',
      parentId: json['parent_id'],
      position: json['position'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      subcategories: json['subcategories'] != null 
          ? (json['subcategories'] as List).map((c) => Category.fromJson(c)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
      'parent_id': parentId,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    String? icon,
    String? parentId,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Category>? subcategories,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}
