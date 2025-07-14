import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyEmployeeId = 'employee_id';
  static const _keyPassword = 'password';
  static const _keyRemember = 'remember_me';

  static Future<void> saveCredentials({
    required String employeeId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
      ..setString(_keyEmployeeId, employeeId)
      ..setString(_keyPassword, password)
      ..setBool(_keyRemember, true);
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
      ..remove(_keyEmployeeId)
      ..remove(_keyPassword)
      ..setBool(_keyRemember, false);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyRemember) != true) return null;

    final id = prefs.getString(_keyEmployeeId);
    final pw = prefs.getString(_keyPassword);
    return (id != null && pw != null) ? {'employeeId': id, 'password': pw} : null;
  }
}
