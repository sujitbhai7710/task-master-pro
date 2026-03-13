class SubTask {
  final String id;
  final String taskId;
  final String title;
  final String? description;
  final bool completed;
  final int position;
  final DateTime? dueDate;
  final bool isRecurring;
  final String? recurrencePattern;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final bool reminderEnabled;
  final DateTime? reminderTime;
  final String? reminderType;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubTask({
    required this.id,
    required this.taskId,
    required this.title,
    this.description,
    this.completed = false,
    this.position = 0,
    this.dueDate,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.reminderEnabled = false,
    this.reminderTime,
    this.reminderType,
    this.priority = 'medium',
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      completed: json['completed'] == 1 || json['completed'] == true,
      position: json['position'] ?? 0,
      dueDate: json['due_date'] != null 
          ? DateTime.tryParse(json['due_date']) 
          : null,
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
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'position': position,
      'due_date': dueDate?.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_pattern': recurrencePattern,
      'recurrence_interval': recurrenceInterval,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime?.toIso8601String(),
      'reminder_type': reminderType,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubTask copyWith({
    String? id,
    String? taskId,
    String? title,
    String? description,
    bool? completed,
    int? position,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrencePattern,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    bool? reminderEnabled,
    DateTime? reminderTime,
    String? reminderType,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      position: position ?? this.position,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderType: reminderType ?? this.reminderType,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
