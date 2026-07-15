class ScheduledRide {
  final int? id;
  final int riderId;
  final String riderUsername;
  final String? riderFullName;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final DateTime scheduledAt;
  final String status;
  final String? pickupCode;
  final String? rideType;
  final double? estimatedFare;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? expiredAt;

  ScheduledRide({
    this.id,
    required this.riderId,
    required this.riderUsername,
    this.riderFullName,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.scheduledAt,
    required this.status,
    this.pickupCode,
    this.rideType,
    this.estimatedFare,
    this.estimatedDistance,
    this.estimatedDuration,
    this.createdAt,
    this.assignedAt,
    this.arrivedAt,
    this.startedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.expiredAt,
  });

  bool get isScheduled => status == 'SCHEDULED';
  bool get isAssigned => status == 'ASSIGNED';
  bool get isDriverArrived => status == 'DRIVER_ARRIVED';
  bool get isStarted => status == 'STARTED';
  bool get isExpired => status == 'EXPIRED';

  factory ScheduledRide.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }
    return ScheduledRide(
      id: json['id'] as int?,
      riderId: json['riderId'] as int? ?? 0,
      riderUsername: json['riderUsername'] as String? ?? '',
      riderFullName: json['riderFullName'] as String?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      pickupLatitude: toDouble(json['pickupLatitude']) ?? 0.0,
      pickupLongitude: toDouble(json['pickupLongitude']) ?? 0.0,
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropoffLatitude: toDouble(json['dropoffLatitude']) ?? 0.0,
      dropoffLongitude: toDouble(json['dropoffLongitude']) ?? 0.0,
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      scheduledAt: parseDate(json['scheduledAt']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'SCHEDULED',
      pickupCode: json['pickupCode'] as String?,
      rideType: json['rideType'] as String?,
      estimatedFare: toDouble(json['estimatedFare']),
      estimatedDistance: toDouble(json['estimatedDistance']),
      estimatedDuration: toInt(json['estimatedDuration']),
      createdAt: parseDate(json['createdAt']),
      assignedAt: parseDate(json['assignedAt']),
      arrivedAt: parseDate(json['arrivedAt']),
      startedAt: parseDate(json['startedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      cancellationReason: json['cancellationReason'] as String?,
      expiredAt: parseDate(json['expiredAt']),
    );
  }
}
