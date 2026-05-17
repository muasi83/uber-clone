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

  // Get nearby drivers
  static Future<List<DriverProfile>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/drivers/nearby'
          '?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm';
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        return jsonList
            .map((d) => DriverProfile.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      addDebugMessage('❌ Error getting nearby drivers: $e');
      return [];
    }
  }
}