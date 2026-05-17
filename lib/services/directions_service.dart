import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../screens/debug_screen.dart';

class DirectionsService {
  // ✅ REPLACE WITH YOUR API KEY FROM ANDROID MANIFEST
  static const String _googleMapsApiKey = 'AIzaSyAzAVhrBKWMJZNrXyD9DGk6AZVM1yv2KiY';
  
  static const String _directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get directions between two points
  /// Returns: distance (km), duration (min), polyline points, address info
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔍 CALLING GOOGLE DIRECTIONS API');
      addDebugMessage('From: ${origin.latitude}, ${origin.longitude}');
      addDebugMessage('To: ${destination.latitude}, ${destination.longitude}');

      // Build URL for Google Directions API
      final String url =
          '$_directionsUrl?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$_googleMapsApiKey';

      addDebugMessage('📡 Sending request...');

      // Make HTTP request
      final response = await http.get(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          addDebugMessage('❌ TIMEOUT: Google Directions API took too long');
          throw TimeoutException('Directions API timeout');
        },
      );

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Check for errors
        final String status = json['status'] ?? 'UNKNOWN';
        
        if (status != 'OK') {
          addDebugMessage('❌ ERROR: $status');
          if (json['error_message'] != null) {
            addDebugMessage('Message: ${json['error_message']}');
          }
          return DirectionsResult(
            isSuccess: false,
            errorMessage: status,
          );
        }

        // Extract route data
        final List<dynamic> routes = json['routes'] ?? [];
        if (routes.isEmpty) {
          addDebugMessage('❌ No routes found');
          return DirectionsResult(
            isSuccess: false,
            errorMessage: 'No route found',
          );
        }

        final route = routes[0]; // First route (best)
        final List<dynamic> legs = route['legs'] ?? [];
        
        if (legs.isEmpty) {
          addDebugMessage('❌ No legs in route');
          return DirectionsResult(
            isSuccess: false,
            errorMessage: 'Invalid route data',
          );
        }

        final leg = legs[0];

        // Extract distance
        final distanceData = leg['distance'] ?? {};
        final int distanceMeters = distanceData['value'] ?? 0;
        final String distanceText = distanceData['text'] ?? '0 km';
        final double distanceKm = distanceMeters / 1000;

        // Extract duration
        final durationData = leg['duration'] ?? {};
        final int durationSeconds = durationData['value'] ?? 0;
        final String durationText = durationData['text'] ?? '0 mins';
        final int durationMinutes = durationSeconds ~/ 60;

        // Extract addresses
        final String startAddress = leg['start_address'] ?? 'Unknown';
        final String endAddress = leg['end_address'] ?? 'Unknown';

        // Extract polyline (encoded)
        final overviewPolyline = route['overview_polyline'] ?? {};
        final String encodedPolyline = overviewPolyline['points'] ?? '';
        final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);

        addDebugMessage('✅ DIRECTIONS RECEIVED');
        addDebugMessage('Distance: ${distanceKm.toStringAsFixed(2)} km');
        addDebugMessage('Duration: $durationMinutes min');
        addDebugMessage('Polyline points: ${polylinePoints.length}');
        addDebugMessage('Start Address: $startAddress');
        addDebugMessage('End Address: $endAddress');
        addDebugMessage('═══════════════════════════════════════');

        return DirectionsResult(
          distanceKm: distanceKm,
          distanceMeters: distanceMeters,
          durationMinutes: durationMinutes,
          durationSeconds: durationSeconds,
          polylinePoints: polylinePoints,
          startAddress: startAddress,
          endAddress: endAddress,
          encodedPolyline: encodedPolyline,
          isSuccess: true,
        );
      } else {
        addDebugMessage('❌ HTTP ERROR: ${response.statusCode}');
        addDebugMessage('Response: ${response.body}');
        return DirectionsResult(
          isSuccess: false,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      addDebugMessage('❌ SOCKET ERROR: $e');
      return DirectionsResult(
        isSuccess: false,
        errorMessage: 'Connection error: ${e.message}',
      );
    } catch (e) {
      addDebugMessage('❌ EXCEPTION: $e');
      return DirectionsResult(
        isSuccess: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  /// Decode polyline points from Google's encoded format
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;

      // Decode longitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(
        LatLng(
          lat / 1e5,
          lng / 1e5,
        ),
      );
    }

    return points;
  }

  /// Get formatted distance string
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }

  /// Get formatted duration string
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours h $mins min';
  }

  /// Calculate fare based on distance and ride type
  static double calculateFare(double distanceKm, String rideType) {
    const double baseFare = 2.0;
    final double ratePerKm = rideType == 'LUXURY' ? 0.35 : 0.20;
    final double fare = baseFare + (distanceKm * ratePerKm);

    // Round to 2 decimal places
    return (fare * 100).roundToDouble() / 100;
  }
}

/// Result object from directions API
class DirectionsResult {
  final bool isSuccess;
  final double? distanceKm;
  final int? distanceMeters;
  final int? durationMinutes;
  final int? durationSeconds;
  final List<LatLng>? polylinePoints;
  final String? startAddress;
  final String? endAddress;
  final String? encodedPolyline;
  final String? errorMessage;

  DirectionsResult({
    required this.isSuccess,
    this.distanceKm,
    this.distanceMeters,
    this.durationMinutes,
    this.durationSeconds,
    this.polylinePoints,
    this.startAddress,
    this.endAddress,
    this.encodedPolyline,
    this.errorMessage,
  });
}