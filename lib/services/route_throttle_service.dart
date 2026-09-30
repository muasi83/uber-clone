import 'dart:async';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../screens/debug_screen.dart';

/// Trip-scoped throttle for paid route recalculations.
///
/// Route/ETA display is read-only UI (billing and trip state never use it),
/// so recalculation frequency is a pure cost knob. Policy (locked spec):
/// - recalc when distance since last call >= 500m OR time since last call >= 30s
/// - 1500ms debounce kept as burst backstop
/// - timestamps stamped on ATTEMPT (never retry-storm on failure)
/// - arrival-radius exception does NOT bypass route throttling (fix
///   processing/markers stay per-fix elsewhere; only route calls are gated)
///
/// Two cross-screen gotchas handled here instead of in widgets:
/// 1. State is trip-scoped (keyed by rideId), NOT per-screen: navigating
///    between trip screens never resets the throttle (no fresh-start burst).
/// 2. In-flight serialization: triggers arriving while a request is running
///    are dropped (the next fix re-triggers), so slow networks can't overlap
///    calls past the intended rate.
///
/// Operational effect: ~2 calls/min floor while active (30s backstop) plus
/// ~1 per 500m driven. Formula per trip:
///   calls ≈ max(distanceKm / 0.5, durationSeconds / 30) + screen-entry primes.
class RouteThrottleService {
  static const double minDistanceM = 500;
  static const Duration maxStale = Duration(seconds: 30);
  static const Duration debounce = Duration(milliseconds: 1500);

  static int? _rideId;
  static DateTime? _lastAttemptAt;
  static LatLng? _lastAttemptFix;
  static Timer? _debounceTimer;
  static bool _inFlight = false;

  static void _resetIfNewTrip(int rideId) {
    if (_rideId == rideId) return;
    _rideId = rideId;
    _lastAttemptAt = null;
    _lastAttemptFix = null;
    _inFlight = false;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Evaluate thresholds on a processed GPS fix; schedule a (debounced,
  /// serialized) route request if tripped. Safe to call per fix.
  static void maybeRequestRoute({
    required int rideId,
    required LatLng fix,
    required Future<void> Function() request,
  }) {
    _resetIfNewTrip(rideId);
    final now = DateTime.now();
    final distOk = _lastAttemptFix == null ||
        _distanceMeters(_lastAttemptFix!, fix) >= minDistanceM;
    final timeOk =
        _lastAttemptAt == null || now.difference(_lastAttemptAt!) >= maxStale;
    if (!distOk && !timeOk) return;
    _schedule(rideId, fix, request);
  }

  /// Screen-entry first call (e.g. entering navigation/active-ride screens).
  /// Bypasses distance/time thresholds — bounded because screen entries are
  /// rare (couple per trip) — but still debounced + serialized like the rest.
  static void primeRoute({
    required int rideId,
    required LatLng fix,
    required Future<void> Function() request,
  }) {
    _resetIfNewTrip(rideId);
    _schedule(rideId, fix, request);
  }

  static void _schedule(
      int rideId, LatLng fix, Future<void> Function() request) {
    if (_inFlight) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      if (_rideId != rideId || _inFlight) return;
      _inFlight = true;
      // Stamp on attempt (not success): failures must not cause retry storms.
      _lastAttemptAt = DateTime.now();
      _lastAttemptFix = fix;
      try {
        await request();
      } catch (e) {
        addDebugMessage('⚠️ Throttled route request failed: $e');
      } finally {
        _inFlight = false;
      }
    });
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLng / 2);
    final h = s1 * s1 +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            s2 *
            s2;
    return 2 * earthRadius * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  static double _toRadians(double deg) => deg * math.pi / 180.0;
}
