import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../services/currency_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_card.dart';
import '../widgets/ride_type_selector.dart';
import '../widgets/bottom_sheet_handle.dart';
import 'package:intl/intl.dart';


class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<Ride> _rides = [];
  List<Ride> _filteredRides = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadPage() async {
    final token = StorageService.getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    final rides = await RideService.getRideHistoryPaginated(token, _currentPage, _pageSize);
    if (!mounted) return;
    setState(() {
      _rides = rides;
      _applyFilter();
      _isLoading = false;
      _hasMore = rides.length >= _pageSize;
    });
  }

  Future<void> _loadMore() async {
    final token = StorageService.getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    final rides = await RideService.getRideHistoryPaginated(token, _currentPage + 1, _pageSize);
    if (!mounted) return;
    setState(() {
      _currentPage++;
      _rides.addAll(rides);
      _applyFilter();
      _isLoading = false;
      _hasMore = rides.length >= _pageSize;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      case 'REQUESTED': return 'Requested';
      case 'ACCEPTED': return 'Accepted';
      case 'DRIVER_ARRIVED': return 'Driver Arrived';
      case 'STARTED': return 'Started';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  void _applyFilter() {
    if (_statusFilter == 'ALL') {
      _filteredRides = List.from(_rides);
    } else {
      _filteredRides = _rides.where((r) => r.status == _statusFilter).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: AppColors.primaryLight),
      ),
      body: Column(
        children: [
          Semantics(
            label: 'Filter trips by status',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('COMPLETED', 'Completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CANCELLED', 'Cancelled'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading && _rides.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.textTertiary),
                      AppSpacing.gapLg,
                      const Text(
                        'No trips yet',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPage,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: AppSpacing.screenPadding,
                    itemCount: _filteredRides.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredRides.length) {
                        return Padding(
                          padding: AppSpacing.cardPadding,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final ride = _filteredRides[index];
                      return _buildTripCard(ride);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _statusFilter == value;
    return Semantics(
      label: 'Filter by $label',
      child: GestureDetector(
        onTap: () => setState(() {
          _statusFilter = value;
          _applyFilter();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Ride ride) {
    final dateStr = ride.requestedAt != null
        ? DateFormat('MMM dd, yyyy – HH:mm').format(ride.requestedAt!)
        : '';
    final fare = ride.finalFare ?? ride.estimatedFare;

    return Semantics(
      label: 'Trip ${_statusLabel(ride.status)} from ${ride.pickupAddress} to ${ride.dropoffAddress}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: PremiumCard(
          hasRipple: true,
          onTap: () => _showTripReceipt(ride),
          shadows: AppShadows.small,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(ride.status).withValues(alpha: 0.15),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Text(
                      _statusLabel(ride.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(ride.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (fare != null)
                    Text(
                      CurrencyService.format(fare),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
              AppSpacing.gapSm,
              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              AppSpacing.gapSm,
              Row(
                children: [
                  const Icon(Icons.trip_origin, size: 14, color: AppColors.pickupMarker),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXs,
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.dropoffAddress,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (ride.driver != null) ...[
                AppSpacing.gapSm,
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Driver: ${ride.driver!.fullName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
              if (ride.status == 'COMPLETED') ...[
                AppSpacing.gapMd,
                Row(
                  children: [
                    Semantics(
                      label: 'View receipt for this trip',
                      child: TextButton.icon(
                        onPressed: () => _showTripReceipt(ride),
                        icon: const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                        label: const Text('Receipt', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Re-book this trip',
                      child: TextButton.icon(
                        onPressed: () => _rebookTrip(ride),
                        icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                        label: const Text('Re-book', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTripReceipt(Ride ride) {
    final receiptDate = ride.requestedAt != null
        ? DateFormat('MMM dd, yyyy – HH:mm').format(ride.requestedAt!)
        : '';
    final receiptFare = ride.finalFare ?? ride.estimatedFare;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BottomSheetHandle()),
            AppSpacing.gapLg,
            const Text('Trip Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            AppSpacing.gapLg,
            _receiptRow('Status', _statusLabel(ride.status)),
            _receiptRow('Date', receiptDate),
            _receiptRow('Pickup', ride.pickupAddress),
            _receiptRow('Dropoff', ride.dropoffAddress),
            if (ride.estimatedDistance != null) _receiptRow('Distance', '${ride.estimatedDistance!.toStringAsFixed(1)} km'),
            if (ride.rideType.isNotEmpty) _receiptRow('Type', RideTypeSelector.toDisplayName(ride.rideType)),
            const Divider(height: 24),
            _receiptRow('Total', CurrencyService.format(receiptFare ?? 0.0), isBold: true),
            AppSpacing.gapXl,
          ],
        ),
      ),
    );
  }

  void _rebookTrip(Ride ride) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Re-booking from ${ride.pickupAddress}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
