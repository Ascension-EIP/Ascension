// @date 2026-09-29
// @file auth_response_model.dart
// @brief Data Transfer Object for authentication API response.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:new_mobile/features/auth/data/models/user_model.dart';
import 'package:new_mobile/features/auth/domain/entities/auth_session.dart';

/// DTO for login/signup response from Go backend.
class AuthResponseModel extends AuthSession {
  const AuthResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.tokenType,
    required super.expiresIn,
    required super.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? json['User'] as Map<String, dynamic>? ?? {};

    return AuthResponseModel(
      accessToken: (json['access_token'] ?? json['AccessToken'] ?? '').toString(),
      refreshToken: (json['refresh_token'] ?? json['RefreshToken'] ?? '').toString(),
      tokenType: (json['token_type'] ?? json['TokenType'] ?? 'Bearer').toString(),
      expiresIn: (json['expires_in'] as num?)?.toInt() ??
          (json['ExpiresIn'] as num?)?.toInt() ??
          3600,
      user: UserModel.fromJson(userMap),
    );
  }
}
