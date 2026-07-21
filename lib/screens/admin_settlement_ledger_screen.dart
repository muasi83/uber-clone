import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/admin_earnings_service.dart';
import '../theme/app_colors.dart';
import '../services/recorded_screen_mixin.dart';
import '../widgets/shimmer_loading.dart';

class AdminSettlementLedgerScreen extends StatefulWidget {
  const AdminSettlementLedgerScreen({super.key});

  @override
  State<AdminSettlementLedgerScreen> createState() => _AdminSettlementLedgerScreenState();
}

class _AdminSettlementLedgerScreenState extends State<AdminSettlementLedgerScreen> with RecordedScreenMixin<AdminSettlementLedgerScreen> {
  List<Map<String, dynamic>> _settlements = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final result = await AdminEarningsService.getSettlements(_token!);
    if (!mounted) return;
    setState(() {
      _settlements = (result?['settlements'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settlement Ledger'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Settlement',
            onPressed: _showCreateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettlements,
          ),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ShimmerList(itemCount: 5, itemHeight: 100),
            )
          : _settlements.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text('No settlements recorded', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Settlement'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadSettlements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _settlements.length,
        itemBuilder: (context, index) {
          final s = _settlements[index];
          return _buildSettlementCard(s);
        },
      ),
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> s) {
    final name = s['driverName'] as String? ?? 'Unknown';
    final net = (s['netAmount'] as num?) ?? 0;
    final gross = (s['grossAmount'] as num?) ?? 0;
    final appFee = (s['appFee'] as num?) ?? 0;
    final ref = s['settlementReference'] as String? ?? '';
    final receipt = s['receiptNumber'] as String?;
    final status = s['status'] as String? ?? 'PENDING';
    final createdAt = s['createdAt'] as String?;

    final date = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))
        : '';

    final isSettled = status == 'SETTLED';
    final statusColor = isSettled ? AppColors.success : AppColors.warning;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSettled
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSettled ? Icons.check_circle : Icons.pending,
                    size: 18,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      if (date.isNotEmpty)
                        Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildDetail('Gross', CurrencyService.format(gross.toDouble())),
                const SizedBox(width: 16),
                _buildDetail('Fee', CurrencyService.format(appFee.toDouble())),
                const SizedBox(width: 16),
                _buildDetail('Net', CurrencyService.format(net.toDouble())),
              ],
            ),
            if (ref.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Ref: $ref', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
            if (receipt != null && receipt.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Receipt: $receipt', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final driverIdCtrl = TextEditingController();
    final grossCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final netCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final receiptCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Settlement', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(driverIdCtrl, 'Driver ID', 'Enter driver user ID'),
              _dialogField(grossCtrl, 'Gross Amount', '0.00'),
              _dialogField(feeCtrl, 'App Fee', '0.00'),
              _dialogField(netCtrl, 'Net Amount', '0.00'),
              _dialogField(refCtrl, 'Settlement Reference', 'e.g. STL-001'),
              _dialogField(receiptCtrl, 'Receipt Number (optional)', ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (driverIdCtrl.text.isEmpty || refCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await AdminEarningsService.createSettlement(
                driverId: int.parse(driverIdCtrl.text),
                grossAmount: grossCtrl.text.isEmpty ? '0' : grossCtrl.text,
                appFee: feeCtrl.text.isEmpty ? '0' : feeCtrl.text,
                netAmount: netCtrl.text.isEmpty ? '0' : netCtrl.text,
                settlementReference: refCtrl.text,
                receiptNumber: receiptCtrl.text,
                token: _token!,
              );
              if (!mounted) return;
              if (ok) {
                _loadSettlements();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to create settlement')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
    );
  }
}
