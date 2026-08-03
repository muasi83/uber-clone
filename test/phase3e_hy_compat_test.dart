import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/driver_document.dart';
import 'package:chat_app/models/ride_model.dart';
import 'package:chat_app/services/photo_service.dart';
import 'package:chat_app/utils/driver_card_data.dart';
import 'package:chat_app/utils/driver_verification.dart';
import 'package:chat_app/widgets/driver_documents_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cache manager whose [getFileStream] fails immediately — simulates a
/// network image load error deterministically without real I/O.
class _FailingCacheManager extends CacheManager {
  _FailingCacheManager() : super(Config('throwing-test-cache'));

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return Stream<FileResponse>.error(Exception('network image failed'));
  }
}

void main() {
  group('Phase 3E½ — old payloads omitting new fields', () {
    test('Ride.fromJson parses when driver + enriched fields absent', () {
      final ride = Ride.fromJson({
        'id': 100,
        'rider': {'id': 1, 'email': 'r@test.com', 'fullName': 'Rider'},
        'pickupLatitude': 24.0,
        'pickupLongitude': 46.0,
        'pickupAddress': 'A',
        'dropoffLatitude': 24.1,
        'dropoffLongitude': 46.1,
        'dropoffAddress': 'B',
        'status': 'ACCEPTED',
        'rideType': 'ECONOMY',
      });
      expect(ride.id, 100);
      expect(ride.driver, isNull);
      expect(ride.driverAverageRating, isNull);
      expect(ride.driverVehiclePhotoUrl, isNull);
      expect(ride.driverVehicleType, isNull);
      expect(ride.driverVehicleNumber, isNull);
      expect(ride.driverVehicleModel, isNull);
      expect(ride.driverVehicleColor, isNull);
      expect(ride.driverLatitude, isNull);
    });

    test('Ride.fromJson handles driver object without photo/vehicle keys', () {
      final ride = Ride.fromJson({
        'id': 101,
        'rider': {'id': 1, 'email': 'r@test.com', 'fullName': 'Rider'},
        'driver': {'id': 2, 'email': 'd@test.com', 'fullName': 'Driver'},
        'pickupLatitude': 24.0,
        'pickupLongitude': 46.0,
        'pickupAddress': 'A',
        'dropoffLatitude': 24.1,
        'dropoffLongitude': 46.1,
        'dropoffAddress': 'B',
        'status': 'ACCEPTED',
        'rideType': 'ECONOMY',
      });
      expect(ride.driver?.fullName, 'Driver');
      expect(ride.driver?.photoUrl, isNull);
      expect(ride.driverVehiclePhotoUrl, isNull);
      expect(ride.driverVehicleType, isNull);
    });

    test('Ride.fromJson falls back to Unknown rider when rider absent', () {
      final ride = Ride.fromJson({
        'id': 102,
        'pickupLatitude': 24.0,
        'pickupLongitude': 46.0,
        'pickupAddress': 'A',
        'dropoffLatitude': 24.1,
        'dropoffLongitude': 46.1,
        'dropoffAddress': 'B',
        'status': 'REQUESTED',
        'rideType': 'ECONOMY',
      });
      expect(ride.rider.fullName, 'Unknown User');
      expect(ride.status, 'REQUESTED');
    });

    test('DriverDocument.fromJson with no keys → defaults, no throw', () {
      final doc = DriverDocument.fromJson(const {});
      expect(doc.id, 0);
      expect(doc.driverId, isNull);
      expect(doc.documentType, isNull);
      expect(doc.fileName, isNull);
      expect(doc.fileUrl, isNull);
      expect(doc.status, isNull);
      expect(doc.adminNote, isNull);
      expect(doc.expiryDate, isNull);
      expect(doc.uploadedAt, isNull);
    });

    test('DriverDocument.fromJson with only id keeps nulls', () {
      final doc = DriverDocument.fromJson({'id': 7});
      expect(doc.id, 7);
      expect(doc.fileUrl, isNull);
      expect(doc.documentType, isNull);
    });

    test('DocumentCompleteness.fromJson with no keys → zeroed defaults', () {
      final c = DocumentCompleteness.fromJson(const {});
      expect(c.required, 0);
      expect(c.uploaded, 0);
      expect(c.missing, isEmpty);
      expect(c.readyForSubmission, isFalse);
    });

    test('DocumentCompleteness.fromJson tolerates null / non-list missing',
        () {
      final nullMissing = DocumentCompleteness.fromJson({'missing': null});
      expect(nullMissing.missing, isEmpty);
      final stringMissing = DocumentCompleteness.fromJson({
        'required': 6,
        'uploaded': 1,
        'missing': 'LICENSE',
        'readyForSubmission': false,
      });
      expect(stringMissing.missing, isEmpty);
      expect(stringMissing.required, 6);
    });

    test('documentTypeLabel falls back safely for null/unknown types', () {
      expect(driverDocumentTypeLabel(null), 'Document');
      expect(driverDocumentTypeLabel('UNKNOWN_TYPE'), 'UNKNOWN_TYPE');
      expect(driverDocumentTypeLabel('LICENSE'), 'Driving License');
    });
  });

  group('Phase 3E½ — null / whitespace photo URLs', () {
    test('resolvePhotoUrl returns null for tab/newline whitespace', () {
      expect(PhotoService.resolvePhotoUrl('\t'), isNull);
      expect(PhotoService.resolvePhotoUrl('  \n  '), isNull);
      expect(PhotoService.resolvePhotoUrl('\u00A0'), isNull);
    });

    test('DriverCardData.fromRide strips blank photo/vehicle values', () {
      final ride = Ride.fromJson({
        'id': 103,
        'rider': {'id': 1, 'email': 'r@test.com', 'fullName': 'Rider'},
        'driver': {
          'id': 2,
          'email': 'd@test.com',
          'fullName': '   ',
          'photoUrl': '   ',
          'vehiclePhotoUrl': '  ',
          'vehicleType': ' ',
          'vehicleNumber': '  ',
          'vehicleModel': '\t',
          'vehicleColor': '  ',
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
      final card = DriverCardData.fromRide(ride);
      expect(card.name, isNull);
      expect(card.photoUrl, isNull);
      expect(card.vehiclePhotoUrl, isNull);
      expect(card.vehicleType, isNull);
      expect(card.vehicleNumber, isNull);
      expect(card.vehicleModel, isNull);
      expect(card.vehicleColor, isNull);
      expect(card.rating, isNull);
    });

    test('DriverCardData.fromRide keeps real values intact', () {
      final ride = Ride.fromJson({
        'id': 104,
        'rider': {'id': 1, 'email': 'r@test.com', 'fullName': 'Rider'},
        'driver': {
          'id': 2,
          'email': 'd@test.com',
          'fullName': 'Ahmed',
          'photoUrl': '/uploads/photos/2_d.png',
          'averageRating': 4.7,
          'vehiclePhotoUrl': '/uploads/photos/2_v.png',
          'vehicleType': 'SUV',
          'vehicleNumber': 'ABC-99',
          'vehicleModel': 'Camry',
          'vehicleColor': 'White',
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
      final card = DriverCardData.fromRide(ride);
      expect(card.name, 'Ahmed');
      expect(card.photoUrl, '/uploads/photos/2_d.png');
      expect(card.vehiclePhotoUrl, '/uploads/photos/2_v.png');
      expect(card.vehicleType, 'SUV');
      expect(card.vehicleNumber, 'ABC-99');
      expect(card.vehicleModel, 'Camry');
      expect(card.vehicleColor, 'White');
      expect(card.rating, 4.7);
    });
  });

  group('Phase 3E½ — missing verificationStatus never crashes', () {
    test('whitespace verification status maps to Draft', () {
      expect(driverVerificationInfo(' ').label, 'Draft');
      expect(driverVerificationInfo('PENDING').label, 'Pending Review');
    });

    test('DriverProfile.fromJson with missing status renders null status', () {
      final d = DriverProfile.fromJson({
        'id': 3,
        'user': {'id': 1, 'email': 'd@test.com', 'fullName': 'Driver'},
        'isVerified': 1,
        'isActive': 1,
        'averageRating': 4.5,
        'totalRides': 2,
        'isOnline': 0,
      });
      expect(d.verificationStatus, isNull);
      expect(d.vehicleYear, isNull);
      expect(driverVerificationInfo(d.verificationStatus).label, 'Draft');
    });
  });

  group('Phase 3E½ — network image failure fallbacks (widgets)', () {
    Widget wrap(Widget child) {
      return MaterialApp(home: Scaffold(body: Center(child: child)));
    }

    testWidgets('vehicle-photo CachedNetworkImage falls back on network error',
        (tester) async {
      await tester.pumpWidget(wrap(
        CachedNetworkImage(
          imageUrl: 'http://localhost:8080/does-not-exist-vehicle.png',
          cacheManager: _FailingCacheManager(),
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox.shrink(),
          errorWidget: (_, __, ___) => const Icon(Icons.directions_car, size: 32),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('documents panel ends loading on failing backend (no stuck spinner)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverDocumentsPanel(token: 'test-token'),
          ),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Documents'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
