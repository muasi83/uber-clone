const String adminStatusAll = 'all';
const String adminStatusDraft = 'draft';
const String adminStatusPending = 'pending';
const String adminStatusApproved = 'approved';
const String adminStatusRejected = 'rejected';
const String adminStatusOnline = 'online';
const String adminStatusOffline = 'offline';
const String adminStatusAvailable = 'available';
const String adminStatusBusy = 'busy';

const String adminExpiryNone = 'none';
const String adminExpiryExpired = 'expired';
const String adminExpiryExpiring7 = 'expiring7';
const String adminExpiryExpiring30 = 'expiring30';

List<Map<String, dynamic>> filterAdminDrivers({
  required List<Map<String, dynamic>> drivers,
  required String statusFilter,
  required String expiryFilter,
  Set<int>? expiredDriverIds,
  Set<int>? expiring7DriverIds,
  Set<int>? expiring30DriverIds,
  String filterText = '',
}) {
  final q = filterText.trim().toLowerCase();
  return drivers.where((d) {
    switch (statusFilter) {
      case adminStatusDraft:
        if (d['verificationStatus'] != 'DRAFT') return false;
      case adminStatusPending:
        if (d['verificationStatus'] != 'PENDING') return false;
      case adminStatusApproved:
        if (d['verificationStatus'] != 'APPROVED') return false;
      case adminStatusRejected:
        if (d['verificationStatus'] != 'REJECTED') return false;
      case adminStatusOnline:
        if (d['online'] != true) return false;
      case adminStatusOffline:
        if (d['online'] == true) return false;
      case adminStatusBusy:
        if (d['currentRideId'] == null) return false;
      case adminStatusAvailable:
        if (d['currentRideId'] != null) return false;
    }
    switch (expiryFilter) {
      case adminExpiryExpired:
        if (expiredDriverIds == null || !expiredDriverIds.contains(d['driverId'])) {
          return false;
        }
      case adminExpiryExpiring7:
        if (expiring7DriverIds == null || !expiring7DriverIds.contains(d['driverId'])) {
          return false;
        }
      case adminExpiryExpiring30:
        if (expiring30DriverIds == null || !expiring30DriverIds.contains(d['driverId'])) {
          return false;
        }
    }
    if (q.isNotEmpty) {
      final name = (d['name'] as String? ?? '').toLowerCase();
      final model = (d['vehicleModel'] as String? ?? '').toLowerCase();
      final plate = (d['vehicleNumber'] as String? ?? '').toLowerCase();
      if (!name.contains(q) && !model.contains(q) && !plate.contains(q)) {
        return false;
      }
    }
    return true;
  }).toList();
}

Set<int> driverIdSet(List<dynamic>? items) {
  return items
          ?.whereType<Map<String, dynamic>>()
          .map((m) => (m['driverId'] as num?)?.toInt())
          .whereType<int>()
          .toSet() ??
      <int>{};
}
