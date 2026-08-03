import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/admin_settlement_service.dart';
import '../theme/app_colors.dart';
import '../services/recorded_screen_mixin.dart';
import '../widgets/shimmer_loading.dart';
import 'admin_driver_settlement_screen.dart';

enum _RangePreset {
  today,
  thisWeek,
  thisMonth,
  last30Days,
  custom,
}

class AdminSettlementDashboardScreen extends StatefulWidget {
  const AdminSettlementDashboardScreen({super.key});

  @override
  State<AdminSettlementDashboardScreen> createState() => _AdminSettlementDashboardScreenState();
}

class _AdminSettlementDashboardScreenState extends State<AdminSettlementDashboardScreen>
    with RecordedScreenMixin<AdminSettlementDashboardScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _token;
  _RangePreset _preset = _RangePreset.last30Days;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _loadSummary();
  }

  (DateTime?, DateTime?) _rangeFor(_RangePreset p) {
    final now = DateTime.now();
    switch (p) {
      case _RangePreset.today:
        return (now, now);
      case _RangePreset.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (start, now);
      case _RangePreset.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case _RangePreset.last30Days:
        return (now.subtract(const Duration(days: 29)), now);
      case _RangePreset.custom:
        return (_customFrom, _customTo);
    }
  }

  Future<void> _loadSummary() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final (from, to) = _rangeFor(_preset);
    final summary = await AdminSettlementService.getSettlementSummary(
      token: _token!,
      from: from,
      to: to,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    if (!mounted) return;
    final from = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? now.subtract(const Duration(days: 29)),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (from == null) return;
    if (!mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _customTo ?? now,
      firstDate: from,
      lastDate: now,
    );
    if (to == null) return;
    setState(() {
      _preset = _RangePreset.custom;
      _customFrom = from;
      _customTo = to;
    });
    await _loadSummary();
  }

  String _rangeLabel(AppLocalizations l10n) {
    final (from, to) = _rangeFor(_preset);
    final fmt = DateFormat('MMM dd');
    if (from == null || to == null) return l10n.custom;
    if (_preset == _RangePreset.custom) return '${fmt.format(from)} – ${fmt.format(to)}';
    return '${fmt.format(from)} – ${fmt.format(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settlementDashboard),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(l10n.failedToLoadEarningsData, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    final s = _summary!;
    final cards = s['cards'] as Map<String, dynamic>? ?? {};
    final totals = s['totals'] as Map<String, dynamic>? ?? {};
    final drivers = (s['drivers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final recommended = (cards['recommendedSettlement'] as num?) ?? 0;
    final waiting = (cards['waitingForPayment'] as num?) ?? 0;
    final underReview = (cards['underReview'] as num?) ?? 0;
    final rejected = (cards['rejected'] as num?) ?? 0;
    final recommendedRides = (cards['recommendedRides'] as num?) ?? 0;
    final waitingRides = (cards['waitingRides'] as num?) ?? 0;
    final underReviewRides = (cards['underReviewRides'] as num?) ?? 0;
    final rejectedRides = (cards['rejectedRides'] as num?) ?? 0;

    final completed = (totals['completedRides'] as num?) ?? 0;
    final verified = (totals['verifiedRides'] as num?) ?? 0;
    final suspicious = (totals['suspiciousRides'] as num?) ?? 0;
    final failed = (totals['failedRides'] as num?) ?? 0;
    final unverified = (totals['unverifiedRides'] as num?) ?? 0;

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRangeBar(l10n),
            const SizedBox(height: 12),
            _buildPayTodayCard(l10n, recommended, recommendedRides),
            const SizedBox(height: 12),
            _buildStatusGrid(l10n, waiting, waitingRides, underReview, underReviewRides, rejected, rejectedRides),
            const SizedBox(height: 12),
            _buildTotalsRow(l10n, completed, verified, suspicious, failed, unverified),
            const SizedBox(height: 16),
            Text(l10n.drivers, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (drivers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(l10n.noDriversInRange, style: const TextStyle(color: AppColors.textTertiary)),
              )
            else
              ...drivers.map((d) => _buildDriverRow(d)),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeBar(AppLocalizations l10n) {
    final presets = [
      (_RangePreset.today, l10n.today),
      (_RangePreset.thisWeek, l10n.thisWeek),
      (_RangePreset.thisMonth, l10n.thisMonth),
      (_RangePreset.last30Days, l10n.last30Days),
      (_RangePreset.custom, l10n.custom),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presets.map((p) {
                    final (value, label) = p;
                    final selected = _preset == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (_) async {
                          if (value == _RangePreset.custom) {
                            await _pickCustomRange();
                          } else {
                            setState(() => _preset = value);
                            await _loadSummary();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(_rangeLabel(l10n), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildPayTodayCard(AppLocalizations l10n, num amount, num rides) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.primaryGradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.payments, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.payToday, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(CurrencyService.format(amount.toDouble()),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyService.format(amount.toDouble()),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(l10n.rides2(rides.toString()), style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGrid(AppLocalizations l10n, num waiting, num waitingRides, num review, num reviewRides, num rejected, num rejectedRides) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            label: l10n.waitingForPayment,
            amount: waiting,
            rides: waitingRides,
            color: AppColors.warning,
            icon: Icons.schedule,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            label: l10n.underReview,
            amount: review,
            rides: reviewRides,
            color: AppColors.info,
            icon: Icons.visibility,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            label: l10n.rejected,
            amount: rejected,
            rides: rejectedRides,
            color: AppColors.error,
            icon: Icons.cancel,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({required String label, required num amount, required num rides, required Color color, required IconData icon}) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(CurrencyService.format(amount.toDouble()),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary), textAlign: TextAlign.center),
            Text(l10nRides(rides), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  String l10nRides(num rides) => '$rides ${rides == 1 ? 'ride' : 'rides'}';

  Widget _buildTotalsRow(AppLocalizations l10n, num completed, num verified, num suspicious, num failed, num unverified) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTotalItem(l10n.completedTrips, completed, AppColors.primary),
                _buildTotalItem(l10n.verified, verified, AppColors.success),
                _buildTotalItem(l10n.suspicious, suspicious, AppColors.warning),
                _buildTotalItem(l10n.failed, failed, AppColors.error),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTotalItem(l10n.unverifiedRides, unverified, AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, num value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildDriverRow(Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context);
    final name = d['driverName'] as String? ?? 'Unknown';
    final driverId = (d['driverId'] as num?)?.toInt() ?? 0;
    final payable = (d['payable'] as num?) ?? 0;
    final rideCount = (d['rideCount'] as num?) ?? 0;
    final verifiedCount = (d['verifiedCount'] as num?) ?? 0;
    final suspiciousCount = (d['suspiciousCount'] as num?) ?? 0;
    final failedCount = (d['failedCount'] as num?) ?? 0;
    final (from, to) = _rangeFor(_preset);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
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
              builder: (_) => AdminDriverSettlementScreen(
                driverId: driverId,
                driverName: name,
                from: from,
                to: to,
              ),
            ),
          ).then((_) => _loadSummary());
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text(l10n.rides2(rideCount.toString()), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyService.format(payable.toDouble()),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success)),
                      Text(l10n.payable, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMiniChip(verifiedCount, l10n.verified, AppColors.success),
                  const SizedBox(width: 8),
                  _buildMiniChip(suspiciousCount, l10n.underReviewShort, AppColors.warning),
                  const SizedBox(width: 8),
                  _buildMiniChip(failedCount, l10n.rejectedShort, AppColors.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(num count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
