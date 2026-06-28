import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculateBearing(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLng = (to.longitude - from.longitude) * math.pi / 180;

  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

  final bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}

double calculateCarRotation(LatLng from, LatLng to) {
  final bearing = calculateBearing(from, to);
  return (bearing + 180) % 360;
}

double normalizeCarHeading(double heading) => (heading + 180) % 360;
