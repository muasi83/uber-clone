import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../screens/debug_screen.dart';
import 'storage_service.dart';

class DirectionsResult {
  final bool isSuccess;
  final double? distanceKm;
  final int? durationMinutes;
  final List<LatLng>? polylinePoints;
  final String? fallbackWarning;

  const DirectionsResult({
    required this.isSuccess,
    this.distanceKm,
    this.durationMinutes,
    this.polylinePoints,
    this.fallbackWarning,
  });
}

class DirectionsService {
  static String _normalizeToken(String token) {
    var t = token.trim();
    if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
      t = t.substring(1, t.length - 1).trim();
    }
    if (t.toLowerCase().startsWith('bearer ')) {
      t = t.substring(7).trim();
    }
    return t;
  }

  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🧭 CALLING BACKEND ROUTE API');
      addDebugMessage('From: ${origin.latitude}, ${origin.longitude}');
      addDebugMessage('To: ${destination.latitude}, ${destination.longitude}');
      addDebugMessage('📡 Sending request...');

      final straightKm = _haversineKm(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );

      if (straightKm < 0.03) {
        addDebugMessage('⚠️ Origin and destination too close. Skipping route call.');
        return const DirectionsResult(
          isSuccess: false,
          distanceKm: 0,
          durationMinutes: 0,
          polylinePoints: [],
          fallbackWarning: 'Origin and destination are too close',
        );
      }

      final baseUrl = StorageService.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/routes/calculate').replace(
        queryParameters: {
          'originLat': origin.latitude.toString(),
          'originLng': origin.longitude.toString(),
          'destLat': destination.latitude.toString(),
          'destLng': destination.longitude.toString(),
        },
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

      final token = StorageService.getToken();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_normalizeToken(token)}';
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      addDebugMessage('✅ Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        addDebugMessage('❌ Backend route API error: ${response.body}');
        return _fallback(origin, destination, warning: 'Backend route API failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final distanceKm = (data['totalDistanceKm'] as num?)?.toDouble();
      final durationMin = (data['totalDurationMinutes'] as num?)?.toInt();
      final warning = data['fallbackWarning'] as String?;

      final points = <LatLng>[];
      final rawPoints = data['polylinePoints'];
      if (rawPoints is List) {
        for (final p in rawPoints) {
          if (p is Map) {
            final lat = (p['lat'] as num?)?.toDouble();
            final lng = (p['lng'] as num?)?.toDouble();
            if (lat != null && lng != null) points.add(LatLng(lat, lng));
          }
        }
      }

      addDebugMessage('🧭 Polyline points: ${points.length}');
      if (warning != null && warning.isNotEmpty) {
        addDebugMessage('⚠️ Backend warning: $warning');
      }

      if (points.isEmpty || distanceKm == null || durationMin == null) {
        addDebugMessage('⚠️ Backend returned empty route. Using fallback.');
        return _fallback(origin, destination, warning: warning ?? 'Empty route from backend');
      }

      return DirectionsResult(
        isSuccess: true,
        distanceKm: distanceKm,
        durationMinutes: durationMin,
        polylinePoints: points,
        fallbackWarning: warning,
      );
    } catch (e) {
      addDebugMessage('❌ EXCEPTION (backend route): $e');
      return _fallback(origin, destination, warning: 'Exception calling backend route');
    }
  }

  static double calculateFare(double distanceKm, String rideType) {
    const base = 2.0;
    final rate = rideType == 'LUXURY' ? 0.35 : 0.20;
    return base + (distanceKm * rate);
  }

  static DirectionsResult _fallback(
    LatLng origin,
    LatLng destination, {
    String? warning,
  }) {
    final km = _haversineKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    final minutes = (km / 35.0 * 60.0).round().clamp(1, 9999);

    addDebugMessage('⚠️ Using fallback route: ${km.toStringAsFixed(2)} km, ~$minutes min');

    return DirectionsResult(
      isSuccess: true,
      distanceKm: km,
      durationMinutes: minutes,
      polylinePoints: <LatLng>[origin, destination],
      fallbackWarning: warning ?? 'Fallback to straight-line estimate',
    );
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}