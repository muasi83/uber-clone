import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ride_service.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

/// Cached + debounced wrapper around GET /api/rides/availability.
///
/// Contract (matches backend spec):
/// - debounce 500ms on rapid map/type changes;
/// - cache key = rideType + pickup rounded to ~3 decimals (~100m), TTL 45s;
/// - refresh on screen open, pickup move, type switch, onResume;
/// - fail-closed: unknown (no fresh cache + network error) => unavailable.
class AvailabilityResult {
  final bool available;
  final int count;
  final double radiusKm;
  final bool fromCache;
  const AvailabilityResult({
    required this.available,
    required this.count,
    required this.radiusKm,
    this.fromCache = false,
  });
}

class RideAvailabilityService {
  static const Duration ttl = Duration(seconds: 45);
  static const Duration debounce = Duration(milliseconds: 500);

  static String? _key;
  static AvailabilityResult? _cached;
  static DateTime? _cachedAt;
  static Timer? _debounceTimer;
  static Future<AvailabilityResult>? _inflight;
  static String? _inflightKey;

  static String keyFor(String rideType, double lat, double lng) =>
      '$rideType|${lat.toStringAsFixed(3)}|${lng.toStringAsFixed(3)}';

  static void invalidate() {
    _key = null;
    _cached = null;
    _cachedAt = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _inflight = null;
    _inflightKey = null;
  }

  /// Immediate cached read (null = unknown). Never triggers network.
  static AvailabilityResult? peek(String rideType, double lat, double lng) {
    if (_key == keyFor(rideType, lat, lng) &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < ttl) {
      return _cached;
    }
    return null;
  }

  /// Debounced probe. [onResult] fires on the state thread with the outcome.
  static void checkDebounced({
    required String rideType,
    required double lat,
    required double lng,
    double? radiusKm,
    void Function(AvailabilityResult result)? onResult,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      final result = await fetch(
        rideType: rideType,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      onResult?.call(result);
    });
  }

  static void cancelPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Fetch with cache + in-flight dedup. Unknown => unavailable (fail-closed).
  static Future<AvailabilityResult> fetch({
    required String rideType,
    required double lat,
    required double lng,
    double? radiusKm,
  }) async {
    final key = keyFor(rideType, lat, lng);
    final now = DateTime.now();
    if (_key == key && _cached != null && _cachedAt != null && now.difference(_cachedAt!) < ttl) {
      return AvailabilityResult(
        available: _cached!.available,
        count: _cached!.count,
        radiusKm: _cached!.radiusKm,
        fromCache: true,
      );
    }
    if (_inflight != null && _inflightKey == key) return _inflight!;

    final future = _fetchNetwork(
      rideType: rideType,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
    _inflight = future;
    _inflightKey = key;
    try {
      return await future;
    } finally {
      _inflight = null;
      _inflightKey = null;
    }
  }

  static Future<AvailabilityResult> _fetchNetwork({
    required String rideType,
    required double lat,
    required double lng,
    double? radiusKm,
  }) async {
    final key = keyFor(rideType, lat, lng);
    try {
      final token = StorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Availability: no auth token');
        return const AvailabilityResult(available: false, count: 0, radiusKm: 15.0);
      }
      final res = await RideService.checkAvailability(
        rideType: rideType,
        latitude: lat,
        longitude: lng,
        radiusKm: radiusKm,
        token: token,
      );
      if (res == null) {
        addDebugMessage('❌ Availability unknown for $rideType — treating as unavailable');
        return const AvailabilityResult(available: false, count: 0, radiusKm: 15.0);
      }
      final result = AvailabilityResult(
        available: res.available,
        count: res.count,
        radiusKm: res.radiusKm,
      );
      _key = key;
      _cached = result;
      _cachedAt = DateTime.now();
      return result;
    } catch (e) {
      addDebugMessage('❌ Availability exception: $e');
      return const AvailabilityResult(available: false, count: 0, radiusKm: 15.0);
    }
  }
}
