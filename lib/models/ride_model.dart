// ignore_for_file: avoid_print
import 'models.dart';

class Ride {
  final int? id;
  final User rider;
  final User? driver;
  final double? driverAverageRating;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final String status;
  final String rideType;
  final double? estimatedFare;
  final double? finalFare;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? driverArrivedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final double? searchRadiusKm;
  final String? selectedRideType;

  Ride({
    this.id,
    required this.rider,
    this.driver,
    this.driverAverageRating,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.status,
    required this.rideType,
    this.estimatedFare,
    this.finalFare,
    this.estimatedDistance,
    this.estimatedDuration,
    this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.driverArrivedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.searchRadiusKm,
    this.selectedRideType,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    try {
      // Safe converters
      double? toDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      int? toInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return Ride(
        id: json['id'] as int?,
        rider: json['rider'] != null 
            ? User.fromJson(json['rider'] as Map<String, dynamic>)
            : User(
                email: 'unknown@test.com',
                password: '',
                fullName: 'Unknown User',
              ),
        driver: json['driver'] != null 
            ? User.fromJson(json['driver'] as Map<String, dynamic>) 
            : null,
        driverAverageRating: json['driver'] is Map<String, dynamic>
            ? (json['driver']['averageRating'] as num?)?.toDouble()
            : null,
        pickupLatitude: toDouble(json['pickupLatitude']) ?? 0.0,
        pickupLongitude: toDouble(json['pickupLongitude']) ?? 0.0,
        pickupAddress: json['pickupAddress'] as String? ?? 'Unknown',
        dropoffLatitude: toDouble(json['dropoffLatitude']) ?? 0.0,
        dropoffLongitude: toDouble(json['dropoffLongitude']) ?? 0.0,
        dropoffAddress: json['dropoffAddress'] as String? ?? 'Unknown',
        status: json['status'] as String? ?? 'REQUESTED',
        rideType: json['rideType'] as String? ?? 'ECONOMY',
        estimatedFare: toDouble(json['estimatedFare']),
        finalFare: toDouble(json['finalFare']),
        estimatedDistance: toDouble(json['estimatedDistance']),
        estimatedDuration: toInt(json['estimatedDuration']),
        requestedAt: json['requestedAt'] != null
            ? DateTime.parse(json['requestedAt'] as String)
            : null,
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'] as String)
            : null,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        driverArrivedAt: json['driverArrivedAt'] != null
            ? DateTime.parse(json['driverArrivedAt'] as String)
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'] as String)
            : null,
        cancellationReason: json['cancellationReason'] as String?,
        searchRadiusKm: json['searchRadiusKm'] != null
            ? (json['searchRadiusKm'] as num).toDouble()
            : null,
        selectedRideType: json['selectedRideType'] as String?,
      );
    } catch (e) {
      print('❌ Error parsing Ride: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rider': rider.toJson(),
    'driver': driver?.toJson(),
    'driverAverageRating': driverAverageRating,
    'pickupLatitude': pickupLatitude,
    'pickupLongitude': pickupLongitude,
    'pickupAddress': pickupAddress,
    'dropoffLatitude': dropoffLatitude,
    'dropoffLongitude': dropoffLongitude,
    'dropoffAddress': dropoffAddress,
    'status': status,
    'rideType': rideType,
    'estimatedFare': estimatedFare,
    'finalFare': finalFare,
    'estimatedDistance': estimatedDistance,
    'estimatedDuration': estimatedDuration,
    'requestedAt': requestedAt?.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'driverArrivedAt': driverArrivedAt?.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'cancellationReason': cancellationReason,
    'searchRadiusKm': searchRadiusKm,
    'selectedRideType': selectedRideType,
  };

}

class DriverProfile {
  final int? id;
  final User user;
  final String? licenseNumber;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;
  final bool isVerified;
  final bool isActive;
  final double averageRating;
  final int totalRides;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isOnline;

  DriverProfile({
    this.id,
    required this.user,
    this.licenseNumber,
    this.vehicleNumber,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    required this.isVerified,
    required this.isActive,
    required this.averageRating,
    required this.totalRides,
    this.currentLatitude,
    this.currentLongitude,
    required this.isOnline,
  });

factory DriverProfile.fromJson(Map<String, dynamic> json) {
  bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  String toString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  try {
    // Parse user safely
    final userData = json['user'] as Map<String, dynamic>?;
    User user;
    
    if (userData != null) {
      user = User.fromJson(userData);
    } else {
      // Fallback user if missing
      user = User(
        id: null,
        username: 'Unknown',
        email: 'unknown@test.com',
        password: '',
        fullName: 'Unknown Driver',
      );
    }

    return DriverProfile(
      id: json['id'] as int?,
      user: user,
      licenseNumber: toString(json['licenseNumber'], 'N/A'),
      vehicleNumber: toString(json['vehicleNumber'], 'N/A'),
      vehicleType: toString(json['vehicleType'], 'CAR'),
      vehicleModel: toString(json['vehicleModel'], 'Unknown'),
      vehicleColor: toString(json['vehicleColor'], 'Unknown'),
      isVerified: toBool(json['isVerified']),
      isActive: toBool(json['isActive']),
      averageRating: ((json['averageRating'] as num?) ?? 5.0).toDouble(),
      totalRides: (json['totalRides'] as int?) ?? 0,
      currentLatitude: json['currentLatitude'] != null 
          ? (json['currentLatitude'] as num).toDouble() 
          : null,
      currentLongitude: json['currentLongitude'] != null 
          ? (json['currentLongitude'] as num).toDouble() 
          : null,
      isOnline: toBool(json['isOnline']),
    );
  } catch (e) {
    print('❌ Error parsing DriverProfile: $e');
    print('JSON: $json');
    rethrow;
  }
}

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user.toJson(),
    'licenseNumber': licenseNumber,
    'vehicleNumber': vehicleNumber,
    'vehicleType': vehicleType,
    'vehicleModel': vehicleModel,
    'vehicleColor': vehicleColor,
    'isVerified': isVerified,
    'isActive': isActive,
    'averageRating': averageRating,
    'totalRides': totalRides,
    'currentLatitude': currentLatitude,
    'currentLongitude': currentLongitude,
    'isOnline': isOnline,
  };
}
