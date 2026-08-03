import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/admin_drivers_service.dart';
import '../services/photo_service.dart';
import '../utils/admin_driver_filters.dart';
import 'admin_driver_details_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import '../services/recorded_screen_mixin.dart';

class AdminDriverListScreen extends StatefulWidget {
  const AdminDriverListScreen({
    super.key,
    this.initialStatusFilter = adminStatusAll,
    this.initialExpiryFilter = adminExpiryNone,
  });

  final String initialStatusFilter;
  final String initialExpiryFilter;

  @override
  State<AdminDriverListScreen> createState() => _AdminDriverListScreenState();
}

class _AdminDriverListScreenState extends State<AdminDriverListScreen> with RecordedScreenMixin<AdminDriverListScreen> {
  List<Map<String, dynamic>>? _drivers;
  bool _loading = true;
  String? _token;
  String _filterText = '';
  late String _statusFilter;
  late String _expiryFilter;
  Set<int> _expiredIds = <int>{};
  Set<int> _expiring7Ids = <int>{};
  Set<int> _expiring30Ids = <int>{};

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _statusFilter = widget.initialStatusFilter;
    _expiryFilter = widget.initialExpiryFilter;
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final driversFuture = AdminDriversService.getDrivers(_token!);
    final expiryFuture = AdminDriversService.getExpirySummary(_token!);
    final drivers = await driversFuture;
    final expiry = await expiryFuture;
    if (!mounted) return;
    setState(() {
      _drivers = drivers;
      _expiredIds = driverIdSet(expiry?['expired'] as List<dynamic>?);
      _expiring7Ids = driverIdSet(expiry?['expiring7'] as List<dynamic>?);
      _expiring30Ids = driverIdSet(expiry?['expiring30'] as List<dynamic>?);
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredDrivers {
    if (_drivers == null) return [];
    return filterAdminDrivers(
      drivers: _drivers!,
      statusFilter: _statusFilter,
      expiryFilter: _expiryFilter,
      expiredDriverIds: _expiredIds,
      expiring7DriverIds: _expiring7Ids,
      expiring30DriverIds: _expiring30Ids,
      filterText: _filterText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).allDrivers),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: l10n.searchByNameVehiclePlate,
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
                _buildChip(l10n.all, adminStatusAll),
                const SizedBox(width: 6),
                _buildChip(l10n.statusDraft, adminStatusDraft),
                const SizedBox(width: 6),
                _buildChip(l10n.statusPending, adminStatusPending),
                const SizedBox(width: 6),
                _buildChip(l10n.approved, adminStatusApproved),
                const SizedBox(width: 6),
                _buildChip(l10n.rejected, adminStatusRejected),
                const SizedBox(width: 6),
                _buildChip(l10n.online, adminStatusOnline),
                const SizedBox(width: 6),
                _buildChip(l10n.offline, adminStatusOffline),
                const SizedBox(width: 6),
                _buildChip(l10n.available, adminStatusAvailable),
                const SizedBox(width: 6),
                _buildChip(l10n.onRide, adminStatusBusy),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildExpiryChip(l10n.all, adminExpiryNone),
                const SizedBox(width: 6),
                _buildExpiryChip(l10n.expiredDocuments, adminExpiryExpired),
                const SizedBox(width: 6),
                _buildExpiryChip(l10n.expiringWithin7Days, adminExpiryExpiring7),
                const SizedBox(width: 6),
                _buildExpiryChip(l10n.expiringWithin30Days, adminExpiryExpiring30),
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

  Widget _buildExpiryChip(String label, String value) {
    final selected = _expiryFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _expiryFilter = value),
      selectedColor: AppColors.warning.withValues(alpha: 0.2),
      checkmarkColor: AppColors.warning,
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: TextStyle(
        color: selected ? AppColors.warning : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);

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
            Text(l10n.failedToLoadDrivers, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDrivers,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
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
            Text(l10n.noDriversFound2, style: const TextStyle(color: AppColors.textSecondary)),
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

  Widget _buildVerificationBadge(Map<String, dynamic> driver) {
    final status = driver['verificationStatus'] as String?;
    final pendingDocs = (driver['pendingDocs'] as num?)?.toInt() ?? 0;

    final (label, color) = switch (status) {
      'PENDING' => (pendingDocs > 0 ? 'Pending · $pendingDocs' : 'Pending', AppColors.warning),
      'REJECTED' => ('Rejected', AppColors.error),
      _ => (null, AppColors.textTertiary),
    };
    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final l10n = AppLocalizations.of(context);
    final online = driver['online'] == true;
    final active = driver['active'] == true;
    final onRide = driver['currentRideId'] != null;
    final rating = driver['averageRating'] != null ? (driver['averageRating'] as num).toDouble() : null;
    final lat = driver['currentLatitude'] as double?;
    final lng = driver['currentLongitude'] as double?;

    String statusText;
    Color statusColor;
    if (online && onRide) {
      statusText = l10n.onRide;
      statusColor = AppColors.warning;
    } else if (online && active) {
      statusText = l10n.available;
      statusColor = AppColors.success;
    } else if (online) {
      statusText = l10n.online;
      statusColor = AppColors.primary;
    } else {
      statusText = l10n.offline;
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
              UserAvatar(
                photoUrl: PhotoService.resolvePhotoUrl(driver['photoUrl'] as String?),
                displayName: driver['name'] as String? ?? 'Driver',
                radius: 22,
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
                  _buildVerificationBadge(driver),
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
