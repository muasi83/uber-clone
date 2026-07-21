import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/admin_service.dart';
import '../services/currency_service.dart';
import '../services/ui_event_recorder.dart';
import '../widgets/status_badge.dart';
import '../widgets/shimmer_loading.dart';
import '../theme/app_colors.dart';
import '../utils/address_utils.dart';
import 'trip_behaviour_screen.dart';
import 'trip_replay_screen.dart';

class AdminTripDetailsScreen extends StatefulWidget {
  final int rideId;
  const AdminTripDetailsScreen({super.key, required this.rideId});

  @override
  State<AdminTripDetailsScreen> createState() => _AdminTripDetailsScreenState();
}

class _AdminTripDetailsScreenState extends State<AdminTripDetailsScreen> with TickerProviderStateMixin {
  String? _token;
  bool _loading = true;
  bool _loadingEvents = true;
  bool _loadingMessages = true;
  String? _error;
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _messages = [];
  bool _showChat = false;
  final _noteController = TextEditingController();
  bool _savingNote = false;
  bool _togglingKeep = false;
  bool _eventLoadError = false;
  bool _messageLoadError = false;
  late TabController _tabController;
  int _syncStage = 0;
  final _replayKey = GlobalKey<TripReplayScreenState>();

  static const _groupOrder = [
    'Ride Request',
    'Searching',
    'Driver Assignment',
    'Pickup',
    'Ride',
    'Payment',
    'Completion',
    'System',
    'Admin Notes',
  ];

  static const _eventGroupMap = {
    'RIDE_REQUESTED': 'Ride Request',
    'RIDE_ACCEPTED': 'Driver Assignment',
    'DRIVER_ARRIVED': 'Pickup',
    'RIDE_STARTED': 'Ride',
    'RIDE_COMPLETED': 'Completion',
    'RIDE_CANCELLED': 'Completion',
    'PAYMENT_CONFIRMED': 'Payment',
    'PAYMENT_RECEIVED': 'Payment',
    'PAYMENT_DISPUTED': 'Payment',
    'ADMIN_VIEWED_RIDE': 'Admin Notes',
    'ADMIN_KEEP_FOREVER': 'Admin Notes',
    'ADMIN_NOTE': 'Admin Notes',
    'LOGIN': 'System',
    'LOGOUT': 'System',
    'APP_OPENED': 'System',
    'WEBSOCKET_CONNECTED': 'System',
    'WEBSOCKET_DISCONNECTED': 'System',
    'FCM_SENT': 'System',
    'SERVER_EXCEPTION': 'System',
    'HTTP_RETRY': 'System',
    'HTTP_TIMEOUT': 'System',
    'HTTP_ERROR': 'System',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 2) {
          UiEventRecorder.setCurrentRideId(widget.rideId);
          UiEventRecorder.setCurrentScreen('AdminTripDetails-Replay');
        } else if (_tabController.index == 1) {
          UiEventRecorder.setCurrentRideId(widget.rideId);
          UiEventRecorder.setCurrentScreen('AdminTripDetails-Behaviour');
        } else {
          UiEventRecorder.setCurrentRideId(widget.rideId);
          UiEventRecorder.setCurrentScreen('AdminTripDetails-Overview');
        }
      }
    });
    _token = StorageService.getToken();
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onReplayStageSelected(int stageNumber) {
    setState(() => _syncStage = stageNumber);
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadDetail(), _loadEvents(), _loadMessages()]);
  }

  Future<void> _loadDetail() async {
    if (_token == null) return;
    setState(() => _loading = true);
    try {
      final detail = await AdminService.getTripDetail(widget.rideId, _token!);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _error = detail == null ? 'Trip not found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading trip: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    if (_token == null) return;
    setState(() => _loadingEvents = true);
    try {
      final result = await AdminService.getTripEvents(
        widget.rideId, _token!, page: 0, size: 100);
      if (!mounted) return;
      setState(() {
        _events = ((result?['events'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
        _loadingEvents = false;
        _eventLoadError = result == null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEvents = false;
        _eventLoadError = true;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_token == null) return;
    setState(() => _loadingMessages = true);
    try {
      final result = await AdminService.getTripMessages(
        widget.rideId, _token!, page: 0, size: 100);
      if (!mounted) return;
      setState(() {
        _messages = ((result?['messages'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
        _loadingMessages = false;
        _messageLoadError = result == null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMessages = false;
        _messageLoadError = true;
      });
    }
  }

  static String _eventGroup(String type) {
    return _eventGroupMap[type] ?? 'Other';
  }

  Color _groupColor(String group) {
    switch (group) {
      case 'Ride Request': return AppColors.info;
      case 'Searching': return AppColors.warning;
      case 'Driver Assignment': return AppColors.primary;
      case 'Pickup': return AppColors.accent;
      case 'Ride': return AppColors.primary;
      case 'Payment': return AppColors.success;
      case 'Completion': return AppColors.success;
      case 'System': return AppColors.textTertiary;
      case 'Admin Notes': return AppColors.accent;
      default: return AppColors.textSecondary;
    }
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Ride Request': return Icons.taxi_alert;
      case 'Searching': return Icons.search;
      case 'Driver Assignment': return Icons.person_pin;
      case 'Pickup': return Icons.location_on;
      case 'Ride': return Icons.directions_car;
      case 'Payment': return Icons.payment;
      case 'Completion': return Icons.check_circle;
      case 'System': return Icons.settings;
      case 'Admin Notes': return Icons.note;
      default: return Icons.circle;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'RIDE_REQUESTED': return Icons.taxi_alert;
      case 'RIDE_ACCEPTED': return Icons.check;
      case 'DRIVER_ARRIVED': return Icons.location_on;
      case 'RIDE_STARTED': return Icons.play_arrow;
      case 'RIDE_COMPLETED': return Icons.flag;
      case 'RIDE_CANCELLED': return Icons.cancel;
      case 'PAYMENT_CONFIRMED': return Icons.credit_card;
      case 'PAYMENT_RECEIVED': return Icons.account_balance_wallet;
      case 'PAYMENT_DISPUTED': return Icons.gavel;
      case 'ADMIN_NOTE': return Icons.note_add;
      case 'ADMIN_KEEP_FOREVER': return Icons.lock;
      case 'ADMIN_VIEWED_RIDE': return Icons.visibility;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip #${widget.rideId}'),
        actions: [
          if (_detail != null)
            IconButton(
              icon: _togglingKeep
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_detail!['keepForever'] == true
                      ? Icons.lock
                      : Icons.lock_open),
              tooltip: _detail!['keepForever'] == true
                  ? 'Disable retention'
                  : 'Enable retention',
              onPressed: _togglingKeep ? null : _toggleKeepForever,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Trip Behaviour'),
                  Tab(text: 'Trip Replay'),
                ],
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
              ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(itemCount: 6, itemHeight: 60))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContent(),
                    TripBehaviourScreen(rideId: widget.rideId),
                    TripReplayScreen(
                      key: _replayKey,
                      rideId: widget.rideId,
                      onStageSelected: _onReplayStageSelected,
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final status = detail['status'] as String?;
    final rider = detail['rider'] as Map<String, dynamic>?;
    final driver = detail['driver'] as Map<String, dynamic>?;
    final payment = detail['payment'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeader(detail, status),
          const SizedBox(height: 12),
          if (rider != null) _buildSection('Rider', _buildRiderCard(rider)),
          if (driver != null) _buildSection('Driver', _buildDriverCard(driver)),
          if (payment != null) _buildSection('Payment', _buildPaymentCard(payment)),
          const SizedBox(height: 8),
          _buildInfoCard(detail),
          const SizedBox(height: 12),
          _buildSection('Timeline', _buildTimeline()),
          const SizedBox(height: 12),
          _buildSection('Chat', _buildChatSection()),
          const SizedBox(height: 12),
          _buildAdminNotesSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> detail, String? status) {
    final reqAt = detail['requestedAt'] as String?;
    final compAt = detail['completedAt'] as String?;
    final canAt = detail['cancelledAt'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Trip #${widget.rideId}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                StatusBadge(
                  label: status ?? 'UNKNOWN',
                  color: _statusColor(status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (reqAt != null)
              _infoRow(Icons.access_time, 'Requested',
                  _formatDate(reqAt)),
            if (compAt != null)
              _infoRow(Icons.flag, 'Completed', _formatDate(compAt)),
            if (canAt != null)
              _infoRow(Icons.cancel, 'Cancelled', _formatDate(canAt)),
            if (detail['cancellationReason'] != null)
              _infoRow(Icons.info_outline, 'Reason',
                  detail['cancellationReason'] as String),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                (rider['name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rider['name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(rider['email'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (rider['username'] != null)
                    Text('@${rider['username']}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              child: Text(
                (driver['name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver['name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(driver['email'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (driver['vehicleModel'] != null)
                    Text(
                        '${driver['vehicleColor'] ?? ''} ${driver['vehicleModel'] ?? ''} (${driver['vehicleNumber'] ?? ''})'
                            .trim(),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  if (driver['country'] != null)
                    Text('${driver['country'] ?? ''}, ${driver['city'] ?? ''}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            if (driver['averageRating'] != null)
              Column(
                children: [
                  Icon(Icons.star, color: AppColors.warning, size: 20),
                  Text('${(driver['averageRating'] as num?)?.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] as String?;
    final amount = payment['amount'] as num?;
    final method = payment['paymentMethod'] as String?;
    final completedAt = payment['completedAt'] as String?;

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
        statusColor = AppColors.success;
        break;
      case 'FAILED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(CurrencyService.format(amount ?? 0),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status ?? '',
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (method != null)
              _infoRow(Icons.payment, 'Method', method),
            if (completedAt != null)
              _infoRow(Icons.check_circle, 'Completed', _formatDate(completedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> detail) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ride Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _infoRow(Icons.route, 'Type', detail['rideType'] as String? ?? ''),
            _infoRow(Icons.location_on, 'Pickup',
                detail['pickupAddress'] as String? ?? ''),
            _infoRow(Icons.map, 'Pickup Coord',
                formatLatLng((detail['pickupLatitude'] as num?)?.toDouble() ?? 0,
                    (detail['pickupLongitude'] as num?)?.toDouble() ?? 0)),
            _infoRow(Icons.flag, 'Dropoff',
                detail['dropoffAddress'] as String? ?? ''),
            _infoRow(Icons.map, 'Dropoff Coord',
                formatLatLng((detail['dropoffLatitude'] as num?)?.toDouble() ?? 0,
                    (detail['dropoffLongitude'] as num?)?.toDouble() ?? 0)),
            if (detail['estimatedDistance'] != null)
              _infoRow(Icons.straighten, 'Distance',
                  '${(detail['estimatedDistance'] as num).toStringAsFixed(2)} km'),
            if (detail['estimatedDuration'] != null)
              _infoRow(Icons.timer, 'Duration',
                  '${detail['estimatedDuration']} min'),
            if (detail['estimatedFare'] != null)
              _infoRow(Icons.attach_money, 'Est. Fare',
                  CurrencyService.format((detail['estimatedFare'] as num).toDouble())),
            if (detail['finalFare'] != null)
              _infoRow(Icons.receipt, 'Final Fare',
                  CurrencyService.format((detail['finalFare'] as num).toDouble())),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_loadingEvents) {
      return const ShimmerList(itemCount: 4, itemHeight: 50);
    }
    if (_eventLoadError) {
      return Center(
        child: TextButton(
          onPressed: _loadEvents,
          child: const Text('Failed to load events. Tap to retry.'),
        ),
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final g in _groupOrder) {
      grouped[g] = [];
    }
    for (final event in _events) {
      final type = event['eventType'] as String? ?? '';
      final group = _eventGroup(type);
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(event);
    }

    final sections = <Widget>[];
    for (final group in _groupOrder) {
      final events = grouped[group] ?? [];
      if (events.isEmpty) continue;

      sections.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            Icon(_groupIcon(group), size: 16, color: _groupColor(group)),
            const SizedBox(width: 6),
            Text(group,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _groupColor(group))),
            Text(' (${events.length})',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ));

      for (final event in events) {
        sections.add(_buildEventItem(event));
      }
    }

    if (sections.isEmpty) {
      return const Text('No timeline events',
          style: TextStyle(color: AppColors.textSecondary));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final type = event['eventType'] as String? ?? '';
    final actor = event['actor'] as String?;
    final actorName = event['actorName'] as String?;
    final timestamp = event['timestamp'] as String?;
    final details = event['details'] as Map<String, dynamic>?;
    final correlationId = event['correlationId'] as String?;

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(_eventIcon(type), size: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(type,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    if (timestamp != null)
                      Text(_formatDateTime(timestamp),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
                if (actorName != null || actor != null)
                  Text('${actor ?? ''} ${actorName ?? ''}'.trim(),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                if (details != null && details.isNotEmpty)
                  Text(details.toString(),
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textTertiary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                if (correlationId != null && correlationId.isNotEmpty)
                  Text('ID: $correlationId',
                      style: TextStyle(
                          fontSize: 9, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    if (_loadingMessages) {
      return const ShimmerList(itemCount: 3, itemHeight: 40);
    }

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showChat = !_showChat),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Chat Messages (${_messages.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Icon(_showChat ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (_showChat)
          _messageLoadError
              ? Center(
                  child: TextButton(
                    onPressed: _loadMessages,
                    child: const Text('Failed to load. Retry.'),
                  ),
                )
              : _messages.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No messages',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppColors.outline),
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        msg['senderName'] as String? ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text(
                                        _formatDateTime(
                                            msg['sentAt'] as String?),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(msg['content'] as String? ?? '',
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      ],
    );
  }

  Widget _buildAdminNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Add an investigation note...',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _savingNote ? null : _addNote,
                child: _savingNote
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _toggleKeepForever() async {
    if (_token == null || _detail == null) return;
    setState(() => _togglingKeep = true);
    final current = _detail!['keepForever'] == true;
    final ok = await AdminService.setKeepForever(
        widget.rideId, !current, _token!);
    if (ok) {
      _detail!['keepForever'] = !current;
      // Reload events to reflect the change
      await _loadEvents();
    }
    if (mounted) {
      setState(() => _togglingKeep = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Retention ${current ? "disabled" : "enabled"} for this ride'
              : 'Failed to update retention'),
        ),
      );
    }
  }

  Future<void> _addNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _token == null) return;
    setState(() => _savingNote = true);
    final ok = await AdminService.addNote(widget.rideId, note, _token!);
    if (ok) {
      _noteController.clear();
      await _loadEvents();
    }
    if (mounted) {
      setState(() => _savingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Note added' : 'Failed to add note'),
        ),
      );
    }
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('HH:mm:ss').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
