import 'package:flutter/material.dart';
import '../services/admin_drivers_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_card.dart';

class DriverAuditScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String token;

  const DriverAuditScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.token,
  });

  @override
  State<DriverAuditScreen> createState() => _DriverAuditScreenState();
}

class _DriverAuditScreenState extends State<DriverAuditScreen> {
  String _filter = 'ALL';
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  bool _error = false;
  int? _total;

  static const _filters = ['ALL', 'DOCUMENTS', 'ELIGIBILITY', 'NOTIFICATIONS'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final data = await AdminDriversService.getDriverAudit(
      widget.driverId,
      widget.token,
      filter: _filter,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _error = true;
        _events = [];
        _total = null;
      } else {
        _events = (data['events'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _total = data['total'] as int?;
      }
    });
  }

  void _setFilter(String filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.driverName} — Audit History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1, color: AppColors.outline),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        children: [
          for (final f in _filters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                label: Text(_filterLabel(f)),
                selected: _filter == f,
                onSelected: (_) => _setFilter(f),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _filter == f ? Colors.white : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.surfaceVariant,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'DOCUMENTS':
        return 'Documents';
      case 'ELIGIBILITY':
        return 'Eligibility';
      case 'NOTIFICATIONS':
        return 'Notifications';
      default:
        return 'All';
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiary),
            AppSpacing.gapMd,
            const Text('Could not load audit history',
                style: TextStyle(color: AppColors.textSecondary)),
            AppSpacing.gapMd,
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.textTertiary),
            AppSpacing.gapMd,
            Text('No audit events in this filter',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        itemCount: _events.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _total != null ? '$_total events total' : '',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            );
          }
          return _AuditEventCard(event: _events[index - 1]);
        },
      ),
    );
  }
}

class _AuditEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _AuditEventCard({required this.event});

  (IconData, Color) get _style {
    final type = (event['eventType'] ?? '') as String;
    switch (type) {
      case 'DRIVER_DOCUMENT_UPLOADED':
        return (Icons.upload_file, AppColors.primary);
      case 'DRIVER_DOCUMENT_APPROVED':
        return (Icons.verified_outlined, AppColors.success);
      case 'DRIVER_DOCUMENT_REJECTED':
        return (Icons.cancel_outlined, AppColors.error);
      case 'DRIVER_DOCUMENT_REUPLOAD_REQUESTED':
        return (Icons.autorenew, AppColors.warning);
      case 'DRIVER_DOCUMENT_EXPIRED':
        return (Icons.event_busy, AppColors.error);
      case 'DRIVER_FORCED_OFFLINE':
        return (Icons.block, AppColors.error);
      case 'DOCUMENT_REVIEW_NOTIFIED':
      case 'DOCUMENT_EXPIRY_NOTIFIED':
        return (Icons.notifications_outlined, AppColors.info);
      case 'DRIVER_APPROVED':
        return (Icons.check_circle_outline, AppColors.success);
      case 'DRIVER_REJECTED':
        return (Icons.do_not_disturb_alt, AppColors.error);
      case 'ADMIN_TOGGLE_VERIFY':
        return (Icons.verified, AppColors.brandSecondary);
      case 'ADMIN_TOGGLE_BLOCK':
        return (Icons.block, AppColors.warning);
      default:
        return (Icons.history, AppColors.textSecondary);
    }
  }

  String _eventLabel(String type) {
    switch (type) {
      case 'DRIVER_DOCUMENT_UPLOADED':
        return 'Document uploaded';
      case 'DRIVER_DOCUMENT_APPROVED':
        return 'Document approved';
      case 'DRIVER_DOCUMENT_REJECTED':
        return 'Document rejected';
      case 'DRIVER_DOCUMENT_REUPLOAD_REQUESTED':
        return 'Re-upload requested';
      case 'DRIVER_DOCUMENT_EXPIRED':
        return 'Document expired';
      case 'DRIVER_FORCED_OFFLINE':
        return 'Forced offline';
      case 'DOCUMENT_REVIEW_NOTIFIED':
        return 'Review notification sent';
      case 'DOCUMENT_EXPIRY_NOTIFIED':
        return 'Expiry notification sent';
      case 'DRIVER_APPROVED':
        return 'Driver approved';
      case 'DRIVER_REJECTED':
        return 'Driver rejected';
      case 'ADMIN_TOGGLE_VERIFY':
        return 'Verification toggled';
      case 'ADMIN_TOGGLE_BLOCK':
        return 'Block status toggled';
      case 'ADMIN_VIEWED_DRIVER':
        return 'Admin viewed profile';
      default:
        return type.replaceAll('_', ' ').toLowerCase();
    }
  }

  String _timestamp(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    final type = (event['eventType'] ?? '') as String;
    final summary = (event['summary'] ?? '') as String;
    final label = summary.isNotEmpty ? summary : _eventLabel(type);
    final details = event['details'] as Map<String, dynamic>? ?? const {};
    final actor = (event['actor'] ?? '') as String;
    final timestamp = (event['timestamp'] ?? '') as String;

    final docType = (details['documentType'] ?? '') as String;
    final adminNote = (details['adminNote'] ?? '') as String;
    final status = (details['status'] ?? '') as String;
    final notificationType = (details['notificationType'] ?? '') as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        hasRipple: false,
        shadows: const <BoxShadow>[],
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _timestamp(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (summary.isEmpty) ...[
                      if (docType.isNotEmpty) ...[
                        AppSpacing.gapXs,
                        Text(
                          _docTypeLabel(docType),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (status.isNotEmpty) ...[
                        AppSpacing.gapXs,
                        Text(
                          'Status: $status',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (notificationType.isNotEmpty) ...[
                        AppSpacing.gapXs,
                        Text(
                          'Notification: $notificationType',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                    if (adminNote.isNotEmpty) ...[
                      AppSpacing.gapXs,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Note: $adminNote',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    if (actor.isNotEmpty && actor != 'SYSTEM') ...[
                      AppSpacing.gapXs,
                      Text(
                        'By $actor',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _docTypeLabel(String t) {
    return t.replaceAll('_', ' ').toLowerCase();
  }
}
