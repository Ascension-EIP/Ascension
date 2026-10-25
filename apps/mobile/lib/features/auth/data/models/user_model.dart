// @date 2026-10-25
// @file user_model.dart
// @brief Data Transfer Object for User JSON serialization.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:mobile/features/auth/domain/entities/user.dart';

/// DTO for [User] deserialization from Go backend response.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.role = 'user',
    super.status = 'active',
  });

  /// Factory creating [UserModel] from backend JSON.
  /// Handles both PascalCase (Go struct) and camelCase/snake_case defensively.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['ID'] ?? json['id'] ?? '').toString(),
      username: (json['Username'] ?? json['username'] ?? '').toString(),
      email: (json['Email'] ?? json['email'] ?? '').toString(),
      firstName:
          (json['FirstName'] ?? json['first_name'] ?? json['firstName'] ?? '')
              .toString(),
      lastName:
          (json['LastName'] ?? json['last_name'] ?? json['lastName'] ?? '')
              .toString(),
      role: (json['Role'] ?? json['role'] ?? 'user').toString(),
      status: (json['Status'] ?? json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'status': status,
    };
  }
}
