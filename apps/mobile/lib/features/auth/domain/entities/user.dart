// @date 2026-10-30
// @file user.dart
// @brief Pure domain entity representing an Ascension user.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:equatable/equatable.dart';

/// Pure domain entity representing an Ascension user.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'user',
    this.status = 'active',
  });

  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String status;

  /// Full display name combining first and last name.
  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    role,
    status,
  ];
}
