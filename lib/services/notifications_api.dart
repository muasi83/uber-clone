import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class NotificationsApi {
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
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_normalizeToken(token)}';
    }
    return headers;
  }

  static String _base() => '${StorageService.getServerUrl()}/api/notifications';

  static Future<List<Map<String, dynamic>>?> getNotifications(String token) async {
    try {
      final response = await http
          .get(Uri.parse(_base()), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
        }
      }
      addDebugMessage('getNotifications failed: HTTP ${response.statusCode}');
    } catch (e) {
      addDebugMessage('getNotifications error: $e');
    }
    return null;
  }

  static Future<int> getUnreadCount(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$_base()/unread-count'), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final count = json['unreadCount'];
        if (count is num) return count.toInt();
      }
    } catch (e) {
      addDebugMessage('getUnreadCount error: $e');
    }
    return 0;
  }

  static Future<bool> markRead(String token, int notificationId) async {
    try {
      final response = await http
          .post(Uri.parse('$_base()/$notificationId/read'), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      addDebugMessage('markRead error: $e');
      return false;
    }
  }

  static Future<bool> markAllRead(String token) async {
    try {
      final response = await http
          .post(Uri.parse('$_base()/read-all'), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      addDebugMessage('markAllRead error: $e');
      return false;
    }
  }
}
