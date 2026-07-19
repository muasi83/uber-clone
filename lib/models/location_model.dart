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
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    address: json['address'] as String? ?? '',
    placeId: json['placeId'] as String?,
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'] as String)
        : null,
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

// Predefined ride types (rates must match backend RideService.calculateFare)
final List<RideType> rideTypes = [
  RideType(
    name: 'Economy',
    icon: '🚗',
    baseFare: 2.0,
    perKmRate: 0.20,
    description: 'Affordable rides',
  ),
  RideType(
    name: 'Comfort',
    icon: '🚙',
    baseFare: 4.0,
    perKmRate: 0.35,
    description: 'More spacious',
  ),
  RideType(
    name: 'Luxury',
    icon: '🚘',
    baseFare: 6.0,
    perKmRate: 0.50,
    description: 'Premium experience',
  ),
  RideType(
    name: 'Women Driver',
    icon: '👩',
    baseFare: 3.0,
    perKmRate: 0.25,
    description: 'Ride with a female driver',
  ),
];