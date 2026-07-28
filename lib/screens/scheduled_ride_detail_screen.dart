import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../models/scheduled_ride.dart';
import '../services/currency_service.dart';
import '../services/scheduled_ride_service.dart';
import '../services/storage_service.dart';
import '../utils/address_utils.dart';

class ScheduledRideDetailScreen extends StatefulWidget {
  final ScheduledRide ride;

  const ScheduledRideDetailScreen({super.key, required this.ride});

  @override
  State<ScheduledRideDetailScreen> createState() => _ScheduledRideDetailScreenState();
}

class _ScheduledRideDetailScreenState extends State<ScheduledRideDetailScreen> {
  ScheduledRide? _ride;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _refreshRide();
  }

  Future<void> _refreshRide() async {
    if (_ride?.id == null) return;
    final token = StorageService.getToken();
    if (token == null) return;
    final ride = await ScheduledRideService.getById(_ride!.id!, token);
    if (mounted && ride != null) {
      setState(() => _ride = ride);
    }
  }

  Future<void> _cancelRide() async {
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelScheduledRide),
        content: Text(l10n.areYouSureYouWantToCancelThisRide),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.yesCancel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final token = StorageService.getToken();
      if (token == null) return;

      final success = await ScheduledRideService.cancel(_ride!.id!, token);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rideCancelled2),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ride = _ride;
    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.rideDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dateStr = DateFormat('MMM dd, yyyy – HH:mm').format(ride.scheduledAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rideDetails),
        actions: [
          if (ride.isScheduled || ride.isAssigned)
            IconButton(
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: _isLoading ? null : _cancelRide,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRide,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(ride, dateStr),
              AppSpacing.gapLg,
              _buildAddressSection(ride),
              AppSpacing.gapLg,
              if (ride.isAssigned || ride.isDriverArrived) ...[
                _buildDriverSection(ride),
                AppSpacing.gapLg,
              ],
              if (ride.pickupCode != null && (ride.isAssigned || ride.isDriverArrived)) ...[
                _buildPickupCodeCard(ride),
                AppSpacing.gapLg,
              ],
              _buildInfoSection(ride),
              if (ride.cancellationReason != null) ...[
                AppSpacing.gapLg,
                _buildCancellationCard(ride),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ScheduledRide ride, String dateStr) {
    Color statusColor;
    switch (ride.status) {
      case 'ASSIGNED':
        statusColor = AppColors.info;
        break;
      case 'DRIVER_ARRIVED':
        statusColor = AppColors.success;
        break;
      case 'STARTED':
        statusColor = AppColors.primary;
        break;
      case 'CANCELLED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: AppRadius.smRadius,
              ),
              child: Text(
                ride.status,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.schedule, size: 16, color: AppColors.textTertiary),
            AppSpacing.hGapXs,
            Text(
              dateStr,
              style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(ScheduledRide ride) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 16, color: AppColors.pickupMarker),
                AppSpacing.hGapSm,
                Text(l10n.pickup, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
            AppSpacing.gapXs,
            Text(ride.pickupAddress, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            Text(
              formatLatLng(ride.pickupLatitude, ride.pickupLongitude),
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.error),
                AppSpacing.hGapSm,
                Text(l10n.dropoff, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
            AppSpacing.gapXs,
            Text(ride.dropoffAddress, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            Text(
              formatLatLng(ride.dropoffLatitude, ride.dropoffLongitude),
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection(ScheduledRide ride) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(l10n.driver, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
            AppSpacing.gapSm,
            if (ride.driverName != null)
              Text(ride.driverName!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (ride.driverPhone != null)
              Text(ride.driverPhone!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupCodeCard(ScheduledRide ride) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Text(
              l10n.pickupCode,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            AppSpacing.gapSm,
            Text(
              ride.pickupCode!,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              l10n.shareThisCodeWithYourDriverToStartTheRide,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ScheduledRide ride) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.details, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            AppSpacing.gapSm,
            if (ride.rideType != null)
              _infoRow(l10n.type, ride.rideType!),
            if (ride.estimatedFare != null)
              _infoRow(l10n.fare, CurrencyService.format(ride.estimatedFare!)),
            if (ride.estimatedDistance != null)
              _infoRow(l10n.distance, '${ride.estimatedDistance!.toStringAsFixed(1)} km'),
            if (ride.estimatedDuration != null)
              _infoRow(l10n.duration, '${ride.estimatedDuration} min'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCancellationCard(ScheduledRide ride) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppColors.error.withValues(alpha: 0.05),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error, size: 20),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                ride.cancellationReason ?? l10n.cancelled,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
