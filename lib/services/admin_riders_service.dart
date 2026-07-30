import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AdminRidersService {
  static String _normalizeToken(String token) {
    var t = token.trim();
    if (t.length >= 2 &&
        ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'")))) {
      t = t.substring(1, t.length - 1).trim();
    }
    final lower = t.toLowerCase();
    if (lower.startsWith('bearer ')) {
      t = t.substring(7).trim();
    }
    return t;
  }

  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_normalizeToken(token)}';
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>?> getRiders(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/riders';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final riders = data['riders'] as List<dynamic>;
        return riders.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRiderDetail(int riderId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/riders/$riderId';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> toggleBlock(int riderId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/riders/$riderId/block';
      final response = await http
          .patch(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
