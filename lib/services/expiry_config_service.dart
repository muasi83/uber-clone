import 'dart:convert';

import 'package:http/http.dart' as http;

import '../screens/debug_screen.dart';
import 'storage_service.dart';

/// Fetches and caches the document-expiry configuration served by the
/// backend (`GET /api/config/document-expiry`). Until a successful fetch
/// the legacy Flutter defaults are kept, so behaviour is unchanged when the
/// server is unreachable.
class ExpiryConfigService {
  static const int _defaultSoonDays = 31;
  static const int _defaultUrgentDays = 7;

  static int _soonDays = _defaultSoonDays;
  static int _urgentDays = _defaultUrgentDays;
  static bool _enabled = true;

  /// Number of days before a document expiry date it is treated as "soon".
  static int get soonDays => _soonDays;

  static int get urgentDays => _urgentDays;

  static bool get enabled => _enabled;

  /// Restores the legacy defaults (used by tests).
  static void reset() {
    _soonDays = _defaultSoonDays;
    _urgentDays = _defaultUrgentDays;
    _enabled = true;
  }

  static Future<void> load({required String token}) async {
    if (token.trim().isEmpty) return;
    try {
      final url = '${StorageService.getServerUrl()}/api/config/document-expiry';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        applyConfig(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        addDebugMessage('ExpiryConfig load error: ${response.statusCode}');
      }
    } catch (e) {
      addDebugMessage('ExpiryConfig load exception: $e');
    }
  }

  /// Applies a parsed config payload, ignoring invalid values so the cached
  /// defaults are preserved.
  static void applyConfig(Map<String, dynamic>? data) {
    if (data == null) return;
    final soon = (data['soonDays'] as num?)?.toInt();
    final urgent = (data['urgentDays'] as num?)?.toInt();
    final enabled = data['enabled'] as bool?;
    if (soon != null && soon > 0) _soonDays = soon;
    if (urgent != null && urgent > 0) _urgentDays = urgent;
    if (enabled != null) _enabled = enabled;
  }

  static Map<String, String> _headers({required String token}) {
    var t = token.trim();
    final lower = t.toLowerCase();
    if (lower.startsWith('bearer ')) {
      t = t.substring(7).trim();
    }
    return {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $t',
    };
  }
}
