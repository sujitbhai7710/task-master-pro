class User {
  final String id;
  final String email;
  final String name;
  final String? fullName;
  final String? dateOfBirth;
  final String? avatar;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.fullName,
    this.dateOfBirth,
    this.avatar,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      fullName: json['full_name'],
      dateOfBirth: json['date_of_birth'],
      avatar: json['avatar'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'avatar': avatar,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? fullName,
    String? dateOfBirth,
    String? avatar,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
