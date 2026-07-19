import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/ride_model.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class RideService {
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

  static Map<String, String> _headers({String? token, bool json = true}) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
    };

    if (json) headers['Content-Type'] = 'application/json';

    if (token != null && token.trim().isNotEmpty) {
      final normalized = _normalizeToken(token);
      headers['Authorization'] = 'Bearer $normalized';
    }

    return headers;
  }

  /// Request a ride (RIDER)
  static Future<Ride?> requestRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String rideType,
    required double estimatedDistance,
    required double estimatedFare,
    required int estimatedDuration,
    required String token,
    String paymentMethod = 'WALLET',
  }) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🚗 REQUESTING RIDE');
      addDebugMessage('From: $pickupAddress');
      addDebugMessage('To: $dropoffAddress');
      addDebugMessage('Type: $rideType');
      addDebugMessage('Payment: $paymentMethod');
      addDebugMessage('Distance: ${estimatedDistance.toStringAsFixed(2)} km (ACTUAL)');
      addDebugMessage('Duration: $estimatedDuration min');
      addDebugMessage('Fare: \$${estimatedFare.toStringAsFixed(2)} (REAL)');

      final url = '${StorageService.getServerUrl()}/api/rides/request';

      final requestBody = {
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLatitude': dropoffLat,
        'dropoffLongitude': dropoffLng,
        'dropoffAddress': dropoffAddress,
        'rideType': rideType,
        'paymentMethod': paymentMethod,
        'estimatedDistance': estimatedDistance,
        'estimatedFare': estimatedFare,
        'estimatedDuration': estimatedDuration,
      };

      addDebugMessage('Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Ride requested: ID ${json['id']}');
        addDebugMessage('Estimated Fare: \$${json['estimatedFare']}');
        addDebugMessage('═══════════════════════════════════════');
        await StorageService.saveActiveRideId(json['id'] as int);
        await StorageService.saveActiveRideStatus('REQUESTED');
        return Ride.fromJson(json);
      } else {
        addDebugMessage('❌ Error: ${response.statusCode}');
        addDebugMessage(response.body);

        // Helpful debug for 401
        if (response.statusCode == 401) {
          final normalized = _normalizeToken(token);
          addDebugMessage('⚠️ 401 DEBUG: tokenLength=${normalized.length}, tokenPrefix=${normalized.substring(0, normalized.length >= 12 ? 12 : normalized.length)}');
        }

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

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final rides = jsonList.map((r) => Ride.fromJson(r as Map<String, dynamic>)).toList();
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

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Ride accepted!');
        addDebugMessage('═══════════════════════════════════════');
        await StorageService.saveActiveRideId(json['id'] as int);
        await StorageService.saveActiveRideStatus('ACCEPTED');
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

  static Future<Ride?> startRide(int rideId, String token) async {
    try {
      addDebugMessage('🚗 STARTING RIDE #$rideId');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/start';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));

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

  static Future<Ride?> completeRide(int rideId, String token) async {
    try {
      addDebugMessage('✅ COMPLETING RIDE #$rideId');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/complete';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('✅ Ride completed!');
        await StorageService.clearActiveRideId();
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

  static Future<Ride?> getRideDetails(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/rides/$rideId';

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers(token: token, json: false),
          )
          .timeout(const Duration(seconds: 10));

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

  static Future<Ride?> getActiveRide(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/rides/active';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token, json: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['active'] == true) {
          return Ride.fromJson(json['ride']);
        }
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Error checking active ride: $e');
      return null;
    }
  }

  static Future<List<Ride>> getRideHistory(String token) async {
    return getRideHistoryPaginated(token, 0, 20);
  }

  static Future<List<Ride>> getRideHistoryPaginated(String token, int page, int size) async {
    try {
      addDebugMessage('📋 FETCHING RIDE HISTORY page=$page size=$size');

      final url = '${StorageService.getServerUrl()}/api/rides/user/history?page=$page&size=$size';

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers(token: token, json: false),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final rides = jsonList.map((r) => Ride.fromJson(r as Map<String, dynamic>)).toList();
        addDebugMessage('✅ Found ${rides.length} rides in history');
        return rides;
      }
      return [];
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      return [];
    }
  }

  static Future<Ride?> changeRideType(int rideId, String newRideType, String token) async {
    try {
      addDebugMessage('🔄 Changing ride type to $newRideType...');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/change-ride-type';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'rideType': newRideType}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        addDebugMessage('✅ Ride type changed to $newRideType');
        return Ride.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Error changing ride type: $e');
      return null;
    }
  }

  static Future<Ride?> continueSearch(int rideId, String token) async {
    try {
      addDebugMessage('🔄 Continuing search with expanded radius...');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/continue-search';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        addDebugMessage('✅ Search continued');
        return Ride.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Error continuing search: $e');
      return null;
    }
  }

  static Future<bool> cancelRide(int rideId, String token, {String reason = 'Cancelled by rider'}) async {
    try {
      addDebugMessage('❌ Cancelling ride...');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/cancel';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'reason': reason}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        addDebugMessage('✅ Ride cancelled');
        await StorageService.clearActiveRideId();
        return true;
      }
      final body = response.body;
      addDebugMessage('❌ Cancel returned ${response.statusCode}: $body');
      if (response.statusCode == 400 && (body.contains('already') || body.contains('COMPLETED') || body.contains('CANCELLED'))) {
        addDebugMessage('✅ Ride already finalised — clearing local state');
        await StorageService.clearActiveRideId();
        return true;
      }
      return false;
    } catch (e) {
      addDebugMessage('❌ Error cancelling ride: $e');
      return false;
    }
  }

  static Future<bool> driverArrived(int rideId, String token) async {
    try {
      addDebugMessage('📍 Notifying driver arrival...');

      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/driver-arrived';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        addDebugMessage('✅ Driver arrival notified');
        return true;
      }
      return false;
    } catch (e) {
      addDebugMessage('❌ Error notifying arrival: $e');
      return false;
    }
  }

  static Future<bool> updateDriverLocation({
    required int rideId,
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/rides/$rideId/location';

      await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(const Duration(seconds: 10));

      return true;
    } catch (e) {
      addDebugMessage('⚠️ Error updating location: $e');
      return false;
    }
  }

  /// Returns null on success, or error message string on failure.
  static Future<String?> confirmPayment(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/$rideId/confirm';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        addDebugMessage('✅ Payment confirmed for ride #$rideId');
        return null;
      }
      final body = response.body;
      addDebugMessage('❌ Payment confirm error: $body');
      String? msg;
      try {
        msg = jsonDecode(body)['error'] as String?;
      } catch (_) {}
      return msg ?? 'Payment confirmation failed (${response.statusCode})';
    } catch (e) {
      addDebugMessage('❌ Payment confirm exception: $e');
      return 'Network error: $e';
    }
  }

  static Future<bool> confirmPaymentReceived(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/$rideId/receive';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        addDebugMessage('✅ Payment received confirmed for ride #$rideId');
        return true;
      }
      addDebugMessage('❌ Payment receive error: ${response.body}');
      return false;
    } catch (e) {
      addDebugMessage('❌ Payment receive exception: $e');
      return false;
    }
  }

  static Future<bool> cashReceived(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/$rideId/cash-received';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        addDebugMessage('✅ Cash received confirmed for ride #$rideId');
        return true;
      }
      addDebugMessage('❌ Cash receive error: ${response.body}');
      return false;
    } catch (e) {
      addDebugMessage('❌ Cash receive exception: $e');
      return false;
    }
  }

  static Future<bool> cashUnpaid(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/$rideId/cash-unpaid';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        addDebugMessage('✅ Cash unpaid marked for ride #$rideId');
        return true;
      }
      addDebugMessage('❌ Cash unpaid error: ${response.body}');
      return false;
    } catch (e) {
      addDebugMessage('❌ Cash unpaid exception: $e');
      return false;
    }
  }

  static Future<bool> disputePayment(int rideId, String token, {String reason = 'Driver disputed payment'}) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/$rideId/dispute';
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'reason': reason}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        addDebugMessage('✅ Payment disputed for ride #$rideId');
        return true;
      }
      addDebugMessage('❌ Payment dispute error: ${response.body}');
      return false;
    } catch (e) {
      addDebugMessage('❌ Payment dispute exception: $e');
      return false;
    }
  }

  static Future<bool> submitRating({
    required int rideId,
    required int rating,
    required String feedback,
    required String token,
  }) async {
    try {
      addDebugMessage('⭐ Submitting rating: $rating stars');

      final url = '${StorageService.getServerUrl()}/api/ratings';

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'rideId': rideId, 'rating': rating, 'feedback': feedback}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        addDebugMessage('✅ Rating submitted');
        return true;
      }
      return false;
    } catch (e) {
      addDebugMessage('❌ Error submitting rating: $e');
      return false;
    }
  }

  static Future<int?> getPendingPaymentRideId(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/pending-ride';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['rideId'] as int?;
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Pending payment ride error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPaymentStatus(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/payments/$rideId/status';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      addDebugMessage('❌ Payment status error: $e');
      return null;
    }
  }

  static Future<bool> registerDeviceToken(String fcmToken, String token) async {
    try {
      final url = StorageService.getAuthDeviceTokenUrl();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: jsonEncode({'deviceToken': fcmToken, 'platform': platform}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      addDebugMessage('❌ Device token register: ${response.statusCode}');
      return false;
    } catch (e) {
      addDebugMessage('❌ Error registering device token: $e');
      return false;
    }
  }
}