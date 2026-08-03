import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/admin_drivers_service.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../services/photo_service.dart';
import '../widgets/user_avatar.dart';
import '../models/driver_document.dart';
import '../widgets/admin_document_viewer.dart';
import '../widgets/document_status_chip.dart';
import '../utils/address_utils.dart';
import '../services/recorded_screen_mixin.dart';
import 'driver_audit_screen.dart';

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
          Text(AppLocalizations.of(context).failedToLoadDriverDetails, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppLocalizations.of(context).retry),
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
            _buildProfilePhotoReviewCard(),
            const SizedBox(height: 12),
            _buildAuditCard(),
            const SizedBox(height: 12),
            _buildVehicleCard(),
            const SizedBox(height: 12),
            _buildDocumentsCard(),
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
    final phone = d['phoneNumber'] as String?;
    final license = d['licenseNumber'] as String?;
    final l10n = AppLocalizations.of(context);

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
                  displayName: d['name'] as String? ?? 'Driver',
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
            if (phone != null || license != null) ...[
              const SizedBox(height: 12),
              if (phone != null) _buildDetailRow(l10n.phoneNumber, phone),
              if (license != null) _buildDetailRow(l10n.licenseNumber, license),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(
                  Icons.circle,
                  online ? l10n.online : l10n.offline,
                  online ? AppColors.success : AppColors.textTertiary,
                ),
                if (active) _buildInfoChip(Icons.check_circle, l10n.active, AppColors.success),
                if (!active) _buildInfoChip(Icons.block, l10n.blocked, AppColors.error),
                if (verified) _buildInfoChip(Icons.verified, l10n.verified, AppColors.primary),
                if (!verified) _buildInfoChip(Icons.verified, l10n.unverified, AppColors.warning),
                if (d['currentRideId'] != null)
                  _buildInfoChip(Icons.route, l10n.onRide, AppColors.warning),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleVerify(d),
                    icon: Icon(verified ? Icons.verified : Icons.verified, size: 16),
                    label: Text(verified ? l10n.unverify : l10n.verify),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: verified ? AppColors.warning : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleBlock(d),
                    icon: Icon(active ? Icons.block : Icons.check_circle, size: 16),
                    label: Text(active ? l10n.block : l10n.unblock),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: active ? AppColors.error : AppColors.success,
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

  Widget _buildAuditCard() {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DriverAuditScreen(
                driverId: widget.driverId,
                driverName: widget.driverName,
                token: _token ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history, size: 20, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit History',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Document reviews, notifications, and eligibility changes',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    final d = _detail!;
    final model = d['vehicleModel'] as String?;
    final color = d['vehicleColor'] as String?;
    final plate = d['vehicleNumber'] as String?;
    final type = d['vehicleType'] as String?;
    final year = d['vehicleYear'] as int?;
    final vehiclePhotoUrl = PhotoService.resolvePhotoUrl(d['vehiclePhotoUrl'] as String?);
    final l10n = AppLocalizations.of(context);

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
                Text(l10n.vehicle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const Spacer(),
                if (vehiclePhotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: vehiclePhotoUrl,
                      width: 56,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 44,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(l10n.model, model ?? '-'),
            if (color != null) _buildDetailRow(l10n.color, color),
            _buildDetailRow(l10n.plate, plate ?? '-'),
            if (type != null) _buildDetailRow(l10n.type, type),
            if (year != null) _buildDetailRow(l10n.vehicleYear, year.toString()),
          ],
        ),
      ),
    );
  }

  List<DriverDocument> _orderedDocuments() {
    final raw = (_detail!['documents'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
    final byType = <String, DriverDocument>{};
    for (final m in raw) {
      final doc = DriverDocument.fromJson(m);
      if (doc.documentType != null) byType[doc.documentType!] = doc;
    }
    return [
      for (final type in kDriverDocumentTypes)
        if (byType[type] != null) byType[type]!,
    ];
  }

  Widget _buildProfilePhotoReviewCard() {
    DriverDocument? pp;
    for (final d in _orderedDocuments()) {
      if (d.documentType == 'PROFILE_PHOTO') pp = d;
    }
    if (pp == null) return const SizedBox.shrink();
    final currentAvatar = _detail!['photoUrl'] as String?;
    final isApproved = pp.status == 'APPROVED';
    final hasNewPhoto = !isApproved && pp.status != 'REJECTED';
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.face, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Profile Photo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const Spacer(),
                DocumentStatusChip(status: pp.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPhotoColumn(
                    label: 'Current approved photo',
                    subtitle: currentAvatar != null ? 'Visible to everyone' : 'No approved photo yet',
                    child: currentAvatar != null
                        ? UserAvatar(photoUrl: PhotoService.resolvePhotoUrl(currentAvatar), displayName: widget.driverName, radius: 44)
                        : const _EmptyThumb(icon: Icons.person_outline),
                  ),
                ),
                if (hasNewPhoto) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPhotoColumn(
                      label: 'New submitted photo',
                      subtitle: 'Under review',
                      child: _DocumentThumb(driverId: widget.driverId, documentId: pp.id, token: _token ?? ''),
                    ),
                  ),
                ],
              ],
            ),
            if (hasNewPhoto) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _reviewActionButton(
                    label: l10n.approveDocument,
                    icon: Icons.verified_outlined,
                    color: AppColors.success,
                    action: 'approve',
                    document: pp,
                  ),
                  _reviewActionButton(
                    label: l10n.rejectDocument,
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    action: 'reject',
                    document: pp,
                  ),
                  _reviewActionButton(
                    label: l10n.requestReupload,
                    icon: Icons.autorenew,
                    color: AppColors.warning,
                    action: 'request-reupload',
                    document: pp,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoColumn({
    required String label,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        Center(child: child),
      ],
    );
  }

  Widget _reviewActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required String action,
    required DriverDocument document,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _runReview(document.id, action),
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: color),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  Future<void> _runReview(int documentId, String action) async {
    final token = _token;
    if (token == null) return;
    final result = await AdminDriversService.reviewDocument(
      widget.driverId,
      documentId,
      action,
      token,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null
              ? '${action.replaceAll('-', ' ')} submitted'
              : 'Review failed',
        ),
        backgroundColor: result != null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadDetail();
  }

  Widget _buildDocumentsCard() {
    final docs = _orderedDocuments();
    final l10n = AppLocalizations.of(context);

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
                const Icon(Icons.folder_open, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.documents,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.noDocuments,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              )
            else
              ...docs.map((d) => _buildDocumentRow(d)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(DriverDocument doc) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDocumentViewer(
              driverId: widget.driverId,
              documentId: doc.id,
              document: doc,
              token: _token ?? '',
            ),
          ),
        );
        if (changed == true && mounted) _loadDetail();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                switch (doc.documentType) {
                  'PROFILE_PHOTO' => Icons.face,
                  'LICENSE' => Icons.credit_card,
                  'VEHICLE_REGISTRATION' => Icons.description_outlined,
                  'VEHICLE_PHOTO' => Icons.directions_car,
                  'INSURANCE' => Icons.shield_outlined,
                  'NATIONAL_ID' => Icons.badge_outlined,
                  _ => Icons.description_outlined,
                },
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverDocumentTypeLabel(doc.documentType),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  if (doc.expiryDate != null && doc.expiryDate!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.expiresOn}: ${doc.expiryDate}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            DocumentStatusChip(status: doc.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
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
    final l10n = AppLocalizations.of(context);

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
                Text(l10n.statistics, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(Icons.star, rating != null ? rating.toStringAsFixed(1) : l10n.na, l10n.rating2, AppColors.warning),
                _buildStatItem(Icons.route, totalRides.toString(), l10n.rides, AppColors.primary),
                if (totalEarnings != null)
                  _buildStatItem(Icons.attach_money, totalEarnings.toStringAsFixed(2), l10n.earnings, AppColors.success),
              ],
            ),
            if (lat != null && lng != null) ...[
              const Divider(height: 20, color: AppColors.outline),
              _buildDetailRow(l10n.latitude, lat.toStringAsFixed(6)),
              _buildDetailRow(l10n.longitude, lng.toStringAsFixed(6)),
            ],
            if (d['lastSeenAt'] != null) ...[
              const Divider(height: 20, color: AppColors.outline),
              _buildDetailRow(l10n.lastSeen, _formatDateTime(d['lastSeenAt'] as String)),
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
    final l10n = AppLocalizations.of(context);

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
                Text(l10n.currentRide, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(l10n.ride2, rideId.toString()),
            _buildDetailRow(l10n.status, rideStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRidesCard() {
    final rides = (_detail!['recentRides'] as List).cast<Map<String, dynamic>>();
    final l10n = AppLocalizations.of(context);

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
                Text(l10n.recentRides, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                  Text(CurrencyService.format(fare), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVerify(Map<String, dynamic> d) async {
    if (_token == null) return;
    final result = await AdminDriversService.toggleVerify(widget.driverId, _token!);
    if (!mounted) return;
    if (result != null) {
      _loadDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle verification')),
      );
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> d) async {
    if (_token == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
            final l10n = AppLocalizations.of(ctx);
            return AlertDialog(
            title: Text(l10n.confirm),
            content: Text(d['active'] == true
                ? l10n.blockThisDriverTheyWillBeUnableToLoginOrAcceptRides
                : l10n.unblockThisDriver),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(d['active'] == true ? l10n.block : l10n.unblock),
              ),
            ],
          );
            },
    );
    if (confirm != true) return;
    final result = await AdminDriversService.toggleBlock(widget.driverId, _token!);
    if (!mounted) return;
    if (result != null) {
      _loadDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle block status')),
      );
    }
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

class _EmptyThumb extends StatelessWidget {
  final IconData icon;
  const _EmptyThumb({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 28, color: AppColors.textTertiary),
    );
  }
}

class _DocumentThumb extends StatefulWidget {
  final int driverId;
  final int documentId;
  final String token;

  const _DocumentThumb({
    required this.driverId,
    required this.documentId,
    required this.token,
  });

  @override
  State<_DocumentThumb> createState() => _DocumentThumbState();
}

class _DocumentThumbState extends State<_DocumentThumb> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = AdminDriversService.fetchDocumentFile(widget.driverId, widget.documentId, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              snapshot.data!,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          );
        }
        return const _EmptyThumb(icon: Icons.image_outlined);
      },
    );
  }
}
