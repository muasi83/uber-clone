import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/admin_drivers_service.dart';
import '../models/driver_document.dart';
import '../theme/app_colors.dart';
import '../services/recorded_screen_mixin.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/admin_driver_filters.dart';
import 'admin_driver_details_screen.dart';
import 'admin_driver_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with RecordedScreenMixin<AdminDashboardScreen> {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _expiry;
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      AdminDriversService.getDashboard(_token!),
      AdminDriversService.getExpirySummary(_token!),
    ]);
    if (!mounted) return;
    setState(() {
      _dashboard = results[0];
      _expiry = results[1];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).dashboard),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ShimmerList(itemCount: 6, itemHeight: 80),
            )
          : (_dashboard == null && _expiry == null)
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
          Text(AppLocalizations.of(context).failedToLoadEarningsData,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerificationSection(),
            const SizedBox(height: 16),
            _buildPendingSection(),
            const SizedBox(height: 16),
            _buildExpirySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    final l10n = AppLocalizations.of(context);
    final d = _dashboard;
    final totalDrivers = d?['totalDrivers'] as int? ?? 0;
    final byStatus = (d?['byStatus'] as Map<String, dynamic>?) ?? {};

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
                Text(l10n.verificationStatus,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const Spacer(),
                Text('$totalDrivers',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.totalDrivers, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _statusCell('DRAFT', _statusCount(byStatus, 'DRAFT'), AppColors.textTertiary, l10n.statusDraft, adminStatusDraft),
                _statusCell('PENDING', _statusCount(byStatus, 'PENDING'), AppColors.warning, l10n.statusPending, adminStatusPending),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusCell('APPROVED', _statusCount(byStatus, 'APPROVED'), AppColors.success, l10n.approved, adminStatusApproved),
                _statusCell('REJECTED', _statusCount(byStatus, 'REJECTED'), AppColors.error, l10n.rejected, adminStatusRejected),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _statusCount(Map<String, dynamic> byStatus, String key) {
    return (byStatus[key] as num?)?.toInt() ?? 0;
  }

  void _openDriverList({required String statusFilter, String expiryFilter = adminExpiryNone}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDriverListScreen(
          initialStatusFilter: statusFilter,
          initialExpiryFilter: expiryFilter,
        ),
      ),
    );
  }

  Widget _statusCell(String key, int count, Color color, String label, String filter) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDriverList(statusFilter: filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingSection() {
    final l10n = AppLocalizations.of(context);
    final d = _dashboard;
    final totalPendingDocs = d?['totalPendingDocs'] as int? ?? 0;
    final driversWithPending = (d?['driversWithPendingDocs'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

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
                const Icon(Icons.pending_actions, size: 18, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.pendingDocuments,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                Text('$totalPendingDocs',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 8),
            if (driversWithPending.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(l10n.noPendingDocuments, style: const TextStyle(color: AppColors.textTertiary)),
              )
            else
              ...driversWithPending.map((item) {
                final driverId = item['driverId'] as int?;
                final name = item['name'] as String? ?? 'Driver #$driverId';
                final count = item['pendingCount'] as int? ?? 0;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('$count ${l10n.pendingDocuments.toLowerCase()}', style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                  onTap: () {
                    if (driverId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminDriverDetailsScreen(driverId: driverId, driverName: name),
                        ),
                      );
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirySection() {
    final l10n = AppLocalizations.of(context);
    final e = _expiry;
    final expired = (e?['expired'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final expiring7 = (e?['expiring7'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final expiring30 = (e?['expiring30'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.documentExpiry,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        _expiryGroup(l10n.expiredDocuments, expired, AppColors.error, Icons.event_busy, adminExpiryExpired),
        const SizedBox(height: 8),
        _expiryGroup(l10n.expiringWithin7Days, expiring7, AppColors.warning, Icons.hourglass_top, adminExpiryExpiring7),
        const SizedBox(height: 8),
        _expiryGroup(l10n.expiringWithin30Days, expiring30, AppColors.info, Icons.hourglass_bottom, adminExpiryExpiring30),
      ],
    );
  }

  Widget _expiryGroup(String title, List<Map<String, dynamic>> items, Color color, IconData icon, String expiryFilter) {
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
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openDriverList(statusFilter: adminStatusAll, expiryFilter: expiryFilter),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Text('${items.length}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(l10n.noExpiringDocuments, style: const TextStyle(color: AppColors.textTertiary)),
              )
            else
              ...items.map((item) {
                final driverId = item['driverId'] as int?;
                final name = item['driverName'] as String? ?? 'Driver #$driverId';
                final type = item['documentType'] as String?;
                final expiry = item['expiryDate'] as String?;
                final expiryText = expiry != null
                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(expiry))
                    : '—';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(driverDocumentTypeLabel(type), style: const TextStyle(fontSize: 11)),
                  trailing: Text(expiryText, style: TextStyle(fontSize: 12, color: color)),
                  onTap: () {
                    if (driverId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminDriverDetailsScreen(driverId: driverId, driverName: name),
                        ),
                      );
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
