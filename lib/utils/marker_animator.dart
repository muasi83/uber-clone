import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class AnimatedMarkerState {
  final MarkerId markerId;
  LatLng currentPosition;
  LatLng targetPosition;
  LatLng fromPosition;
  double animationProgress;
  final BitmapDescriptor icon;
  final double anchorU;
  final double anchorV;
  bool flat;
  InfoWindow? infoWindow;
  double rotation;
  Timer? _timer;

  AnimatedMarkerState({
    required this.markerId,
    required this.currentPosition,
    required this.targetPosition,
    required this.fromPosition,
    this.animationProgress = 1.0,
    required this.icon,
    this.anchorU = 0.5,
    this.anchorV = 0.5,
    this.flat = false,
    this.infoWindow,
    this.rotation = 0,
  });

  Marker buildMarker() {
    return Marker(
      markerId: markerId,
      position: currentPosition,
      icon: icon,
      flat: flat,
      infoWindow: infoWindow ?? const InfoWindow(title: ''),
      rotation: rotation,
    );
  }
}

class MarkerAnimator {
  static final Map<String, AnimatedMarkerState> _states = {};
  static Timer? _globalTimer;

  static void updatePosition({
    required String id,
    required LatLng newPosition,
    required BitmapDescriptor icon,
    double anchorU = 0.5,
    double anchorV = 0.5,
    bool flat = false,
    InfoWindow? infoWindow,
    double rotation = 0,
    int durationMs = 1000,
    void Function(Marker)? onUpdate,
  }) {
    final existing = _states[id];
    if (existing != null) {
      final from = existing.currentPosition;
      existing.fromPosition = from;
      existing.targetPosition = newPosition;
      existing.animationProgress = 0.0;
      existing.rotation = rotation;
      existing.infoWindow = infoWindow;
    } else {
      _states[id] = AnimatedMarkerState(
        markerId: MarkerId(id),
        currentPosition: newPosition,
        targetPosition: newPosition,
        fromPosition: newPosition,
        icon: icon,
        anchorU: anchorU,
        anchorV: anchorV,
        flat: flat,
        infoWindow: infoWindow,
        rotation: rotation,
      );
    }

    _startAnimator(durationMs, onUpdate);
  }

  static void _startAnimator(int durationMs, void Function(Marker)? onUpdate) {
    _globalTimer?.cancel();
    final tickMs = 16;
    final totalTicks = (durationMs / tickMs).ceil();
    var tick = 0;

    _globalTimer = Timer.periodic(Duration(milliseconds: tickMs), (_) {
      tick++;
      final progress = (tick / totalTicks).clamp(0.0, 1.0);
      final eased = _easeOutCubic(progress);

      for (final entry in _states.entries) {
        final state = entry.value;
        if (state.targetPosition == state.fromPosition) {
          state.animationProgress = 1.0;
          continue;
        }
        state.animationProgress = progress;
        state.currentPosition = LatLng(
          state.fromPosition.latitude +
              (state.targetPosition.latitude - state.fromPosition.latitude) *
                  eased,
          state.fromPosition.longitude +
              (state.targetPosition.longitude - state.fromPosition.longitude) *
                  eased,
        );
        onUpdate?.call(state.buildMarker());
      }

      if (tick >= totalTicks) {
        _globalTimer?.cancel();
        _globalTimer = null;
        for (final entry in _states.entries) {
          final state = entry.value;
          state.currentPosition = state.targetPosition;
          state.animationProgress = 1.0;
          onUpdate?.call(state.buildMarker());
        }
      }
    });
  }

  static double _easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3).toDouble();
  }

  static void removeMarker(String id) {
    _states.remove(id);
  }

  static void clear() {
    _states.clear();
    _globalTimer?.cancel();
    _globalTimer = null;
  }

  static Marker? getCurrentMarker(String id) {
    final state = _states[id];
    if (state == null) return null;
    return state.buildMarker();
  }
}
