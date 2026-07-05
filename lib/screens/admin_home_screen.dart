import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/admin_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/shimmer_loading.dart';
import 'admin_trip_details_screen.dart';
import '../theme/app_colors.dart';
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _scrollController = ScrollController();
  final _rideIdController = TextEditingController();
  final _riderNameController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  String? _token;
  bool _showFilters = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _statusFilter;
  String? _paymentStatusFilter;
  int _currentPage = 0;
  List<Map<String, dynamic>> _trips = [];
  String? _error;

  final _statusOptions = [
    null,
    'REQUESTED',
    'ACCEPTED',
    'DRIVER_ARRIVED',
    'STARTED',
    'COMPLETED',
    'CANCELLED',
  ];

  final _paymentStatusOptions = [
    null,
    'PENDING',
    'COMPLETED',
    'FAILED',
    'NONE',
  ];

  @override
  void initState() {
    super.initState();
    _token = StorageService.getToken();
    _scrollController.addListener(_onScroll);
    _loadTrips();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rideIdController.dispose();
    _riderNameController.dispose();
    _driverNameController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadTrips() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = 0;
    });
    await _fetchTrips(page: 0, append: false);
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _token == null) return;
    setState(() => _loadingMore = true);
    await _fetchTrips(page: _currentPage + 1, append: true);
    setState(() => _loadingMore = false);
  }

  Future<void> _fetchTrips({required int page, required bool append}) async {
    try {
      final result = await AdminService.getTrips(
        rideId: int.tryParse(_rideIdController.text),
        status: _statusFilter,
        paymentStatus: _paymentStatusFilter,
        riderName: _riderNameController.text.isNotEmpty
            ? _riderNameController.text
            : null,
        driverName: _driverNameController.text.isNotEmpty
            ? _driverNameController.text
            : null,
        fromDate: _dateFromController.text.isNotEmpty
            ? _dateFromController.text
            : null,
        toDate: _dateToController.text.isNotEmpty
            ? _dateToController.text
            : null,
        page: page,
        size: 20,
        token: _token!,
      );

      if (result == null) {
        setState(() => _error = 'Failed to load trips');
        return;
      }

      final rides = (result['rides'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      setState(() {
        if (append) {
          _trips.addAll(rides);
        } else {
          _trips = rides;
        }
        _currentPage = result['currentPage'] as int? ?? page;
        _hasMore = result['hasMore'] as bool? ?? false;
      });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      case 'STARTED':
        return AppColors.primary;
      case 'ACCEPTED':
      case 'DRIVER_ARRIVED':
        return AppColors.info;
      case 'REQUESTED':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'STARTED':
        return Icons.play_circle;
      case 'ACCEPTED':
        return Icons.check;
      case 'DRIVER_ARRIVED':
        return Icons.navigation;
      case 'REQUESTED':
        return Icons.search;
      default:
        return Icons.help;
    }
  }

  Color _paymentStatusColor(String? status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'FAILED':
        return AppColors.error;
      case 'PENDING':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin \u2014 Trip Investigation'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterPanel(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rideIdController,
                  decoration: const InputDecoration(
                    labelText: 'Ride ID',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: _statusOptions.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s ?? 'All'),
                  )).toList(),
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _riderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Rider Name',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateFromController,
                  decoration: const InputDecoration(
                    labelText: 'From Date',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(_dateFromController),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _dateToController,
                  decoration: const InputDecoration(
                    labelText: 'To Date',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(_dateToController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _paymentStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Payment',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: _paymentStatusOptions.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s ?? 'All'),
                  )).toList(),
                  onChanged: (v) => setState(() => _paymentStatusFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loadTrips,
                        child: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _rideIdController.clear();
                          _riderNameController.clear();
                          _driverNameController.clear();
                          _dateFromController.clear();
                          _dateToController.clear();
                          setState(() {
                            _statusFilter = null;
                            _paymentStatusFilter = null;
                          });
                          _loadTrips();
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const ShimmerList(itemCount: 8, itemHeight: 100),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTrips, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text('No trips found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _trips.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _trips.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildTripCard(_trips[index]);
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final rideId = trip['rideId'] as int?;
    final status = trip['status'] as String?;
    final riderName = trip['riderName'] as String? ?? 'Unknown';
    final driverName = trip['driverName'] as String?;
    final requestedAt = trip['requestedAt'] as String?;
    final finalFare = trip['finalFare'] as num?;
    final paymentStatus = trip['paymentStatus'] as String?;

    final date = requestedAt != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(requestedAt))
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (rideId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminTripDetailsScreen(rideId: rideId),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#$rideId',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  StatusBadge(
                    label: status ?? 'UNKNOWN',
                    color: _statusColor(status),
                    icon: _statusIcon(status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(riderName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (driverName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(driverName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(date,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const Spacer(),
                  if (finalFare != null)
                    Text('\$${finalFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _paymentStatusColor(paymentStatus)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      paymentStatus ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: _paymentStatusColor(paymentStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
