import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/admin_earnings_service.dart';
import '../theme/app_colors.dart';
import '../services/recorded_screen_mixin.dart';
import '../widgets/shimmer_loading.dart';
import 'admin_settlement_ledger_screen.dart';

class AdminEarningsDashboardScreen extends StatefulWidget {
  const AdminEarningsDashboardScreen({super.key});

  @override
  State<AdminEarningsDashboardScreen> createState() => _AdminEarningsDashboardScreenState();
}

class _AdminEarningsDashboardScreenState extends State<AdminEarningsDashboardScreen> with RecordedScreenMixin<AdminEarningsDashboardScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final summary = await AdminEarningsService.getEarningsSummary(_token!);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings Dashboard'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.payments),
            tooltip: 'Settlement Ledger',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettlementLedgerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ShimmerList(itemCount: 6, itemHeight: 80),
            )
          : _summary == null
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
          const Text('Failed to load earnings data', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _summary!;
    final totalGross = (s['totalGross'] as num?) ?? 0;
    final totalAppFees = (s['totalAppFees'] as num?) ?? 0;
    final totalNet = (s['totalNet'] as num?) ?? 0;
    final totalRides = s['totalRides'] as int? ?? 0;
    final totalDrivers = s['totalDrivers'] as int? ?? 0;
    final topDrivers = (s['topDrivers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(totalGross, totalAppFees, totalNet),
            const SizedBox(height: 12),
            _buildStatsRow(totalRides, totalDrivers),
            const SizedBox(height: 16),
            const Text('Top Drivers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (topDrivers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text('No earnings data yet', style: TextStyle(color: AppColors.textTertiary)),
              )
            else
              ...topDrivers.map((d) => _buildDriverRankCard(d)),
          ],
        ),
      ),
    );
  }

  String _fmt(num v) => CurrencyService.format(v.toDouble());

  Widget _buildSummaryCard(num totalGross, num totalAppFees, num totalNet) {
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
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Revenue Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Gross Revenue', _fmt(totalGross), AppColors.textPrimary),
            const Divider(height: 20, color: AppColors.outline),
            _buildMetricRow('Platform Fees (15%)', _fmt(totalAppFees), AppColors.primary),
            const Divider(height: 20, color: AppColors.outline),
            _buildMetricRow('Driver Payouts', _fmt(totalNet), AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatsRow(int totalRides, int totalDrivers) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.route, totalRides.toString(), 'Total Rides', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.person, totalDrivers.toString(), 'Drivers', AppColors.success)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverRankCard(Map<String, dynamic> driver) {
    final name = driver['driverName'] as String? ?? 'Unknown';
    final net = (driver['totalNet'] as num?) ?? 0;
    final rideCount = driver['rideCount'] as int? ?? 0;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text('$rideCount rides', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            Text(_fmt(net), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success)),
          ],
        ),
      ),
    );
  }
}
