import 'package:http/http.dart' as http;
import 'dart:convert';
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
  static Future<bool> toggleOnlineStatus(String token) async {
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
        addDebugMessage('✅ Online: ${json['isOnline']}');
        return true;
      }
      return false;
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      return false;
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
}