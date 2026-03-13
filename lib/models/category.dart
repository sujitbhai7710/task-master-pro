class Category {
  final String id;
  final String userId;
  final String name;
  final String color;
  final String? icon;
  final String? parentId;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    this.color = '#6366f1',
    this.icon,
    this.parentId,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#6366f1',
      icon: json['icon'],
      parentId: json['parent_id'],
      position: json['position'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
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
    );
  }

  // Helper to parse color string to Color
  int get colorValue {
    try {
      final hexColor = color.replaceAll('#', '');
      return int.parse('FF$hexColor', radix: 16);
    } catch (e) {
      return 0xFF6366F1; // Default color
    }
  }
}
