import 'models.dart';

class Ride {
  final int? id;
  final User rider;
  final User? driver;
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

  Ride({
    this.id,
    required this.rider,
    this.driver,
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
  };

  Ride copyWith({
    int? id,
    User? rider,
    User? driver,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    String? status,
    String? rideType,
    double? estimatedFare,
    double? finalFare,
    double? estimatedDistance,
    int? estimatedDuration,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      rider: rider ?? this.rider,
      driver: driver ?? this.driver,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      status: status ?? this.status,
      rideType: rideType ?? this.rideType,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      finalFare: finalFare ?? this.finalFare,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
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
  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  String _toString(dynamic value, String defaultValue) {
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
      licenseNumber: _toString(json['licenseNumber'], 'N/A'),
      vehicleNumber: _toString(json['vehicleNumber'], 'N/A'),
      vehicleType: _toString(json['vehicleType'], 'CAR'),
      vehicleModel: _toString(json['vehicleModel'], 'Unknown'),
      vehicleColor: _toString(json['vehicleColor'], 'Unknown'),
      isVerified: _toBool(json['isVerified']),
      isActive: _toBool(json['isActive']),
      averageRating: ((json['averageRating'] as num?) ?? 5.0).toDouble(),
      totalRides: (json['totalRides'] as int?) ?? 0,
      currentLatitude: json['currentLatitude'] != null 
          ? (json['currentLatitude'] as num).toDouble() 
          : null,
      currentLongitude: json['currentLongitude'] != null 
          ? (json['currentLongitude'] as num).toDouble() 
          : null,
      isOnline: _toBool(json['isOnline']),
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


// Add this enum to your existing file
enum RideStep { 
  initial,           // Show map with pickup/dropoff buttons
  pickupConfirmed,   // Pickup button gray, dropoff active
  dropoffConfirmed,  // Both buttons gray, confirm ride button shows
  routeReady,        // Show route, waiting to request
  searching,         // Searching for drivers
  driverFound,       // Driver details showing
}