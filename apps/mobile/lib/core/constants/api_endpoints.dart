// @date 2026-11-13
// @file api_endpoints.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done / Centralized API endpoint constants.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/v1/auth/login';
  static const String register = '/v1/auth/register';
  static const String refreshToken = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';

  // Profile & Constraints
  static const String profile = '/v1/profile';
  static const String profileConstraints = '/v1/profile/constraints';
  static String profileConstraintDetails(String id) =>
      '/v1/profile/constraints/$id';

  // Video & Analysis
  static const String requestUploadUrl = '/v1/videos/upload-url';
  static const String uploadComplete = '/v1/videos/upload-done';
  static const String analyses = '/v1/analysis';
  static String analysisDetails(String id) => '/v1/analysis/$id';
  static String retryAdvice(String id) => '/v1/analysis/$id/retry-advice';

  // Climb sessions
  static const String climbSessions = '/v1/sessions';
  static const String activeClimbSession = '/v1/sessions/active';
  static String climbSessionDetails(String id) => '/v1/sessions/$id';
  static String climbSessionAnalyses(String id) => '/v1/sessions/$id/analyses';

  // Training
  static const String trainingPrograms = '/v1/trainings/programs';

  // Subscription
  static const String subscriptionStatus = '/v1/subscriptions/me';
}
