// lib/services/session_service.dart
// Persist login state using shared_preferences

import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class SessionService {
  static const _keyUserId = 'user_id';
  static const _keyEmail  = 'email';
  static const _keyRole   = 'role';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.userId);
    await prefs.setString(_keyEmail,  user.email);
    await prefs.setString(_keyRole,   user.role);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    if (userId == null) return null;
    return UserModel(
      userId: userId,
      email:  prefs.getString(_keyEmail) ?? '',
      role:   prefs.getString(_keyRole)  ?? 'user',
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
