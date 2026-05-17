class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String? placeId;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.placeId,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'placeId': placeId,
    'timestamp': timestamp?.toIso8601String(),
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    address: json['address'] as String,
    placeId: json['placeId'] as String?,
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'] as String)
        : null,
  );

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? placeId,
    DateTime? timestamp,
  }) => LocationData(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    address: address ?? this.address,
    placeId: placeId ?? this.placeId,
    timestamp: timestamp ?? this.timestamp,
  );
}

class RideType {
  final String name;
  final String icon;
  final double baseFare;
  final double perKmRate;
  final String description;

  RideType({
    required this.name,
    required this.icon,
    required this.baseFare,
    required this.perKmRate,
    required this.description,
  });
}

// Predefined ride types
final List<RideType> rideTypes = [
  RideType(
    name: 'Economy',
    icon: '🚗',
    baseFare: 2.5,
    perKmRate: 0.5,
    description: 'Affordable rides',
  ),
  RideType(
    name: 'Comfort',
    icon: '🚙',
    baseFare: 4.0,
    perKmRate: 0.75,
    description: 'More spacious',
  ),
  RideType(
    name: 'Luxury',
    icon: '🚘',
    baseFare: 6.0,
    perKmRate: 1.0,
    description: 'Premium experience',
  ),
];