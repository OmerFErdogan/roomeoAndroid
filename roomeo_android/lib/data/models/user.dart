// lib/data/models/user.dart
class User {
  final int id; // userId yerine id kullanıyoruz çünkü API'den id olarak geliyor
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isDeleted;

  int get userId => id;

  User({
    required this.id, // userId -> id olarak değiştirildi
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'], // userId -> id olarak değiştirildi
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImage: json['profile_image'],
      status: json['status'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      isDeleted: json['is_deleted'],
    );
  }
}
