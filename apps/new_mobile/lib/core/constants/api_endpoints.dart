// @date 2026-09-29
// @file api_endpoints.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
/// Centralized API endpoint constants.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/v1/auth/login';
  static const String signup = '/v1/auth/signup';
  static const String refreshToken = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';

  // User & Profile
  static const String currentUser = '/users/me';
  static const String updateProfile = '/users/me/profile';

  // Video & Analysis
  static const String requestUploadUrl = '/videos/upload-url';
  static const String analyses = '/analyses';
  static String analysisDetails(String id) => '/analyses/$id';

  // Climb sessions
  static const String climbSessions = '/climbs';
  static String climbSessionDetails(String id) => '/climbs/$id';

  // Training
  static const String trainingPrograms = '/trainings/programs';

  // Subscription
  static const String subscriptionStatus = '/subscriptions/me';
}
