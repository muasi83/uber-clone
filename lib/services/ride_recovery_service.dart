import '../models/ride_model.dart';

enum RideDestination {
  searching,
  tracking,
  activeRide,
  completed,
  cancelled,
}

class RecoveryTarget {
  final RideDestination destination;
  final Map<String, dynamic>? arguments;
  final bool canResume;
  final String? message;

  const RecoveryTarget({
    required this.destination,
    this.arguments,
    this.canResume = true,
    this.message,
  });
}

class RideRecoveryService {
  static RecoveryTarget getRecoveryTarget(Ride ride) {
    switch (ride.status) {
      case 'REQUESTED':
        return RecoveryTarget(
          destination: RideDestination.searching,
          arguments: {
            'rideId': ride.id,
            'pickupAddress': ride.pickupAddress,
            'dropoffAddress': ride.dropoffAddress,
            'estimatedFare': ride.estimatedFare ?? 0.0,
          },
        );
      case 'ACCEPTED':
      case 'DRIVER_ARRIVED':
        return RecoveryTarget(
          destination: RideDestination.tracking,
          arguments: {
            'rideId': ride.id,
            'driverData': <String, dynamic>{
              'driverId': ride.driver?.id,
              'driverName': ride.driver?.fullName,
              'pickupLatitude': ride.pickupLatitude,
              'pickupLongitude': ride.pickupLongitude,
              'pickupAddress': ride.pickupAddress,
              'dropoffLatitude': ride.dropoffLatitude,
              'dropoffLongitude': ride.dropoffLongitude,
              'dropoffAddress': ride.dropoffAddress,
              'estimatedFare': ride.estimatedFare,
              'estimatedDistance': ride.estimatedDistance,
              'estimatedDuration': ride.estimatedDuration,
              'averageRating': ride.driverAverageRating,
            },
          },
        );
      case 'STARTED':
        return RecoveryTarget(
          destination: RideDestination.activeRide,
          arguments: {
            'rideId': ride.id,
            'pickupLat': ride.pickupLatitude,
            'pickupLng': ride.pickupLongitude,
            'dropoffLat': ride.dropoffLatitude,
            'dropoffLng': ride.dropoffLongitude,
            'dropoffAddress': ride.dropoffAddress,
          },
        );
      case 'COMPLETED':
        return RecoveryTarget(
          destination: RideDestination.completed,
          arguments: {
            'rideId': ride.id,
            'totalFare': ride.finalFare ?? ride.estimatedFare,
            'distance': ride.estimatedDistance,
            'duration': ride.estimatedDuration,
          },
          canResume: false,
          message: 'Ride already completed.',
        );
      case 'CANCELLED':
      case 'CANCELED':
        return const RecoveryTarget(
          destination: RideDestination.cancelled,
          canResume: false,
          message: 'Ride already cancelled.',
        );
      default:
        return RecoveryTarget(
          destination: RideDestination.cancelled,
          canResume: false,
          message: 'Cannot resume ride with status "${ride.status}"',
        );
    }
  }
}
