import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/address_utils.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/scheduled_ride_service.dart';
import '../services/websocket_service.dart';
import '../models/scheduled_ride.dart';
import '../screens/scheduled_ride_detail_screen.dart';
import 'schedule_ride_sheet.dart';

class UpcomingRidesView extends StatefulWidget {
  const UpcomingRidesView({super.key});

  @override
  State<UpcomingRidesView> createState() => _UpcomingRidesViewState();
}

class _UpcomingRidesViewState extends State<UpcomingRidesView> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _currentMonth;
  List<ScheduledRide> _rides = [];
  bool _isLoading = true;
  StreamSubscription? _rideEventsSub;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _loadRides();
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _rideEventsSub?.cancel();
    super.dispose();
  }

  void _setupWebSocketListener() {
    _rideEventsSub?.cancel();
    _rideEventsSub = WebSocketService.rideEvents.listen((event) {
      final type = event['type'] ?? '';
      if (type.startsWith('scheduled_ride_') && mounted) {
        _loadRides();
      }
    });
  }

  Future<void> _loadRides() async {
    final token = StorageService.getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    final rides = await ScheduledRideService.getUpcoming(token);
    if (mounted) {
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    }
  }

  void _previousMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  int _weekdayOffset(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % 7;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final totalDays = _daysInMonth(_currentMonth);
    final offset = _weekdayOffset(_currentMonth);
    final today = DateTime.now();
    final cellSize = (MediaQuery.of(context).size.width - 48 - 32) / 7;

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                        color: AppColors.textPrimary,
                      ),
                      Text(
                        '${_months[_currentMonth.month - 1]} ${_currentMonth.year}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((d) => SizedBox(
                              width: cellSize,
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: (MediaQuery.of(context).size.width - 48 - cellSize * 7 - 32) / 6,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < offset; i++)
                        SizedBox(width: cellSize, height: 38),
                      for (int d = 1; d <= totalDays; d++) ...[
                        _dayCell(d, cellSize, today),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  enableDrag: false,
                  isDismissible: false,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => ScheduleRideSheet(selectedDate: _selectedDate),
                );
                if (result == true) _loadRides();
              },
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Later Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_rides.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._rides.map((ride) => _buildRideCard(ride)),
          ] else if (!_isLoading) ...[
            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text(
                    'No upcoming rides',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Schedule a ride using the button above',
                    style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
          if (_isLoading && _rides.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _buildRideCard(ScheduledRide ride) {
    final dateStr = DateFormat('MMM dd, yyyy – HH:mm').format(ride.scheduledAt);
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduledRideDetailScreen(ride: ride),
          ),
        );
        if (result == true) _loadRides();
      },
      child: Card(
      margin: const EdgeInsets.only(top: 12),
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
                    color: AppColors.info.withValues(alpha: 0.15),
          borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    ride.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            if (ride.estimatedFare != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    CurrencyService.format(ride.estimatedFare!),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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

  Widget _dayCell(int day, double cellSize, DateTime today) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, today);
    final hasRide = _rides.any((r) => _isSameDay(r.scheduledAt, date));

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        width: cellSize,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : null,
          borderRadius: AppRadius.smRadius,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
              ),
            ),
            if (hasRide && !isSelected)
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
