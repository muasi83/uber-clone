import '../models/ride_model.dart';

/// Normalized driver-card fields, sourced from either the enriched REST ride
/// payload (`GET /api/rides/{id}`) or the WS `ride_accepted` payload.
class DriverCardData {
  final String? name;
  final String? photoUrl;
  final String? vehiclePhotoUrl;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? vehicleModel;
  final String? vehicleColor;
  final double? rating;

  const DriverCardData({
    this.name,
    this.photoUrl,
    this.vehiclePhotoUrl,
    this.vehicleType,
    this.vehicleNumber,
    this.vehicleModel,
    this.vehicleColor,
    this.rating,
  });

  /// Reads a payload map that may use WS keys (`driverPhotoUrl`,
  /// `driverVehiclePhotoUrl`, `driverRating`, `vehicleNumber`) or REST keys
  /// (`photoUrl`, `vehiclePhotoUrl`, `averageRating`, `vehicleType`).
  factory DriverCardData.fromMap(Map<String, dynamic> data) {
    String? s(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    double? d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
    return DriverCardData(
      name: s(data['driverName']) ?? s(data['fullName']),
      photoUrl: s(data['driverPhotoUrl']) ?? s(data['photoUrl']),
      vehiclePhotoUrl: s(data['driverVehiclePhotoUrl']) ?? s(data['vehiclePhotoUrl']),
      vehicleType: s(data['driverVehicleType']) ?? s(data['vehicleType']),
      vehicleNumber: s(data['driverVehicleNumber']) ??
          s(data['vehicleNumber']) ??
          s(data['licensePlate']),
      vehicleModel: s(data['driverVehicleModel']) ?? s(data['vehicleModel']),
      vehicleColor: s(data['driverVehicleColor']) ?? s(data['vehicleColor']),
      rating: d(data['driverRating']) ?? d(data['averageRating']),
    );
  }

  /// Builds from the enriched REST ride payload (`Ride.fromJson`).
  /// Blank/empty strings are sanitized to `null`, matching `fromMap`.
  factory DriverCardData.fromRide(Ride ride) {
    String? s(String? v) => v != null && v.trim().isNotEmpty ? v : null;
    return DriverCardData(
      name: s(ride.driver?.fullName),
      photoUrl: s(ride.driver?.photoUrl),
      vehiclePhotoUrl: s(ride.driverVehiclePhotoUrl),
      vehicleType: s(ride.driverVehicleType),
      vehicleNumber: s(ride.driverVehicleNumber),
      vehicleModel: s(ride.driverVehicleModel),
      vehicleColor: s(ride.driverVehicleColor),
      rating: ride.driverAverageRating,
    );
  }

  /// Canonical payload for navigation arguments. Only non-empty values are
  /// included so downstream rendering never sees placeholder empty strings.
  Map<String, dynamic> toPayloadMap() {
    return {
      if (name != null) 'driverName': name,
      if (photoUrl != null) 'driverPhotoUrl': photoUrl,
      if (vehiclePhotoUrl != null) 'driverVehiclePhotoUrl': vehiclePhotoUrl,
      if (vehicleType != null) 'driverVehicleType': vehicleType,
      if (vehicleNumber != null) 'driverVehicleNumber': vehicleNumber,
      if (vehicleModel != null) 'driverVehicleModel': vehicleModel,
      if (vehicleColor != null) 'driverVehicleColor': vehicleColor,
      if (rating != null) 'driverRating': rating,
    };
  }

  /// e.g. "CAR Toyota Camry White • AB-1234" (only the parts available).
  String get vehicleSummary {
    final parts = <String>[
      if (vehicleType != null) vehicleType!,
      if (vehicleModel != null) vehicleModel!,
      if (vehicleColor != null) vehicleColor!,
    ];
    final joined = parts.join(' ');
    if (vehicleNumber != null) {
      return joined.isNotEmpty ? '$joined • $vehicleNumber' : vehicleNumber!;
    }
    return joined;
  }
}
