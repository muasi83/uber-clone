import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/driver_document.dart';
import '../models/ride_model.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class DriverService {
  
  // Register as driver
  static Future<bool> registerAsDriver({
    required String licenseNumber,
    required String vehicleNumber,
    required String vehicleType,
    required String vehicleModel,
    required String vehicleColor,
    int? vehicleYear,
    required String token,
  }) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🚗 REGISTERING AS DRIVER');
      addDebugMessage('Vehicle: $vehicleModel ($vehicleColor)');
      addDebugMessage('License: $licenseNumber');

      final url = '${StorageService.getServerUrl()}/api/drivers/register';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'licenseNumber': licenseNumber,
          'vehicleNumber': vehicleNumber,
          'vehicleType': vehicleType,
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
          'vehicleYear': vehicleYear,
        }),
      ).timeout(const Duration(seconds: 15));

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Driver profile created!');
        addDebugMessage('Message: ${json['message']}');
        addDebugMessage('═══════════════════════════════════════');
        return true;
      } else {
        addDebugMessage('❌ Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return false;
    }
  }

  // Get driver profile
static Future<DriverProfile?> getDriverProfile(String token) async {
  try {
    addDebugMessage('📋 FETCHING DRIVER PROFILE');

    final url = '${StorageService.getServerUrl()}/api/drivers/profile';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));

    addDebugMessage('Response Status: ${response.statusCode}');
    addDebugMessage('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      addDebugMessage('✅ Parsed response');
      
      final profile = DriverProfile.fromJson(json);
      addDebugMessage('✅ Profile loaded: ${profile.user.fullName}');
      return profile;
    } else if (response.statusCode == 404) {
      addDebugMessage('⚠️ Profile not found (404)');
      return null;
    } else {
      addDebugMessage('❌ Error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    addDebugMessage('❌ Exception in getDriverProfile: $e');
    return null;
  }
}

  // Update location
  static Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/drivers/location';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      addDebugMessage('❌ Error updating location: $e');
      return false;
    }
  }

  // Toggle online status
  static Future<({bool online, String? message})> toggleOnlineStatus(String token) async {
    try {
      addDebugMessage('🔄 TOGGLING ONLINE STATUS');

      final url = '${StorageService.getServerUrl()}/api/drivers/toggle-online';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final isOnline = json['isOnline'] == true;
        addDebugMessage('✅ Online: $isOnline');
        return (online: isOnline, message: null);
      }
      String? message;
      try {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          final raw = json['message'] ?? json['error'];
          if (raw is String) message = raw;
        }
      } catch (_) {}
      addDebugMessage('❌ Toggle failed: ${response.statusCode} $message');
      return (online: false, message: message ?? 'Failed to update status');
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      return (online: false, message: 'Failed to update status');
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // DOCUMENT WORKFLOW (Phase 3C2)
  // ═════════════════════════════════════════════════════════════════
  // Upload a single document (multipart): POST /api/drivers/documents
  static Future<DriverDocument?> uploadDriverDocument({
    required String documentType,
    required Uint8List bytes,
    required String filename,
    required String token,
    String? issueDate,
    String? expiryDate,
    String? documentNumber,
  }) async {
    try {
      addDebugMessage('📄 UPLOADING DOCUMENT: $documentType');
      final url = Uri.parse('${StorageService.getServerUrl()}/api/drivers/documents');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['documentType'] = documentType;
      if (issueDate != null && issueDate.isNotEmpty) request.fields['issueDate'] = issueDate;
      if (expiryDate != null && expiryDate.isNotEmpty) request.fields['expiryDate'] = expiryDate;
      if (documentNumber != null && documentNumber.isNotEmpty) request.fields['documentNumber'] = documentNumber;
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        addDebugMessage('✅ Document uploaded (id ${json['id']})');
        return DriverDocument.fromJson(json);
      }
      String? message;
      try {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          final raw = json['message'] ?? json['error'];
          if (raw is String) message = raw;
        }
      } catch (_) {}
      addDebugMessage('❌ Document upload failed: ${response.statusCode} $message');
      return null;
    } catch (e) {
      addDebugMessage('❌ Document upload exception: $e');
      return null;
    }
  }

  // List uploaded documents: GET /api/drivers/documents
  static Future<List<DriverDocument>> getDriverDocuments(String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/drivers/documents');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.isNotEmpty && body.startsWith('[')) {
          final list = jsonDecode(body) as List;
          return list
              .map((d) => DriverDocument.fromJson(d as Map<String, dynamic>))
              .toList();
        }
      }
      addDebugMessage('⚠️ List documents failed: ${response.statusCode}');
      return [];
    } catch (e) {
      addDebugMessage('❌ List documents exception: $e');
      return [];
    }
  }

  // Completeness: GET /api/drivers/documents/status
  static Future<DocumentCompleteness?> getDocumentCompleteness(String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/drivers/documents/status');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DocumentCompleteness.fromJson(json);
      }
      addDebugMessage('⚠️ Completeness failed: ${response.statusCode}');
      return null;
    } catch (e) {
      addDebugMessage('❌ Completeness exception: $e');
      return null;
    }
  }

  // Delete a document: DELETE /api/drivers/documents/{id}
  static Future<bool> deleteDriverDocument(int documentId, String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/drivers/documents/$documentId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      final ok = response.statusCode == 200;
      addDebugMessage('${ok ? "✅" : "❌"} Document delete (${response.statusCode})');
      return ok;
    } catch (e) {
      addDebugMessage('❌ Document delete exception: $e');
      return false;
    }
  }

  // Submit driver for verification (DRAFT/REJECTED -> PENDING): POST /api/drivers/submit
  static Future<({bool ok, String? message, String? verificationStatus})> submitDriver(String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/drivers/submit');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> json = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {}

      if (response.statusCode == 200) {
        addDebugMessage('✅ Driver submitted: ${json['verificationStatus']}');
        return (
          ok: true,
          message: json['message'] as String?,
          verificationStatus: json['verificationStatus'] as String?,
        );
      }
      final raw = json['message'] ?? json['error'];
      final msg = raw is String ? raw : 'Submission failed (${response.statusCode})';
      addDebugMessage('❌ Submit failed: ${response.statusCode} $msg');
      return (ok: false, message: msg, verificationStatus: null);
    } catch (e) {
      addDebugMessage('❌ Submit exception: $e');
      return (ok: false, message: 'Submission failed', verificationStatus: null);
    }
  }

    // ═════════════════════════════════════════════════════════════════
  // CHECK IF DRIVER HAS AN ACTIVE RIDE (Engagement Lock)
  // ═════════════════════════════════════════════════════════════════
  static Future<Ride?> getActiveRide(String token) async {
    try {
      addDebugMessage('🚗 CHECKING ACTIVE RIDE FOR DRIVER');

      final url = '${StorageService.getServerUrl()}/api/rides/driver/active';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      addDebugMessage('Active ride check status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Active ride found');
        return Ride.fromJson(json);
      } else if (response.statusCode == 404) {
        addDebugMessage('ℹ️ No active ride (404)');
        return null;
      } else {
        addDebugMessage('❌ Error checking active ride: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      addDebugMessage('❌ Exception in getActiveRide: $e');
      return null;
    }
  }

  // Get nearby drivers via WebSocket broadcast + ride-specific location API.
  // NOTE: The backend must have a /api/drivers/nearby endpoint or broadcast
  // driver_location WebSocket events for this to work at scale.
  // During an active ride, the driver's location is shown via /api/rides/$rideId/location.
  static Future<List<DriverProfile>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final token = StorageService.getToken();
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final url = '${StorageService.getServerUrl()}/api/drivers/nearby'
          '?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm';
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = response.body;
        if (body.isNotEmpty && body.startsWith('[')) {
          final jsonList = jsonDecode(body) as List;
          return jsonList
              .map((d) => DriverProfile.fromJson(d as Map<String, dynamic>))
              .toList();
        } else {
          addDebugMessage('⚠️ Nearby drivers response was not an array: $body');
        }
      } else {
        addDebugMessage('⚠️ Nearby drivers API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      addDebugMessage('❌ Error fetching nearby drivers: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getFinancialSummary(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/drivers/financial-summary';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Error fetching financial summary: $e');
      return null;
    }
  }
}