import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/admin_drivers_service.dart';
import '../theme/app_colors.dart';
import '../utils/address_utils.dart';
import '../services/recorded_screen_mixin.dart';

class AdminDriverDetailsScreen extends StatefulWidget {
  final int driverId;
  final String driverName;

  const AdminDriverDetailsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<AdminDriverDetailsScreen> createState() => _AdminDriverDetailsScreenState();
}

class _AdminDriverDetailsScreenState extends State<AdminDriverDetailsScreen> with RecordedScreenMixin<AdminDriverDetailsScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final detail = await AdminDriversService.getDriverDetail(widget.driverId, _token!);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.driverName),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _detail == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          const Text('Failed to load driver details', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 12),
            _buildVehicleCard(),
            const SizedBox(height: 12),
            _buildStatsCard(),
            if (_detail!['currentRideId'] != null) ...[
              const SizedBox(height: 12),
              _buildCurrentRideCard(),
            ],
            if (_detail!['recentRides'] is List && (_detail!['recentRides'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRecentRidesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final d = _detail!;
    final online = d['online'] == true;
    final active = d['active'] == true;
    final verified = d['verified'] == true;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person,
                    color: online ? AppColors.success : AppColors.textTertiary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'] as String? ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(d['email'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      if (d['username'] != null)
                        Text('@${d['username']}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(
                  Icons.circle,
                  online ? 'Online' : 'Offline',
                  online ? AppColors.success : AppColors.textTertiary,
                ),
                if (active) _buildInfoChip(Icons.check_circle, 'Active', AppColors.success),
                if (verified) _buildInfoChip(Icons.verified, 'Verified', AppColors.primary),
                if (d['currentRideId'] != null)
                  _buildInfoChip(Icons.route, 'On Ride', AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    final d = _detail!;
    final model = d['vehicleModel'] as String?;
    final color = d['vehicleColor'] as String?;
    final plate = d['vehicleNumber'] as String?;
    final type = d['vehicleType'] as String?;

    if (model == null && plate == null) return const SizedBox.shrink();

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Vehicle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Model', model ?? '-'),
            if (color != null) _buildDetailRow('Color', color),
            _buildDetailRow('Plate', plate ?? '-'),
            if (type != null) _buildDetailRow('Type', type),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final d = _detail!;
    final rating = d['averageRating'] != null ? (d['averageRating'] as num).toDouble() : null;
    final totalRides = d['totalRides'] as int? ?? 0;
    final totalEarnings = d['totalEarnings'] != null ? (d['totalEarnings'] as num).toDouble() : null;
    final lat = d['currentLatitude'] as double?;
    final lng = d['currentLongitude'] as double?;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Statistics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(Icons.star, rating != null ? rating.toStringAsFixed(1) : 'N/A', 'Rating', AppColors.warning),
                _buildStatItem(Icons.route, totalRides.toString(), 'Rides', AppColors.primary),
                if (totalEarnings != null)
                  _buildStatItem(Icons.attach_money, totalEarnings.toStringAsFixed(2), 'Earnings', AppColors.success),
              ],
            ),
            if (lat != null && lng != null) ...[
              const Divider(height: 20, color: AppColors.outline),
              _buildDetailRow('Latitude', lat.toStringAsFixed(6)),
              _buildDetailRow('Longitude', lng.toStringAsFixed(6)),
            ],
            if (d['lastSeenAt'] != null) ...[
              const Divider(height: 20, color: AppColors.outline),
              _buildDetailRow('Last Seen', _formatDateTime(d['lastSeenAt'] as String)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildCurrentRideCard() {
    final rideId = _detail!['currentRideId'] as int;
    final rideStatus = _detail!['currentRideStatus'] as String? ?? 'UNKNOWN';

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                const Text('Current Ride', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Ride #', rideId.toString()),
            _buildDetailRow('Status', rideStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRidesCard() {
    final rides = (_detail!['recentRides'] as List).cast<Map<String, dynamic>>();

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Recent Rides', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            ...rides.take(10).map((ride) => _buildRideItem(ride)),
          ],
        ),
      ),
    );
  }

  Widget _buildRideItem(Map<String, dynamic> ride) {
    final status = ride['status'] as String? ?? '';
    final fare = ride['finalFare'] != null ? (ride['finalFare'] as num).toDouble() : null;

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
        statusColor = AppColors.success;
        break;
      case 'CANCELLED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return InkWell(
      onTap: () {
        final rideId = ride['rideId'] as int?;
        if (rideId != null) {
          Navigator.pushNamed(
            context,
            '/admin-trip-details',
            arguments: {'rideId': rideId},
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.route, size: 16, color: statusColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride['pickupAddress'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  Text(
                    formatLatLng(
                        (ride['pickupLatitude'] as num?)?.toDouble() ?? 0,
                        (ride['pickupLongitude'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    ride['dropoffAddress'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                  Text(
                    formatLatLng(
                        (ride['dropoffLatitude'] as num?)?.toDouble() ?? 0,
                        (ride['dropoffLongitude'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                if (fare != null)
                  Text('\$${fare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
