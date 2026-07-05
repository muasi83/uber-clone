import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/admin_drivers_service.dart';
import 'admin_driver_details_screen.dart';
import '../theme/app_colors.dart';

class AdminDriverListScreen extends StatefulWidget {
  const AdminDriverListScreen({super.key});

  @override
  State<AdminDriverListScreen> createState() => _AdminDriverListScreenState();
}

class _AdminDriverListScreenState extends State<AdminDriverListScreen> {
  List<Map<String, dynamic>>? _drivers;
  bool _loading = true;
  String? _token;
  String _filterText = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _token = StorageService.getToken();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final drivers = await AdminDriversService.getDrivers(_token!);
    if (!mounted) return;
    setState(() {
      _drivers = drivers;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredDrivers {
    if (_drivers == null) return [];
    return _drivers!.where((d) {
      if (_statusFilter == 'online' && d['online'] != true) return false;
      if (_statusFilter == 'offline' && d['online'] == true) return false;
      if (_statusFilter == 'busy' && d['currentRideId'] == null) return false;
      if (_statusFilter == 'available' && d['currentRideId'] != null) return false;
      if (_filterText.isNotEmpty) {
        final name = (d['name'] as String? ?? '').toLowerCase();
        final model = (d['vehicleModel'] as String? ?? '').toLowerCase();
        final plate = (d['vehicleNumber'] as String? ?? '').toLowerCase();
        final q = _filterText.toLowerCase();
        if (!name.contains(q) && !model.contains(q) && !plate.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Drivers'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrivers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, vehicle, plate...',
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            onChanged: (v) => setState(() => _filterText = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChip('All', 'all'),
                const SizedBox(width: 6),
                _buildChip('Online', 'online'),
                const SizedBox(width: 6),
                _buildChip('Offline', 'offline'),
                const SizedBox(width: 6),
                _buildChip('Available', 'available'),
                const SizedBox(width: 6),
                _buildChip('On Ride', 'busy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_drivers == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text('Failed to load drivers', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDrivers,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_filteredDrivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text('No drivers found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredDrivers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final driver = _filteredDrivers[index];
          return _buildDriverCard(driver);
        },
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final online = driver['online'] == true;
    final active = driver['active'] == true;
    final onRide = driver['currentRideId'] != null;
    final rating = driver['averageRating'] != null ? (driver['averageRating'] as num).toDouble() : null;
    final lat = driver['currentLatitude'] as double?;
    final lng = driver['currentLongitude'] as double?;

    String statusText;
    Color statusColor;
    if (online && onRide) {
      statusText = 'On Ride';
      statusColor = AppColors.warning;
    } else if (online && active) {
      statusText = 'Available';
      statusColor = AppColors.success;
    } else if (online) {
      statusText = 'Online';
      statusColor = AppColors.primary;
    } else {
      statusText = 'Offline';
      statusColor = AppColors.textTertiary;
    }

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDriverDetailsScreen(
                driverId: (driver['driverId'] as num).toInt(),
                driverName: driver['name'] as String? ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: online ? AppColors.success.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: online ? AppColors.success : AppColors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'] as String? ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (driver['vehicleModel'] != null) ...[
                          Icon(Icons.directions_car, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${driver['vehicleModel']} ${driver['vehicleColor'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (lat != null && lng != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
