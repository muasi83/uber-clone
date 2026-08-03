import 'package:flutter/material.dart';
import '../services/notifications_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_card.dart';
import 'driver_documents_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({super.key, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  bool _error = false;

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
    final list = await NotificationsApi.getNotifications(widget.token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (list == null) {
        _error = true;
        _notifications = [];
      } else {
        _notifications = list;
      }
    });
  }

  int get _unreadCount => _notifications.where((n) => (n['isRead'] ?? 0) == 0).length;

  bool _isDocumentType(Map<String, dynamic> n) {
    final type = (n['type'] ?? '') as String;
    return type.startsWith('DOCUMENT_') || type == 'DRIVER_FORCED_OFFLINE';
  }

  Future<void> _onTap(Map<String, dynamic> n) async {
    final id = n['id'];
    final unread = (n['isRead'] ?? 0) == 0;
    if (unread && id is int) {
      await NotificationsApi.markRead(widget.token, id);
      if (mounted) {
        setState(() => n['isRead'] = 1);
      }
    }
    if (!mounted) return;
    if (_isDocumentType(n)) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DriverDocumentsScreen(token: widget.token)),
      );
    }
  }

  Future<void> _markAllRead() async {
    final ok = await NotificationsApi.markAllRead(widget.token);
    if (!mounted) return;
    if (ok) {
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiary),
            AppSpacing.gapMd,
            const Text('Could not load notifications',
                style: TextStyle(color: AppColors.textSecondary)),
            AppSpacing.gapMd,
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.textTertiary),
            AppSpacing.gapMd,
            Text('No notifications yet',
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
        itemCount: _notifications.length,
        itemBuilder: (context, index) => _NotificationCard(
          notification: _notifications[index],
          onTap: () => _onTap(_notifications[index]),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  (IconData, Color) get _style {
    final type = (notification['type'] ?? '') as String;
    switch (type) {
      case 'DOCUMENT_APPROVED':
      case 'PAYMENT':
      case 'REFUND':
        return (Icons.check_circle_outline, AppColors.success);
      case 'DOCUMENT_REJECTED':
        return (Icons.cancel_outlined, AppColors.error);
      case 'DOCUMENT_REUPLOAD_REQUESTED':
      case 'DOCUMENT_EXPIRING_7':
        return (Icons.refresh, AppColors.warning);
      case 'DOCUMENT_EXPIRING_30':
        return (Icons.hourglass_empty, AppColors.warning);
      case 'DOCUMENT_EXPIRED':
        return (Icons.error_outline, AppColors.error);
      case 'DRIVER_FORCED_OFFLINE':
        return (Icons.block, AppColors.error);
      case 'chat_message':
        return (Icons.chat_bubble_outline, AppColors.primary);
      default:
        return (Icons.notifications_outlined, AppColors.primary);
    }
  }

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = (notification['isRead'] ?? 0) == 0;
    final (icon, color) = _style;
    final title = (notification['title'] ?? '') as String;
    final body = (notification['body'] ?? '') as String;
    final createdAt = (notification['createdAt'] ?? '') as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: '$title, $body',
        child: PremiumCard(
          hasRipple: true,
          onTap: onTap,
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
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _relativeTime(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  AppSpacing.hGapSm,
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
