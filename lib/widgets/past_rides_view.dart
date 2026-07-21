import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride_model.dart';
import '../services/currency_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/address_utils.dart';

class PastRidesView extends StatefulWidget {
  const PastRidesView({super.key});

  @override
  State<PastRidesView> createState() => _PastRidesViewState();
}

class _PastRidesViewState extends State<PastRidesView> {
  List<Ride> _allRides = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadPage() async {
    final token = StorageService.getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    final rides = await RideService.getRideHistoryPaginated(token, 0, _pageSize);
    if (!mounted) return;
    setState(() {
      _allRides = rides;
      _currentPage = 0;
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
      _allRides.addAll(rides);
      _isLoading = false;
      _hasMore = rides.length >= _pageSize;
    });
  }

  bool _isTerminalStatus(String status) {
    return status == 'COMPLETED' || status == 'CANCELLED';
  }

  Map<String, List<Ride>> _groupByMonth(List<Ride> rides) {
    final Map<String, List<Ride>> groups = {};
    for (final ride in rides) {
      if (!_isTerminalStatus(ride.status)) continue;
      final date = ride.requestedAt ?? ride.completedAt ?? ride.cancelledAt;
      if (date == null) continue;
      final key = DateFormat('MMMM yyyy').format(date);
      groups.putIfAbsent(key, () => []).add(ride);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allRides.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadPage,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    final groups = _groupByMonth(_allRides);
    if (groups.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'No past rides yet',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your completed trips will appear here',
                    style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final sortedMonths = groups.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sortedMonths.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sortedMonths.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final month = sortedMonths[index];
        final rides = groups[month]!;
        return _buildMonthGroup(month, rides);
      },
    );
  }

  Widget _buildMonthGroup(String month, List<Ride> rides) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            month,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...rides.map((ride) => _buildRideCard(ride)),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
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

  Widget _buildRideCard(Ride ride) {
    final dateStr = ride.requestedAt != null
        ? DateFormat('MMM dd, yyyy – HH:mm').format(ride.requestedAt!)
        : '';
    final fare = ride.finalFare ?? ride.estimatedFare;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 11,
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
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 14, color: AppColors.pickupMarker),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatLatLng(ride.pickupLatitude, ride.pickupLongitude),
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.dropoffAddress,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatLatLng(ride.dropoffLatitude, ride.dropoffLongitude),
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (ride.estimatedDistance != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${ride.estimatedDistance!.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
