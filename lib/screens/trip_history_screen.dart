import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../screens/debug_screen.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _rides.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _rides.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _rides.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final ride = _rides[index];
                      return _buildTripCard(ride);
                    },
                  ),
                ),
    );
  }

  Widget _buildTripCard(Ride ride) {
    final dateStr = ride.requestedAt != null
        ? DateFormat('MMM dd, yyyy – HH:mm').format(ride.requestedAt!)
        : '';
    final fare = ride.finalFare ?? ride.estimatedFare;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    borderRadius: BorderRadius.circular(8),
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
                    '\$${fare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 4),
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
              const SizedBox(height: 8),
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
            if (ride.estimatedDistance != null) ...[
              const SizedBox(height: 4),
              Text(
                '${ride.estimatedDistance!.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
