import 'dart:convert';
import 'dart:io';

import 'package:chat_app/models/ride_model.dart';
import 'package:chat_app/utils/driver_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

const _dir = r'C:\Users\User\AppData\Local\Temp\opencode\phase3f';

String _read(String name) {
  return File('$_dir\\$name').readAsStringSync();
}

void main() {
  final hasEvidence = File('$_dir\\evidence_ride_rest.json').existsSync() &&
      File('$_dir\\evidence_ride_accepted_ws.json').existsSync();

  group('Phase 3F — app parsers against LIVE backend payloads', () {
    test('Ride.fromJson + DriverCardData.fromRide parse the live REST detail',
        () {
      if (!hasEvidence) {
        markTestSkipped('live evidence files not present (not a 3F live run)');
        return;
      }
      final json = jsonDecode(_read('evidence_ride_rest.json'))
          as Map<String, dynamic>;
      final ride = Ride.fromJson(json);
      expect(ride.status, 'ACCEPTED');
      expect(ride.driver?.fullName, 'Phase 3F Driver');
      expect(ride.driver?.photoUrl, isNotNull);
      expect(ride.driverVehiclePhotoUrl, isNotNull);
      expect(ride.driverVehicleType, 'ECONOMY');
      expect(ride.driverVehicleNumber, 'ABC-3F99');
      expect(ride.driverVehicleModel, 'Toyota Corolla');
      expect(ride.driverVehicleColor, 'White');
      expect(ride.driverAverageRating, 5.0);

      final card = DriverCardData.fromRide(ride);
      expect(card.name, 'Phase 3F Driver');
      expect(card.photoUrl, contains('/uploads/photos/25_'));
      expect(card.vehiclePhotoUrl, contains('/uploads/documents/25/'));
      expect(card.vehicleType, 'ECONOMY');
      expect(card.vehicleNumber, 'ABC-3F99');
      expect(card.vehicleModel, 'Toyota Corolla');
      expect(card.vehicleColor, 'White');
      expect(card.rating, 5.0);
    });

    test('DriverCardData.fromMap parses the live WS ride_accepted payload', () {
      if (!hasEvidence) {
        markTestSkipped('live evidence files not present (not a 3F live run)');
        return;
      }
      final ws = jsonDecode(_read('evidence_ride_accepted_ws.json'))
          as Map<String, dynamic>;
      expect(ws['type'], 'ride_accepted');
      final payload = ws['payload'] as Map<String, dynamic>;

      final card = DriverCardData.fromMap(payload);
      expect(card.name, 'Phase 3F Driver');
      expect(card.photoUrl, contains('/uploads/photos/25_'));
      expect(card.vehiclePhotoUrl, contains('/uploads/documents/25/'));
      expect(card.rating, 5.0);
      expect(card.vehicleNumber, 'ABC-3F99');
      expect(card.vehicleModel, 'Toyota Corolla');
      expect(card.vehicleColor, 'White');
      expect(card.toPayloadMap()['driverName'], 'Phase 3F Driver');
      expect(card.toPayloadMap()['driverPhotoUrl'], contains('/uploads/photos/25_'));
      expect(card.toPayloadMap()['driverVehiclePhotoUrl'],
          contains('/uploads/documents/25/'));
    });
  });
}
