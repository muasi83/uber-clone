// ignore_for_file: avoid_print

class RideVerification {
  final int? rideId;
  final String? verificationStatus;
  final int? verificationScore;
  final double? actualKm;
  final double? estimatedKm;
  final double? distanceDifference;
  final int? actualDuration;
  final int? estimatedDuration;
  final bool? pickupReached;
  final bool? dropoffReached;
  final bool? movementDetected;
  final String? gpsQuality;
  final List<String> verificationReasons;
  final int? algorithmVersion;
  final DateTime? computedAt;

  RideVerification({
    this.rideId,
    this.verificationStatus,
    this.verificationScore,
    this.actualKm,
    this.estimatedKm,
    this.distanceDifference,
    this.actualDuration,
    this.estimatedDuration,
    this.pickupReached,
    this.dropoffReached,
    this.movementDetected,
    this.gpsQuality,
    this.verificationReasons = const [],
    this.algorithmVersion,
    this.computedAt,
  });

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isSuspicious => verificationStatus == 'SUSPICIOUS';
  bool get isFailed => verificationStatus == 'FAILED';

  factory RideVerification.fromJson(Map<String, dynamic> json) {
    return RideVerification(
      rideId: json['rideId'] as int?,
      verificationStatus: json['verificationStatus'] as String?,
      verificationScore: json['verificationScore'] as int?,
      actualKm: (json['actualKm'] as num?)?.toDouble(),
      estimatedKm: (json['estimatedKm'] as num?)?.toDouble(),
      distanceDifference: (json['distanceDifference'] as num?)?.toDouble(),
      actualDuration: json['actualDuration'] as int?,
      estimatedDuration: json['estimatedDuration'] as int?,
      pickupReached: json['pickupReached'] as bool?,
      dropoffReached: json['dropoffReached'] as bool?,
      movementDetected: json['movementDetected'] as bool?,
      gpsQuality: json['gpsQuality'] as String?,
      verificationReasons: (json['verificationReasons'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      algorithmVersion: json['algorithmVersion'] as int?,
      computedAt: json['computedAt'] != null
          ? DateTime.tryParse(json['computedAt'] as String)
          : null,
    );
  }
}
