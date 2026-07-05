import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class AdminService {
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

  static Future<Map<String, dynamic>?> getTrips({
    int? rideId,
    String? status,
    String? paymentStatus,
    String? riderName,
    String? driverName,
    String? fromDate,
    String? toDate,
    int page = 0,
    int size = 20,
    required String token,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (rideId != null) params['rideId'] = rideId.toString();
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (paymentStatus != null && paymentStatus.isNotEmpty) params['paymentStatus'] = paymentStatus;
      if (riderName != null && riderName.isNotEmpty) params['riderName'] = riderName;
      if (driverName != null && driverName.isNotEmpty) params['driverName'] = driverName;
      if (fromDate != null && fromDate.isNotEmpty) params['fromDate'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) params['toDate'] = toDate;

      final uri = Uri.parse('${StorageService.getServerUrl()}/api/admin/rides')
          .replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      addDebugMessage('Admin getTrips error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      addDebugMessage('Admin getTrips exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTripDetail(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/rides/$rideId';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      addDebugMessage('Admin getTripDetail error: ${response.statusCode}');
      return null;
    } catch (e) {
      addDebugMessage('Admin getTripDetail exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTripEvents(
    int rideId, String token, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final uri = Uri.parse('${StorageService.getServerUrl()}/api/admin/rides/$rideId/events')
          .replace(queryParameters: {'page': page.toString(), 'size': size.toString()});
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      addDebugMessage('Admin getTripEvents exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTripMessages(
    int rideId, String token, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final uri = Uri.parse('${StorageService.getServerUrl()}/api/admin/rides/$rideId/messages')
          .replace(queryParameters: {'page': page.toString(), 'size': size.toString()});
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      addDebugMessage('Admin getTripMessages exception: $e');
      return null;
    }
  }

  static Future<bool> setKeepForever(int rideId, bool keepForever, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/rides/$rideId/keep-forever';
      final response = await http
          .patch(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'keepForever': keepForever}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      addDebugMessage('Admin setKeepForever exception: $e');
      return false;
    }
  }

  static Future<bool> addNote(int rideId, String note, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/rides/$rideId/notes';
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'note': note}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      addDebugMessage('Admin addNote exception: $e');
      return false;
    }
  }
}
