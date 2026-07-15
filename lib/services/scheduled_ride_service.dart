import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scheduled_ride.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class ScheduledRideService {
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
      headers['Authorization'] = 'Bearer ${_normalizeToken(token)}';
    }
    return headers;
  }

  static Future<ScheduledRide?> create({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required DateTime scheduledAt,
    required String token,
    String? rideType,
    double? estimatedFare,
    double? estimatedDistance,
    int? estimatedDuration,
  }) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides';
      final body = {
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLatitude': dropoffLat,
        'dropoffLongitude': dropoffLng,
        'dropoffAddress': dropoffAddress,
        'scheduledAt': scheduledAt.toIso8601String(),
        'rideType': rideType ?? 'ECONOMY',
        'estimatedFare': estimatedFare,
        'estimatedDistance': estimatedDistance,
        'estimatedDuration': estimatedDuration,
      };

      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('Scheduled ride created: ID ${json['id']}');
        return ScheduledRide.fromJson(json);
      }
      addDebugMessage('Error creating scheduled ride: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      addDebugMessage('Exception creating scheduled ride: $e');
      return null;
    }
  }

  static Future<List<ScheduledRide>> getUpcoming(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/upcoming';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token, json: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => ScheduledRide.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      addDebugMessage('Exception fetching upcoming rides: $e');
      return [];
    }
  }

  static Future<List<ScheduledRide>> getPast(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/past';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token, json: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => ScheduledRide.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      addDebugMessage('Exception fetching past scheduled rides: $e');
      return [];
    }
  }

  static Future<bool> cancel(int rideId, String token, {String? reason}) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/cancel';
      final body = reason != null ? {'reason': reason} : {};
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        addDebugMessage('Scheduled ride $rideId cancelled');
        return true;
      }
      addDebugMessage('Error cancelling scheduled ride: ${response.statusCode}');
      return false;
    } catch (e) {
      addDebugMessage('Exception cancelling scheduled ride: $e');
      return false;
    }
  }

  static Future<bool> complete(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/complete';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        addDebugMessage('Scheduled ride $rideId completed');
        return true;
      }
      return false;
    } catch (e) {
      addDebugMessage('Exception completing scheduled ride: $e');
      return false;
    }
  }

  static Future<ScheduledRide?> getById(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token, json: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ScheduledRide.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      addDebugMessage('Exception fetching scheduled ride: $e');
      return null;
    }
  }

  static Future<List<ScheduledRide>> getNearby({
    required double lat,
    required double lng,
    required String token,
    double radius = 50,
  }) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/nearby?lat=$lat&lng=$lng&radius=$radius';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token, json: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => ScheduledRide.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      addDebugMessage('Exception fetching nearby scheduled rides: $e');
      return [];
    }
  }

  static Future<ScheduledRide?> assign(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/assign';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('Scheduled ride $rideId assigned');
        return ScheduledRide.fromJson(json);
      }
      addDebugMessage('Error assigning scheduled ride: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      addDebugMessage('Exception assigning scheduled ride: $e');
      return null;
    }
  }

  static Future<List<ScheduledRide>> getDriverUpcoming(String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/driver/upcoming';
      final response = await http
          .get(Uri.parse(url), headers: _headers(token: token, json: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => ScheduledRide.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      addDebugMessage('Exception fetching driver upcoming rides: $e');
      return [];
    }
  }

  static Future<bool> verifyCode(int rideId, String code, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/verify-code';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token), body: jsonEncode({'code': code}))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['valid'] == true;
      }
      return false;
    } catch (e) {
      addDebugMessage('Exception verifying code: $e');
      return false;
    }
  }

  static Future<ScheduledRide?> unassign(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/unassign';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        addDebugMessage('Scheduled ride $rideId unassigned');
        return ScheduledRide.fromJson(json);
      }
      addDebugMessage('Error unassigning scheduled ride: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      addDebugMessage('Exception unassigning scheduled ride: $e');
      return null;
    }
  }

  static Future<ScheduledRide?> markArrived(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/arrive';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ScheduledRide.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      addDebugMessage('Exception marking arrived: $e');
      return null;
    }
  }

  static Future<ScheduledRide?> start(int rideId, String token) async {
    try {
      final url = '${StorageService.getServerUrl()}/api/scheduled-rides/$rideId/start';
      final response = await http
          .post(Uri.parse(url), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ScheduledRide.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      addDebugMessage('Exception starting scheduled ride: $e');
      return null;
    }
  }
}
