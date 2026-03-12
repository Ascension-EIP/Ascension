import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String? _userId;
  String? _username;
  String? _email;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    _userId = prefs.getString(AppConstants.userIdKey);
    _username = prefs.getString(AppConstants.usernameKey);
    _email = prefs.getString(AppConstants.emailKey);
    _role = prefs.getString(AppConstants.roleKey);
    _isLoggedIn = token != null && token.isNotEmpty;
  }

  /// Sync profile fields from an API response `{ id, username, email, role }`.
  Future<void> syncFromApi(Map<String, dynamic> data) async {
    await updateProfile(
      username: data['username'] as String?,
      email: data['email'] as String?,
      role: data['role'] as String?,
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? username,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    await prefs.setString(AppConstants.userIdKey, userId);
    if (username != null)
      await prefs.setString(AppConstants.usernameKey, username);
    if (email != null) await prefs.setString(AppConstants.emailKey, email);
    _userId = userId;
    _username = username ?? _username;
    _email = email ?? _email;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? email,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (username != null) {
      await prefs.setString(AppConstants.usernameKey, username);
      _username = username;
    }
    if (email != null) {
      await prefs.setString(AppConstants.emailKey, email);
      _email = email;
    }
    if (role != null) {
      await prefs.setString(AppConstants.roleKey, role);
      _role = role;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.emailKey);
    await prefs.remove(AppConstants.roleKey);
    _isLoggedIn = false;
    _userId = null;
    _username = null;
    _email = null;
    notifyListeners();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }
}
