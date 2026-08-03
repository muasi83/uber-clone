import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/admin_settlement_service.dart';
import '../theme/app_colors.dart';
import '../services/recorded_screen_mixin.dart';
import '../widgets/shimmer_loading.dart';

class AdminDriverSettlementScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final DateTime? from;
  final DateTime? to;

  const AdminDriverSettlementScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    this.from,
    this.to,
  });

  @override
  State<AdminDriverSettlementScreen> createState() => _AdminDriverSettlementScreenState();
}

class _AdminDriverSettlementScreenState extends State<AdminDriverSettlementScreen>
    with RecordedScreenMixin<AdminDriverSettlementScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _token;
  String _sort = 'date';

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED', extraDetails: {'driverId': widget.driverId});
    _token = StorageService.getToken();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final detail = await AdminSettlementService.getDriverSettlementDetail(
      driverId: widget.driverId,
      token: _token!,
      from: widget.from,
      to: widget.to,
      sort: _sort,
    );
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _changeSort(String sort) async {
    if (_sort == sort) return;
    setState(() => _sort = sort);
    await _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.driverName),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: _sort,
            tooltip: AppLocalizations.of(context).sortBy,
            onSelected: _changeSort,
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context);
              return [
                PopupMenuItem(value: 'date', child: Text(l10n.sortDate)),
                PopupMenuItem(value: 'score', child: Text(l10n.sortScore)),
                PopupMenuItem(value: 'net', child: Text(l10n.sortNet)),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ShimmerList(itemCount: 6, itemHeight: 100),
            )
          : _detail == null
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
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    final d = _detail!;
    final header = d['header'] as Map<String, dynamic>? ?? {};
    final trips = (d['trips'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final completedTrips = (header['completedTrips'] as num?) ?? 0;
    final verifiedRides = (header['verifiedRides'] as num?) ?? 0;
    final suspiciousRides = (header['suspiciousRides'] as num?) ?? 0;
    final failedRides = (header['failedRides'] as num?) ?? 0;
    final unverifiedRides = (header['unverifiedRides'] as num?) ?? 0;
    final recommended = (header['recommendedSettlement'] as num?) ?? 0;
    final waiting = (header['waitingForPayment'] as num?) ?? 0;
    final underReview = (header['underReview'] as num?) ?? 0;
    final rejected = (header['rejected'] as num?) ?? 0;
    final reliabilityVerified = (header['reliabilityVerifiedPct'] as num?) ?? 0;
    final reliabilitySuspicious = (header['reliabilitySuspiciousPct'] as num?) ?? 0;
    final reliabilityFailed = (header['reliabilityFailedPct'] as num?) ?? 0;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(l10n, completedTrips, verifiedRides, suspiciousRides, failedRides, unverifiedRides, recommended, waiting, underReview, rejected),
          const SizedBox(height: 12),
          _buildReliabilityCard(l10n, reliabilityVerified, reliabilitySuspicious, reliabilityFailed),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.trips, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Text('${trips.length}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          if (trips.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(l10n.noSettlementData, style: const TextStyle(color: AppColors.textTertiary)),
            )
          else
            ...trips.map((t) => _buildTripRow(t)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n, num completed, num verified, num suspicious, num failed, num unverified, num recommended, num waiting, num review, num rejected) {
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
                const Icon(Icons.payments, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(l10n.settlement, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAmountCell(l10n.recommendedSettlement, recommended, AppColors.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAmountCell(l10n.waitingForPayment, waiting, AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAmountCell(l10n.underReview, review, AppColors.info),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAmountCell(l10n.rejected, rejected, AppColors.error),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.outline),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCountCell(l10n.completedTrips, completed, AppColors.primary),
                _buildCountCell(l10n.verified, verified, AppColors.success),
                _buildCountCell(l10n.suspicious, suspicious, AppColors.warning),
                _buildCountCell(l10n.failed, failed, AppColors.error),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountCell(l10n.unverifiedRides, unverified, AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCell(String label, num amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CurrencyService.format(amount.toDouble()),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCountCell(String label, num value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildReliabilityCard(AppLocalizations l10n, num verifiedPct, num suspiciousPct, num failedPct) {
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
                const Icon(Icons.verified, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(l10n.reliability, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            _buildReliabilityBar(l10n.verified, verifiedPct, AppColors.success),
            const SizedBox(height: 8),
            _buildReliabilityBar(l10n.suspicious, suspiciousPct, AppColors.warning),
            const SizedBox(height: 8),
            _buildReliabilityBar(l10n.failed, failedPct, AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildReliabilityBar(String label, num pct, Color color) {
    final pctValue = pct.toDouble().clamp(0, 100);
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pctValue / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '${pctValue.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _verificationColor(String? status) {
    switch (status) {
      case 'VERIFIED':
        return AppColors.success;
      case 'SUSPICIOUS':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _settlementColor(String? status) {
    switch (status) {
      case 'PAYABLE':
        return AppColors.success;
      case 'WAITING_PAYMENT':
        return AppColors.warning;
      case 'UNDER_REVIEW':
        return AppColors.info;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  Widget _buildTripRow(Map<String, dynamic> t) {
    final l10n = AppLocalizations.of(context);
    final rideId = (t['rideId'] as num?)?.toInt() ?? 0;
    final completedAt = t['completedAt'] as String?;
    final verificationStatus = t['verificationStatus'] as String?;
    final settlementStatus = t['settlementStatus'] as String?;
    final verificationScore = t['verificationScore'] as num?;
    final paymentMethod = t['paymentMethod'] as String?;
    final paymentStatus = t['paymentStatus'] as String?;
    final netAmount = (t['netAmount'] as num?) ?? 0;
    final grossAmount = (t['grossAmount'] as num?) ?? 0;
    final reasons = (t['reasons'] as List<dynamic>?)?.cast<String>() ?? [];

    final date = completedAt != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(completedAt))
        : '';

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#$rideId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _settlementColor(settlementStatus).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    settlementStatus ?? 'UNKNOWN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _settlementColor(settlementStatus)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(verificationStatus, _verificationColor(verificationStatus), l10n.verification),
                const SizedBox(width: 8),
                if (verificationScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${l10n.score}: ${verificationScore.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                const Spacer(),
                Text(CurrencyService.format(netAmount.toDouble()),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.payment, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${paymentMethod ?? ''} · ${paymentStatus ?? ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const Spacer(),
                Text('${l10n.gross}: ${CurrencyService.format(grossAmount.toDouble())}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(l10n.reasons, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                reasons.join(', '),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status ?? label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
