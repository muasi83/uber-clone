import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AdminSettlementService {
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

  static String _date(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static Future<Map<String, dynamic>?> getSettlementSummary({
    String? token,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final params = <String, String>{
        if (from != null) 'from': _date(from),
        if (to != null) 'to': _date(to),
      };
      final uri = Uri.parse('${StorageService.getServerUrl()}/api/admin/settlement/summary')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDriverSettlementDetail({
    required int driverId,
    String? token,
    DateTime? from,
    DateTime? to,
    String? sort,
  }) async {
    try {
      final params = <String, String>{
        if (from != null) 'from': _date(from),
        if (to != null) 'to': _date(to),
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };
      final uri = Uri.parse(
              '${StorageService.getServerUrl()}/api/admin/settlement/drivers/$driverId')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
