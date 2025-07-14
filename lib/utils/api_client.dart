import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_config.dart'; // Make sure apiBase is defined here
const String apiBase = 'http://172.16.18.188:3000';  // or your actual server URL

class ApiClient {
  static final _storage = const FlutterSecureStorage();

  /// Save token after login
  static Future<void> saveToken(String token) async =>
      _storage.write(key: 'jwt', value: token);

  /// Retrieve stored JWT token
  static Future<String?> _token() => _storage.read(key: 'jwt');

  /// Generic POST
  static Future<Map<String, dynamic>> post(
      String path,
      Map<String, dynamic> body, {
        bool auth = false,
        bool isMultipart = false,
      }) async {
    final uri = Uri.parse('$apiBase$path');
    final headers = <String, String>{};

    if (auth) {
      final token = await _token();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    late http.Response res;

    if (isMultipart) {
      // body contains 'file' (http.MultipartFile) and regular fields
      final req = http.MultipartRequest('POST', uri)..headers.addAll(headers);
      body.forEach((k, v) {
        if (v is http.MultipartFile) {
          req.files.add(v);
        } else {
          req.fields[k] = v.toString();
        }
      });
      res = await http.Response.fromStream(await req.send());
    } else {
      headers['Content-Type'] = 'application/json';
      res = await http.post(uri, headers: headers, body: jsonEncode(body));
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw 'Error ${res.statusCode}: ${res.body}';
    }
  }

  /// Generic GET
  static Future<Map<String, dynamic>> get(
      String path, {
        bool auth = false,
      }) async {
    final uri = Uri.parse('$apiBase$path');
    final headers = <String, String>{};

    if (auth) {
      final token = await _token();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final res = await http.get(uri, headers: headers);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw 'Error ${res.statusCode}: ${res.body}';
    }
  }
}
