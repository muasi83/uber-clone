import 'dart:math' as math;

double calculateHaversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
      math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRad(double deg) => deg * math.pi / 180;

String formatDuration(double minutes) {
  if (minutes < 1) return 'Less than 1 min';
  if (minutes < 60) return '${minutes.round()} min';
  final hours = minutes ~/ 60;
  final mins = minutes.round() % 60;
  return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
}

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

String formatFare(double fare) {
  return '\$${fare.toStringAsFixed(2)}';
}

double calculateEstimatedFare({
  required double distanceKm,
  required String rideType,
}) {
  double baseFare;
  double perKmRate;

  switch (rideType.toUpperCase()) {
    case 'LUXURY':
      baseFare = 6.0;
      perKmRate = 0.50;
      break;
    case 'COMFORT':
      baseFare = 4.0;
      perKmRate = 0.35;
      break;
    case 'ECONOMY':
    default:
      baseFare = 2.0;
      perKmRate = 0.20;
      break;
  }

  return baseFare + (distanceKm * perKmRate);
}
