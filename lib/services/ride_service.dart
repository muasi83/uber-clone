import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/ride_model.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class RideService {
  
  /// Request a ride (RIDER) - NOW SENDS ACTUAL DISTANCE AND FARE
  static Future<Ride?> requestRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String rideType,
    required double estimatedDistance,  // ✅ NOW REQUIRED
    required double estimatedFare,      // ✅ NOW REQUIRED
    required int estimatedDuration,     // ✅ NOW REQUIRED
    required String token,
  }) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🚗 REQUESTING RIDE');
      addDebugMessage('From: $pickupAddress');
      addDebugMessage('To: $dropoffAddress');
      addDebugMessage('Type: $rideType');
      addDebugMessage('Distance: ${estimatedDistance.toStringAsFixed(2)} km (ACTUAL)');
      addDebugMessage('Duration: $estimatedDuration min');
      addDebugMessage('Fare: \$${estimatedFare.toStringAsFixed(2)} (REAL)');

      final url = '${StorageService.getServerUrl()}/api/rides/request';
      
      // ✅ NOW INCLUDES estimatedDistance AND estimatedFare
      final requestBody = {
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLatitude': dropoffLat,
        'dropoffLongitude': dropoffLng,
        'dropoffAddress': dropoffAddress,
        'rideType': rideType,
        'estimatedDistance': estimatedDistance,  // ✅ REAL DISTANCE FROM GOOGLE MAPS
        'estimatedFare': estimatedFare,          // ✅ REAL FARE CALCULATED FROM REAL DISTANCE
        'estimatedDuration': estimatedDuration,  // ✅ DURATION FROM GOOGLE MAPS
      };

      addDebugMessage('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      addDebugMessage('Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Ride requested: ID ${json['id']}');
        addDebugMessage('Estimated Fare: \$${json['estimatedFare']}');
        addDebugMessage('═══════════════════════════════════════');
        return Ride.fromJson(json);
      } else {
        addDebugMessage('❌ Error: ${response.statusCode}');
        addDebugMessage(response.body);
        return null;
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return null;
    }
  }

  // Get available rides (DRIVER)
  static Future<List<Ride>> getAvailableRides(String token) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔍 FETCHING AVAILABLE RIDES');

      final url = '${StorageService.getServerUrl()}/api/rides/available';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final rides = jsonList
            .map((r) => Ride.fromJson(r as Map<String, dynamic>))
            .toList();
        addDebugMessage('✅ Found ${rides.length} available rides');
        addDebugMessage('═══════════════════════════════════════');
        return rides;
      } else {
        addDebugMessage('❌ Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return [];
    }
  }

  // Accept ride (DRIVER)
  static Future<Ride?> acceptRide(int rideId, String token) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('✅ ACCEPTING RIDE #$rideId');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/accept';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Ride accepted!');
        addDebugMessage('═══════════════════════════════════════');
        return Ride.fromJson(json);
      } else {
        addDebugMessage('❌ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return null;
    }
  }

  // Start ride (DRIVER)
  static Future<Ride?> startRide(int rideId, String token) async {
    try {
      addDebugMessage('🚗 STARTING RIDE #$rideId');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/start';
      
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
        addDebugMessage('✅ Ride started!');
        return Ride.fromJson(json);
      } else {
        addDebugMessage('❌ Error starting ride');
        return null;
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return null;
    }
  }

  // Complete ride (DRIVER)
  static Future<Ride?> completeRide(int rideId, String token) async {
    try {
      addDebugMessage('✅ COMPLETING RIDE #$rideId');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/complete';
      
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
        addDebugMessage('✅ Ride completed!');
        return Ride.fromJson(json);
      } else {
        addDebugMessage('❌ Error completing ride');
        return null;
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return null;
    }
  }

  // Get ride details
  static Future<Ride?> getRideDetails(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/rides/$rideId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Ride.fromJson(json);
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Error getting ride details: $e');
      return null;
    }
  }

  // Get user's ride history
  static Future<List<Ride>> getRideHistory(String token) async {
    try {
      addDebugMessage('📋 FETCHING RIDE HISTORY');

      final url = '${StorageService.getServerUrl()}/api/rides/user/history';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final rides = jsonList
            .map((r) => Ride.fromJson(r as Map<String, dynamic>))
            .toList();
        addDebugMessage('✅ Found ${rides.length} rides in history');
        return rides;
      }
      return [];
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return [];
    }
  }
}