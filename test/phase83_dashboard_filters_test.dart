import 'package:chat_app/utils/admin_driver_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8.3 — filterAdminDrivers', () {
    final drivers = <Map<String, dynamic>>[
      {'driverId': 1, 'name': 'Ahmed', 'verificationStatus': 'DRAFT', 'online': true, 'currentRideId': null, 'vehicleModel': 'Camry', 'vehicleNumber': 'A-1'},
      {'driverId': 2, 'name': 'Salem', 'verificationStatus': 'PENDING', 'online': true, 'currentRideId': 5, 'vehicleModel': 'Rav4', 'vehicleNumber': 'B-2'},
      {'driverId': 3, 'name': 'Nasser', 'verificationStatus': 'APPROVED', 'online': false, 'currentRideId': null, 'vehicleModel': 'X5', 'vehicleNumber': 'C-3'},
      {'driverId': 4, 'name': 'Khalid', 'verificationStatus': 'REJECTED', 'online': true, 'currentRideId': null, 'vehicleModel': 'Sunny', 'vehicleNumber': 'D-4'},
      {'driverId': 5, 'name': 'Omar', 'verificationStatus': 'PENDING', 'online': false, 'currentRideId': null, 'vehicleModel': 'Yaris', 'vehicleNumber': 'E-5'},
    ];

    test('all returns every driver', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryNone,
      );
      expect(result.length, 5);
    });

    test('draft keeps only DRAFT drivers', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusDraft,
        expiryFilter: adminExpiryNone,
      );
      expect(result.map((d) => d['driverId']), [1]);
    });

    test('pending keeps only PENDING drivers', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusPending,
        expiryFilter: adminExpiryNone,
      );
      expect(result.map((d) => d['driverId']), [2, 5]);
    });

    test('approved keeps only APPROVED drivers', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusApproved,
        expiryFilter: adminExpiryNone,
      );
      expect(result.map((d) => d['driverId']), [3]);
    });

    test('rejected keeps only REJECTED drivers', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusRejected,
        expiryFilter: adminExpiryNone,
      );
      expect(result.map((d) => d['driverId']), [4]);
    });

    test('online/offline/busy/available still work', () {
      expect(filterAdminDrivers(drivers: drivers, statusFilter: adminStatusOnline, expiryFilter: adminExpiryNone)
          .map((d) => d['driverId']), [1, 2, 4]);
      expect(filterAdminDrivers(drivers: drivers, statusFilter: adminStatusOffline, expiryFilter: adminExpiryNone)
          .map((d) => d['driverId']), [3, 5]);
      expect(filterAdminDrivers(drivers: drivers, statusFilter: adminStatusBusy, expiryFilter: adminExpiryNone)
          .map((d) => d['driverId']), [2]);
      expect(filterAdminDrivers(drivers: drivers, statusFilter: adminStatusAvailable, expiryFilter: adminExpiryNone)
          .map((d) => d['driverId']), [1, 3, 4, 5]);
    });

    test('expired filter keeps only drivers in the expired set', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryExpired,
        expiredDriverIds: {3, 4},
      );
      expect(result.map((d) => d['driverId']), [3, 4]);
    });

    test('expiring7 filter keeps only drivers in the expiring7 set', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryExpiring7,
        expiring7DriverIds: {2},
      );
      expect(result.map((d) => d['driverId']), [2]);
    });

    test('expiring30 filter keeps only drivers in the expiring30 set', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryExpiring30,
        expiring30DriverIds: {1, 5},
      );
      expect(result.map((d) => d['driverId']), [1, 5]);
    });

    test('expired filter with null set yields empty list', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryExpired,
      );
      expect(result, isEmpty);
    });

    test('status and expiry filters combine (AND)', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusRejected,
        expiryFilter: adminExpiryExpired,
        expiredDriverIds: {4},
      );
      expect(result.map((d) => d['driverId']), [4]);
    });

    test('expired + rejected with non-overlapping sets yields empty', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusApproved,
        expiryFilter: adminExpiryExpired,
        expiredDriverIds: {4},
      );
      expect(result, isEmpty);
    });

    test('text filter still matches name, model or plate', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryNone,
        filterText: 'camry',
      );
      expect(result.map((d) => d['driverId']), [1]);
    });

    test('text filter is case-insensitive', () {
      final result = filterAdminDrivers(
        drivers: drivers,
        statusFilter: adminStatusAll,
        expiryFilter: adminExpiryNone,
        filterText: 'AHMED',
      );
      expect(result.map((d) => d['driverId']), [1]);
    });
  });

  group('Phase 8.3 — driverIdSet', () {
    test('extracts driverIds from expiry summary lists', () {
      final set = driverIdSet([
        {'driverId': 3, 'driverName': 'X'},
        {'driverId': 7, 'driverName': 'Y'},
        {'driverId': 9, 'driverName': 'Z'},
      ]);
      expect(set, {3, 7, 9});
    });

    test('handles null input', () {
      expect(driverIdSet(null), isEmpty);
    });

    test('handles empty list', () {
      expect(driverIdSet(<dynamic>[]), isEmpty);
    });

    test('skips items without driverId', () {
      final set = driverIdSet([
        {'name': 'no id'},
        {'driverId': 2},
      ]);
      expect(set, {2});
    });
  });
}
