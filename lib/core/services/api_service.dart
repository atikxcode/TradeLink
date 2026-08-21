import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get _baseUrl {
    // Web always runs on the same machine, so localhost works.
    // Android emulator needs 10.0.2.2.
    if (kIsWeb) {
      return 'http://localhost:8081/api/v1';
    }
    return 'http://localhost:8081/api/v1';
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    debugPrint('[ApiService] userId=$userId');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-User-Id': '$userId::supplier',
    };
  }

  static Future<Map<String, dynamic>?> get(String path) async {
    try {
      final headers = await _headers();
      final url = '$_baseUrl$path';
      debugPrint('[ApiService] GET $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint('[ApiService] GET ${response.statusCode} ${response.body}');
      final body = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && body['success'] == true) {
        return body['data'];
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] GET ERROR: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _headers();
      final url = '$_baseUrl$path';
      debugPrint('[ApiService] POST $url body=$body');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      debugPrint('[ApiService] POST ${response.statusCode} ${response.body}');
      final respBody = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && respBody['success'] == true) {
        return respBody['data'];
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] POST ERROR: $e');
      return null;
    }
  }
}
