import 'package:chat_app/models/models.dart';
import 'package:chat_app/models/ride_model.dart';
import 'package:chat_app/services/photo_service.dart';
import 'package:chat_app/utils/driver_verification.dart';
import 'package:chat_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3C1 — driver verification info mapping', () {
    test('maps each status to label/color/icon', () {
      final approved = driverVerificationInfo('APPROVED');
      expect(approved.label, 'Approved');
      expect(approved.color, const Color(0xFF10B981));

      final pending = driverVerificationInfo('PENDING');
      expect(pending.label, 'Pending Review');
      expect(pending.color, const Color(0xFFF59E0B));

      final rejected = driverVerificationInfo('REJECTED');
      expect(rejected.label, 'Rejected');
      expect(rejected.color, const Color(0xFFEF4444));
    });

    test('unknown/null status maps to Draft', () {
      expect(driverVerificationInfo(null).label, 'Draft');
      expect(driverVerificationInfo('').label, 'Draft');
      expect(driverVerificationInfo('SOMETHING_ELSE').label, 'Draft');
    });
  });

  group('Phase 3C1 — DriverProfile vehicle/verification parse round-trip', () {
    test('parses vehicleYear, verificationStatus, photoUrl, vehiclePhotoUrl',
        () {
      final d = DriverProfile.fromJson({
        'id': 9,
        'user': {'email': 'd@test.com', 'fullName': 'Driver Nine', 'id': 15},
        'isVerified': 0,
        'isActive': 1,
        'averageRating': 4.5,
        'totalRides': 2,
        'isOnline': 0,
        'vehicleYear': 2019,
        'verificationStatus': 'PENDING',
        'photoUrl': '/uploads/photos/15_p.png',
        'vehiclePhotoUrl': '/uploads/photos/15_v.png',
      });
      expect(d.vehicleYear, 2019);
      expect(d.verificationStatus, 'PENDING');
      expect(d.photoUrl, '/uploads/photos/15_p.png');
      expect(d.vehiclePhotoUrl, '/uploads/photos/15_v.png');
      final json = d.toJson();
      expect(json['vehicleYear'], 2019);
      expect(json['verificationStatus'], 'PENDING');
      expect(json['vehiclePhotoUrl'], '/uploads/photos/15_v.png');
    });
  });

  group('Phase 3B — PhotoService.resolvePhotoUrl', () {
    test('returns null for null path', () {
      expect(PhotoService.resolvePhotoUrl(null), isNull);
    });

    test('returns null for empty/blank path', () {
      expect(PhotoService.resolvePhotoUrl(''), isNull);
      expect(PhotoService.resolvePhotoUrl('   '), isNull);
    });

    test('passes through absolute http(s) URLs unchanged', () {
      expect(
        PhotoService.resolvePhotoUrl('https://example.com/uploads/p.png'),
        'https://example.com/uploads/p.png',
      );
      expect(
        PhotoService.resolvePhotoUrl('http://localhost:8080/uploads/p.png'),
        'http://localhost:8080/uploads/p.png',
      );
    });

    test('joins relative path onto server URL', () {
      final resolved = PhotoService.resolvePhotoUrl('/uploads/photos/20_x.png');
      expect(resolved, endsWith('/uploads/photos/20_x.png'));
      expect(resolved, contains('http'));
    });

    test('joins relative path without leading slash', () {
      final resolved = PhotoService.resolvePhotoUrl('uploads/photos/20_x.png');
      expect(resolved, endsWith('/uploads/photos/20_x.png'));
    });
  });

  group('Phase 3A — backward-compatible JSON parsing', () {
    test('User.fromJson parses when photoUrl absent', () {
      final json = {
        'id': 1,
        'username': 'rider1',
        'email': 'rider1@test.com',
        'password': 'x',
        'fullName': 'Rider One',
        'isOnline': 1,
        'isVerified': 1,
        'countryCode': '+966',
        'phoneNumber': '555010111',
        'normalizedPhone': '+966555010111',
        'phoneVerified': 1,
        'gender': 'MALE',
        'createdAt': '2026-01-01T00:00:00.000+00:00',
      };
      final u = User.fromJson(json);
      expect(u.id, 1);
      expect(u.fullName, 'Rider One');
      expect(u.isVerified, true);
      expect(u.photoUrl, isNull);
    });

    test('User.fromJson parses photoUrl when present', () {
      final u = User.fromJson({
        'email': 'a@b.com',
        'fullName': 'Rider Two',
        'photoUrl': '/uploads/photos/2_abc.png',
      });
      expect(u.photoUrl, '/uploads/photos/2_abc.png');
    });

    test('User.toJson round-trips photoUrl', () {
      final u = User.fromJson({
        'email': 'a@b.com',
        'fullName': 'Rider Three',
        'photoUrl': '/uploads/photos/3_def.png',
      });
      final json = u.toJson();
      expect(json['photoUrl'], '/uploads/photos/3_def.png');
      expect(User.fromJson(json).photoUrl, '/uploads/photos/3_def.png');
    });

    test('DriverProfile.fromJson parses when new keys absent', () {
      final json = {
        'id': 5,
        'user': {
          'email': 'd@test.com',
          'fullName': 'Driver Five',
          'id': 10,
        },
        'licenseNumber': 'L123',
        'vehicleNumber': 'V123',
        'vehicleType': 'CAR',
        'vehicleModel': 'Camry',
        'vehicleColor': 'White',
        'isVerified': 1,
        'isActive': 1,
        'averageRating': 4.8,
        'totalRides': 12,
        'isOnline': 0,
      };
      final d = DriverProfile.fromJson(json);
      expect(d.id, 5);
      expect(d.vehicleType, 'CAR');
      expect(d.photoUrl, isNull);
      expect(d.vehiclePhotoUrl, isNull);
      expect(d.vehicleYear, isNull);
      expect(d.verificationStatus, isNull);
      expect(d.verifiedAt, isNull);
    });

    test('DriverProfile.fromJson parses new keys when present', () {
      final json = {
        'id': 6,
        'user': {
          'email': 'd@test.com',
          'fullName': 'Driver Six',
          'id': 11,
        },
        'isVerified': 1,
        'isActive': 1,
        'averageRating': 4.9,
        'totalRides': 3,
        'isOnline': 1,
        'photoUrl': '/uploads/photos/11_xyz.png',
        'vehiclePhotoUrl': '/uploads/photos/11_vehicle.png',
        'vehicleYear': 2022,
        'verificationStatus': 'APPROVED',
        'verifiedAt': '2026-08-02T10:00:00.000+00:00',
      };
      final d = DriverProfile.fromJson(json);
      expect(d.photoUrl, '/uploads/photos/11_xyz.png');
      expect(d.vehiclePhotoUrl, '/uploads/photos/11_vehicle.png');
      expect(d.vehicleYear, 2022);
      expect(d.verificationStatus, 'APPROVED');
      expect(d.verifiedAt, isNotNull);
    });

    test('DriverProfile.toJson round-trips new keys', () {
      final d = DriverProfile.fromJson({
        'id': 7,
        'user': {'email': 'd@test.com', 'fullName': 'Driver Seven', 'id': 12},
        'isVerified': 1,
        'isActive': 1,
        'averageRating': 5.0,
        'totalRides': 1,
        'isOnline': 1,
        'photoUrl': '/uploads/photos/12_a.png',
        'vehiclePhotoUrl': '/uploads/photos/12_v.png',
        'vehicleYear': 2021,
        'verificationStatus': 'PENDING',
      });
      final json = d.toJson();
      expect(json['photoUrl'], '/uploads/photos/12_a.png');
      expect(json['vehiclePhotoUrl'], '/uploads/photos/12_v.png');
      expect(json['vehicleYear'], 2021);
      expect(json['verificationStatus'], 'PENDING');
    });
  });

  group('Phase 3A — UserAvatar fallback', () {
    Widget wrap(Widget child) {
      return MaterialApp(home: Scaffold(body: Center(child: child)));
    }

    testWidgets('renders initial when photoUrl is null', (tester) async {
      await tester.pumpWidget(wrap(
        const UserAvatar(photoUrl: null, displayName: 'Ali', radius: 24),
      ));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders initial when photoUrl is empty string', (tester) async {
      await tester.pumpWidget(wrap(
        const UserAvatar(photoUrl: '', displayName: 'Sara', radius: 24),
      ));
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('renders initial when photoUrl is blank whitespace',
        (tester) async {
      await tester.pumpWidget(wrap(
        const UserAvatar(photoUrl: '   ', displayName: 'Omar', radius: 24),
      ));
      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('renders initial fallback when network image fails',
        (tester) async {
      await tester.pumpWidget(wrap(
        const UserAvatar(
          photoUrl: 'http://localhost:8080/does-not-exist.png',
          displayName: 'Hassan',
          radius: 24,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('uses first character of name for the initial',
        (tester) async {
      await tester.pumpWidget(wrap(
        const UserAvatar(photoUrl: null, displayName: 'Mohammed', radius: 24),
      ));
      expect(find.text('M'), findsOneWidget);
    });
  });
}
