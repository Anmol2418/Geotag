import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static const String baseUrl = 'http://172.16.18.188:3000';

  // Keys for storing logged-in user session
  static const _keyLoggedInUserId = 'logged_in_employee_id';
  static const _keyLoggedInUserName = 'logged_in_employee_name';

  /// Manual login using employee_id and password
  Future<UserModel?> login({
    required String employeeId,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final employee = data['employee'];

        final user = UserModel(
          employeeId: employee['employee_id'],
          name: employee['name'] ?? 'Unknown',
        );

        // Save logged-in user session
        await saveLoggedInUser(user);

        // Save or clear credentials based on rememberMe
        if (rememberMe) {
          await StorageService.saveCredentials(
            employeeId: employeeId,
            password: password,
          );
        } else {
          await StorageService.clearCredentials();
        }

        return user;
      } else {
        print('Login failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Register a new employee with optional face image upload
  Future<bool> register({
    required String employeeId,
    required String email,
    required String name,
    required String password,
    File? faceImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register');

      var request = http.MultipartRequest('POST', uri)
        ..fields['employeeId'] = employeeId.trim()
        ..fields['email'] = email.trim()
        ..fields['name'] = name.trim()
        ..fields['password'] = password.trim();

      if (faceImage != null) {
        request.files.add(await http.MultipartFile.fromPath('face', faceImage.path));
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Registration successful.');
        return true;
      } else {
        print('❌ Registration failed: $body');
        return false;
      }
    } catch (e, st) {
      print('❗ Registration error: $e');
      print('Stacktrace:\n$st');
      return false;
    }
  }

  /// Save logged-in user session in SharedPreferences
  Future<void> saveLoggedInUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoggedInUserId, user.employeeId);
    await prefs.setString(_keyLoggedInUserName, user.name);
  }

  /// Get logged-in user session from SharedPreferences
  Future<UserModel?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyLoggedInUserId);
    final name = prefs.getString(_keyLoggedInUserName);
    if (id != null && name != null) {
      return UserModel(employeeId: id, name: name);
    }
    return null;
  }

  /// Clear logged-in user session from SharedPreferences
  Future<void> clearLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedInUserId);
    await prefs.remove(_keyLoggedInUserName);
  }

  /// Auto-login if credentials are stored
  Future<UserModel?> getRememberedUser() async {
    final creds = await StorageService.getCredentials();
    if (creds == null) return null;

    return await login(
      employeeId: creds['employeeId']!,
      password: creds['password']!,
      rememberMe: true,
    );
  }

  /// Logout and clear stored credentials and session
  Future<void> logout() async {
    await clearLoggedInUser();
    await StorageService.clearCredentials();
  }

  /// Dummy: Get current user — optional, unused
  Future<UserModel?> getCurrentUser() async => null;
}

