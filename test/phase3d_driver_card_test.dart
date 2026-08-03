import 'package:chat_app/models/ride_model.dart';
import 'package:chat_app/utils/driver_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3D — DriverCardData.fromMap (WS ride_accepted keys)', () {
    test('parses driver photo, vehicle photo, rating, vehicle number', () {
      final card = DriverCardData.fromMap({
        'rideId': 42,
        'driverId': 7,
        'driverName': 'Ahmed Ali',
        'driverPhotoUrl': '/uploads/photos/7_d.png',
        'driverVehiclePhotoUrl': '/uploads/photos/7_v.png',
        'driverVehicleType': 'CAR',
        'driverVehicleNumber': 'ABC-1234',
        'driverVehicleModel': 'Camry',
        'driverVehicleColor': 'White',
        'driverRating': 4.8,
      });
      expect(card.name, 'Ahmed Ali');
      expect(card.photoUrl, '/uploads/photos/7_d.png');
      expect(card.vehiclePhotoUrl, '/uploads/photos/7_v.png');
      expect(card.vehicleType, 'CAR');
      expect(card.vehicleNumber, 'ABC-1234');
      expect(card.vehicleModel, 'Camry');
      expect(card.vehicleColor, 'White');
      expect(card.rating, 4.8);
    });

    test('falls back to licensePlate alias for vehicle number', () {
      final card = DriverCardData.fromMap({'licensePlate': 'KSA-99'});
      expect(card.vehicleNumber, 'KSA-99');
    });

    test('reads rating passed as string', () {
      final card = DriverCardData.fromMap({'driverRating': '4.5'});
      expect(card.rating, 4.5);
    });
  });

  group('Phase 3D — DriverCardData.fromMap (REST ride keys)', () {
    test('parses REST-style keys', () {
      final card = DriverCardData.fromMap({
        'fullName': 'Salem',
        'photoUrl': '/uploads/photos/8_d.png',
        'vehiclePhotoUrl': '/uploads/photos/8_v.png',
        'vehicleType': 'SUV',
        'vehicleNumber': 'X-100',
        'averageRating': 4.9,
      });
      expect(card.name, 'Salem');
      expect(card.photoUrl, '/uploads/photos/8_d.png');
      expect(card.vehiclePhotoUrl, '/uploads/photos/8_v.png');
      expect(card.vehicleType, 'SUV');
      expect(card.vehicleNumber, 'X-100');
      expect(card.rating, 4.9);
    });
  });

  group('Phase 3D — DriverCardData empty-string sanitization', () {
    test('strips empty/blank strings and treats them as null', () {
      final card = DriverCardData.fromMap({
        'driverName': '   ',
        'driverPhotoUrl': '',
        'driverVehiclePhotoUrl': '',
        'driverVehicleType': '',
        'driverVehicleNumber': '',
        'driverRating': null,
      });
      expect(card.name, isNull);
      expect(card.photoUrl, isNull);
      expect(card.vehiclePhotoUrl, isNull);
      expect(card.vehicleType, isNull);
      expect(card.vehicleNumber, isNull);
      expect(card.rating, isNull);
    });

    test('empty map yields an empty card (no placeholders)', () {
      final card = DriverCardData.fromMap(const {});
      expect(card.name, isNull);
      expect(card.rating, isNull);
    });
  });

  group('Phase 3D — DriverCardData.fromRide (REST ride enrichment)', () {
    Ride buildRide({
      double? rating,
      String? photoUrl,
      String? vehiclePhotoUrl,
      String? vehicleType,
      String? vehicleNumber,
      String? vehicleModel,
      String? vehicleColor,
    }) {
      return Ride.fromJson({
        'id': 42,
        'rider': {'email': 'r@t.com', 'fullName': 'Rider'},
        'driver': {
          'email': 'd@t.com',
          'fullName': 'Ahmed Ali',
          'id': 7,
          'photoUrl': photoUrl,
          'averageRating': rating,
          'currentLatitude': 24.0,
          'currentLongitude': 46.0,
          'vehiclePhotoUrl': vehiclePhotoUrl,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
        },
        'pickupLatitude': 24.0,
        'pickupLongitude': 46.0,
        'pickupAddress': 'A',
        'dropoffLatitude': 24.1,
        'dropoffLongitude': 46.1,
        'dropoffAddress': 'B',
        'status': 'ACCEPTED',
        'rideType': 'ECONOMY',
      });
    }

    test('maps driver + vehicle fields from the enriched ride payload', () {
      final card = DriverCardData.fromRide(buildRide(
        rating: 4.7,
        photoUrl: '/uploads/photos/7_d.png',
        vehiclePhotoUrl: '/uploads/photos/7_v.png',
        vehicleType: 'CAR',
        vehicleNumber: 'ABC-1234',
        vehicleModel: 'Camry',
        vehicleColor: 'White',
      ));
      expect(card.name, 'Ahmed Ali');
      expect(card.photoUrl, '/uploads/photos/7_d.png');
      expect(card.vehiclePhotoUrl, '/uploads/photos/7_v.png');
      expect(card.vehicleType, 'CAR');
      expect(card.vehicleNumber, 'ABC-1234');
      expect(card.vehicleModel, 'Camry');
      expect(card.vehicleColor, 'White');
      expect(card.rating, 4.7);
    });

    test('leaves fields null when ride has no enrichment', () {
      final card = DriverCardData.fromRide(buildRide());
      expect(card.photoUrl, isNull);
      expect(card.vehiclePhotoUrl, isNull);
      expect(card.vehicleType, isNull);
      expect(card.rating, isNull);
      expect(card.name, 'Ahmed Ali');
    });
  });

  group('Phase 3D — toPayloadMap canonical payload', () {
    test('round-trips only non-null values under WS canonical keys', () {
      const card = DriverCardData(
        name: 'Ahmed Ali',
        photoUrl: '/uploads/photos/7_d.png',
        vehiclePhotoUrl: '/uploads/photos/7_v.png',
        vehicleType: 'CAR',
        vehicleNumber: 'ABC-1234',
        rating: 4.8,
      );
      final map = card.toPayloadMap();
      expect(map, {
        'driverName': 'Ahmed Ali',
        'driverPhotoUrl': '/uploads/photos/7_d.png',
        'driverVehiclePhotoUrl': '/uploads/photos/7_v.png',
        'driverVehicleType': 'CAR',
        'driverVehicleNumber': 'ABC-1234',
        'driverRating': 4.8,
      });
      final reparsed = DriverCardData.fromMap(map);
      expect(reparsed.name, card.name);
      expect(reparsed.photoUrl, card.photoUrl);
      expect(reparsed.vehiclePhotoUrl, card.vehiclePhotoUrl);
      expect(reparsed.vehicleType, card.vehicleType);
      expect(reparsed.vehicleNumber, card.vehicleNumber);
      expect(reparsed.rating, card.rating);
    });

    test('omits null fields entirely', () {
      const card = DriverCardData(name: 'Only Name');
      expect(card.toPayloadMap(), {'driverName': 'Only Name'});
    });
  });

  group('Phase 3D — vehicleSummary composition', () {
    test('combines type, model, color and number', () {
      const card = DriverCardData(
        vehicleType: 'CAR',
        vehicleModel: 'Camry',
        vehicleColor: 'White',
        vehicleNumber: 'ABC-1234',
      );
      expect(card.vehicleSummary, 'CAR Camry White • ABC-1234');
    });

    test('shows number alone when no type/model/color', () {
      const card = DriverCardData(vehicleNumber: 'ABC-1234');
      expect(card.vehicleSummary, 'ABC-1234');
    });

    test('returns empty when nothing is present', () {
      expect(const DriverCardData().vehicleSummary, isEmpty);
    });
  });

  group('Phase 3D — Ride model enriched driver fields', () {
    test('fromJson parses enriched driver vehicle fields', () {
      final ride = Ride.fromJson({
        'id': 1,
        'rider': {'email': 'r@t.com', 'fullName': 'R'},
        'driver': {
          'email': 'd@t.com',
          'fullName': 'D',
          'id': 2,
          'photoUrl': '/uploads/photos/2_d.png',
          'vehiclePhotoUrl': '/uploads/photos/2_v.png',
          'vehicleType': 'SUV',
          'vehicleNumber': 'XYZ-77',
          'vehicleModel': 'Rav4',
          'vehicleColor': 'Black',
        },
        'pickupLatitude': 1.0,
        'pickupLongitude': 1.0,
        'pickupAddress': 'A',
        'dropoffLatitude': 2.0,
        'dropoffLongitude': 2.0,
        'dropoffAddress': 'B',
        'status': 'ACCEPTED',
        'rideType': 'ECONOMY',
      });
      expect(ride.driverVehiclePhotoUrl, '/uploads/photos/2_v.png');
      expect(ride.driverVehicleType, 'SUV');
      expect(ride.driverVehicleNumber, 'XYZ-77');
      expect(ride.driverVehicleModel, 'Rav4');
      expect(ride.driverVehicleColor, 'Black');
      expect(ride.driver?.photoUrl, '/uploads/photos/2_d.png');
      final json = ride.toJson();
      expect(json['driverVehiclePhotoUrl'], '/uploads/photos/2_v.png');
      expect(json['driverVehicleType'], 'SUV');
      expect(json['driverVehicleNumber'], 'XYZ-77');
      expect(json['driverVehicleModel'], 'Rav4');
      expect(json['driverVehicleColor'], 'Black');
    });

    test('fromJson stays null-safe when enriched fields absent', () {
      final ride = Ride.fromJson({
        'id': 2,
        'rider': {'email': 'r@t.com', 'fullName': 'R'},
        'driver': {'email': 'd@t.com', 'fullName': 'D', 'id': 3},
        'pickupLatitude': 1.0,
        'pickupLongitude': 1.0,
        'pickupAddress': 'A',
        'dropoffLatitude': 2.0,
        'dropoffLongitude': 2.0,
        'dropoffAddress': 'B',
        'status': 'REQUESTED',
        'rideType': 'ECONOMY',
      });
      expect(ride.driverVehiclePhotoUrl, isNull);
      expect(ride.driverVehicleType, isNull);
      expect(ride.driverVehicleNumber, isNull);
      expect(ride.driverVehicleModel, isNull);
      expect(ride.driverVehicleColor, isNull);
      expect(ride.driverAverageRating, isNull);
    });
  });
}
