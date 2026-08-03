import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/driver_document.dart';

class AdminDriversService {
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

  static Future<List<Map<String, dynamic>>?> getDrivers(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/drivers';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final drivers = data['drivers'] as List<dynamic>;
        return drivers.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDriverDetail(int driverId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/drivers/$driverId';
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

  static Future<Map<String, dynamic>?> toggleVerify(int driverId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/verify';
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

  static Future<Map<String, dynamic>?> toggleBlock(int driverId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/block';
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

  static Future<List<DriverDocument>> getDriverDocuments(int driverId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/documents';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final docs = data['documents'] as List<dynamic>? ?? [];
        return docs
            .whereType<Map<String, dynamic>>()
            .map(DriverDocument.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> reviewDocument(
    int driverId,
    int documentId,
    String action,
    String token, {
    String? adminNote,
    String? issueDate,
    String? expiryDate,
    String? documentNumber,
  }) async {
    try {
      final url =
          '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/documents/$documentId/$action';
      final body = <String, dynamic>{};
      if (adminNote != null && adminNote.trim().isNotEmpty) body['adminNote'] = adminNote;
      if (issueDate != null && issueDate.isNotEmpty) body['issueDate'] = issueDate;
      if (expiryDate != null && expiryDate.isNotEmpty) body['expiryDate'] = expiryDate;
      if (documentNumber != null && documentNumber.isNotEmpty) body['documentNumber'] = documentNumber;
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: body.isEmpty ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> fetchDocumentFile(
    int driverId,
    int documentId,
    String token,
  ) async {
    try {
      final url =
          '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/documents/$documentId/file';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDashboard(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/dashboard';
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

  static Future<Map<String, dynamic>?> getExpirySummary(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/admin/documents/expiry-summary';
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

  static Future<Map<String, dynamic>?> getDriverAudit(
    int driverId,
    String token, {
    String filter = 'ALL',
    int limit = 100,
  }) async {
    try {
      final url =
          '${StorageService.getServerUrl()}/api/admin/drivers/$driverId/audit?filter=$filter&limit=$limit';
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
}
