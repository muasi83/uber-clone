import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/admin_riders_service.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../services/photo_service.dart';
import '../widgets/user_avatar.dart';
import '../services/recorded_screen_mixin.dart';

class AdminRiderDetailsScreen extends StatefulWidget {
  final int riderId;
  final String riderName;

  const AdminRiderDetailsScreen({
    super.key,
    required this.riderId,
    required this.riderName,
  });

  @override
  State<AdminRiderDetailsScreen> createState() => _AdminRiderDetailsScreenState();
}

class _AdminRiderDetailsScreenState extends State<AdminRiderDetailsScreen> with RecordedScreenMixin<AdminRiderDetailsScreen> {
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
    final detail = await AdminRidersService.getRiderDetail(widget.riderId, _token!);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _toggleBlock(Map<String, dynamic> d) async {
    final token = _token;
    if (token == null) return;
    final result = await AdminRidersService.toggleBlock(widget.riderId, token);
    if (!mounted) return;
    if (result != null) {
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.riderName),
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
          const Text('Failed to load rider details', style: TextStyle(color: AppColors.textSecondary)),
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
            _buildStatsCard(),
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
    final blocked = d['blocked'] == true;
    final phone = d['phoneNumber'] as String?;
    final phoneVerified = d['phoneVerified'] == true;

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
                UserAvatar(
                  photoUrl: PhotoService.resolvePhotoUrl(d['photoUrl'] as String?),
                  displayName: d['name'] as String? ?? 'Rider',
                  radius: 26,
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
                _buildInfoChip(Icons.circle, online ? 'Online' : 'Offline', online ? AppColors.success : AppColors.textTertiary),
                if (blocked) _buildInfoChip(Icons.block, 'Blocked', AppColors.error),
                if (!blocked) _buildInfoChip(Icons.check_circle, 'Active', AppColors.success),
                if (phoneVerified) _buildInfoChip(Icons.phone, 'Phone Verified', AppColors.primary),
              ],
            ),
            if (phone != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Phone', phone),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleBlock(d),
                    icon: Icon(blocked ? Icons.check_circle : Icons.block, size: 16),
                    label: Text(blocked ? 'Unblock' : 'Block'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blocked ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final d = _detail!;
    final totalTrips = d['totalTrips'] as int? ?? 0;
    final totalSpend = d['totalSpend'] != null ? (d['totalSpend'] as num) : 0;
    final createdAt = d['createdAt'] as String?;
    final joined = createdAt != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt)) : '-';

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
                _buildStatItem(Icons.route, 'Total Trips', totalTrips.toString()),
                const SizedBox(width: 16),
                _buildStatItem(Icons.money, 'Total Spend', CurrencyService.format(totalSpend)),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Joined', joined),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
            const SizedBox(height: 12),
            ...rides.take(20).map((ride) => _buildRideRow(ride)),
          ],
        ),
      ),
    );
  }

  Widget _buildRideRow(Map<String, dynamic> ride) {
    final rideId = ride['rideId'] as int?;
    final status = ride['status'] as String? ?? '';
    final pickup = ride['pickupAddress'] as String? ?? '';
    final dropoff = ride['dropoffAddress'] as String? ?? '';
    final requestedAt = ride['requestedAt'] as String?;
    final fare = ride['finalFare'] != null ? (ride['finalFare'] as num) : null;
    final paymentStatus = ride['paymentStatus'] as String?;

    final date = requestedAt != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(requestedAt))
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#$rideId', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  Text(status, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(date, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(pickup, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(dropoff, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (fare != null || paymentStatus != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (fare != null)
                      Text(CurrencyService.format(fare), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    if (paymentStatus != null) ...[
                      const SizedBox(width: 8),
                      Text(paymentStatus, style: TextStyle(fontSize: 10, color: paymentStatus == 'COMPLETED' ? AppColors.success : AppColors.warning)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
