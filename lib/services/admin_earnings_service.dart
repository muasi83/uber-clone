import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AdminEarningsService {
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

  static Future<Map<String, dynamic>?> getEarningsSummary(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/earnings/summary';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDriverEarnings(int driverId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/earnings/drivers/$driverId';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSettlements(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/settlements';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDriverSettlements(int driverId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/settlements';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> createSettlement({
    required int driverId,
    required String grossAmount,
    required String appFee,
    required String netAmount,
    required String settlementReference,
    String? receiptNumber,
    required String token,
  }) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/settlements';
      final body = {
        'driverId': driverId,
        'grossAmount': grossAmount,
        'appFee': appFee,
        'netAmount': netAmount,
        'settlementReference': settlementReference,
        if (receiptNumber != null && receiptNumber.isNotEmpty) 'receiptNumber': receiptNumber,
      };
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
