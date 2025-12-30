import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _keyUsername = 'username';

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
  }
}
