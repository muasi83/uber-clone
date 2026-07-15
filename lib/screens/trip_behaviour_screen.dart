import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trip_events.dart';
import '../services/trip_behaviour_service.dart';
import '../services/storage_service.dart';
import '../services/ui_event_recorder.dart';
import '../theme/app_colors.dart';

class TripBehaviourScreen extends StatefulWidget {
  final int rideId;
  const TripBehaviourScreen({super.key, required this.rideId});

  @override
  State<TripBehaviourScreen> createState() => _TripBehaviourScreenState();
}

class _TripBehaviourScreenState extends State<TripBehaviourScreen> {
  String? _token;
  bool _loading = true;
  String? _error;
  TripBehaviourResponse? _data;
  String _selectedFilter = '';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showExportMenu = false;

  static const _filters = [
    '', 'WARNINGS', 'ERRORS', 'BUSINESS', 'NETWORK', 'FRONTEND',
    'BACKEND', 'WEBSOCKET', 'DATABASE', 'GPS', 'PAYMENTS',
    'NOTIFICATIONS', 'RECOVERY', 'SCHEDULER', 'UI',
  ];

  @override
  void initState() {
    super.initState();
    _token = StorageService.getToken();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) return;
    setState(() => _loading = true);
    try {
      final result = await TripBehaviourService.getBehaviour(
        rideId: widget.rideId,
        token: _token!,
        filter: _selectedFilter,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
        _error = result == null ? 'Failed to load trip behaviour' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildToolbar(),
          if (_showFilters) _buildFilterChips(),
          if (_showExportMenu) _buildExportToolbar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search events...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (v) {
                _searchQuery = v;
                _loadData();
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, size: 20,
                color: _selectedFilter.isNotEmpty ? AppColors.primary : AppColors.textSecondary),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Filter',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: Icon(Icons.ios_share, size: 20, color: AppColors.textSecondary),
            onPressed: () => setState(() => _showExportMenu = !_showExportMenu),
            tooltip: 'Share / Export',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: _filters.map((f) {
          final active = _selectedFilter == f;
          return FilterChip(
            label: Text(
              f.isEmpty ? 'All' : EventCategory.displayName(f),
              style: TextStyle(fontSize: 11, color: active ? Colors.white : AppColors.textSecondary),
            ),
            selected: active,
            onSelected: (v) {
              setState(() => _selectedFilter = f);
              _loadData();
            },
            visualDensity: VisualDensity.compact,
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          _exportButton(Icons.content_copy, 'Copy\nSummary', _copySummary),
          const SizedBox(width: 8),
          _exportButton(Icons.copy_all, 'Copy\nTimeline', _copyTimeline),
          const SizedBox(width: 8),
          _exportButton(Icons.auto_awesome, 'Copy for\nAI Analysis', _copyAiReport),
          const SizedBox(width: 8),
          _exportButton(Icons.description, 'Export\nJSON', _exportJson),
          const SizedBox(width: 8),
          _exportButton(Icons.text_snippet, 'Export\nMarkdown', _exportMarkdown),
          const SizedBox(width: 8),
          _exportButton(Icons.share, 'Share', _shareData),
        ],
      ),
    );
  }

  Widget _exportButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          Text(label, style: TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null) return const SizedBox();

    final summary = _data!.summary;
    final events = _data!.events;
    final anomalies = _data!.anomalies;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          if (summary != null) _buildSummaryCard(summary),
          if (anomalies.isNotEmpty) _buildAnomalyList(anomalies),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('No events recorded for this filter.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else
            ...events.asMap().entries.map((entry) => _buildEventCard(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TripSummary summary) {
    final score = summary.healthScore ?? 100;
    final scoreColor = score >= 80 ? AppColors.success : (score >= 50 ? AppColors.warning : AppColors.error);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Trip Health', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$score%', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _healthRow(Icons.timer, 'Duration', summary.duration ?? 'N/A'),
            _healthRow(Icons.warning, 'Warnings', '${summary.warningCount ?? 0}'),
            _healthRow(Icons.error, 'Errors', '${summary.errorCount ?? 0}'),
            _healthRow(Icons.wifi, 'Network Issues', '${summary.networkInterruptions ?? 0}'),
            _healthRow(Icons.sensors, 'GPS Interruptions', '${summary.gpsInterruptions ?? 0}'),
            _healthRow(Icons.link, 'WS Reconnects', '${summary.wsReconnects ?? 0}'),
            _healthRow(Icons.payment, 'Payment Retries', '${summary.paymentRetries ?? 0}'),
            if (summary.longestStage != null)
              _healthRow(Icons.timer_outlined, 'Longest Stage', '${summary.longestStage}'),
            if (summary.possibleIssues != null && summary.possibleIssues!.isNotEmpty) ...[
              const Divider(height: 12),
              const Text('Possible Issues:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.warning)),
              ...summary.possibleIssues!.map((issue) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  ⚠️ ', style: TextStyle(fontSize: 11)),
                    Expanded(child: Text(issue, style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _healthRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildAnomalyList(List<TripAnomaly> anomalies) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('Anomalies (${anomalies.length})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 4),
            ...anomalies.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.severity == 'ERROR' ? '❌ ' : '⚠️ ', style: TextStyle(fontSize: 12)),
                  Expanded(child: Text(a.message ?? '', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(int index, TripBehaviourEvent event) {
    final time = event.timestamp?.toString().substring(11, 19) ?? '??:??:??';
    final isError = event.severity == 'ERROR';
    final isWarning = event.severity == 'WARNING';
    final bgColor = isError ? AppColors.error.withValues(alpha: 0.05)
        : isWarning ? AppColors.warning.withValues(alpha: 0.05)
        : AppColors.surface;

    return Card(
      margin: const EdgeInsets.only(bottom: 3),
      color: bgColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        leading: Text(
          event.severityIcon.isNotEmpty ? event.severityIcon : '•',
          style: const TextStyle(fontSize: 14),
        ),
        title: Row(
          children: [
            Text('$time ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            Expanded(
              child: Text(event.eventName ?? '',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: isError ? AppColors.error : AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        subtitle: Text(
          event.summary ?? event.categoryDisplay,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          _detailRow('Category', event.categoryDisplay),
          _detailRow('Actor', event.actorName ?? event.actor ?? 'SYSTEM'),
          _detailRow('Severity', event.severity ?? 'INFO'),
          _detailRow('Ride Status', event.rideStatus ?? 'N/A'),
          if (event.correlationId != null)
            _detailRow('Correlation ID', event.correlationId!),
          if (event.actorId != null)
            _detailRow('Actor ID', '${event.actorId}'),
          if (event.currentScreen != null)
            _detailRow('Screen', event.currentScreen!),
          if (event.restEndpoint != null)
            _detailRow('REST', '${event.restMethod ?? ""} ${event.restEndpoint} (${event.restStatus ?? ""})'),
          if (event.wsEventName != null)
            _detailRow('WebSocket', '${event.wsEventName} [${event.wsDirection ?? ""}]'),
          if (event.backendController != null)
            _detailRow('Controller', event.backendController!),
          if (event.backendService != null)
            _detailRow('Service', event.backendService!),
          if (event.dbTable != null)
            _detailRow('DB', '${event.dbTable} (${event.dbOperation ?? ""})'),
          if (event.paymentState != null)
            _detailRow('Payment', event.paymentState!),
          if (event.notificationType != null)
            _detailRow('Notification', '${event.notificationType} [${event.notificationStatus ?? ""}]'),
          if (event.internetQuality != null)
            _detailRow('Internet', event.internetQuality!),
          if (event.result != null)
            _detailRow('Result', event.result!),
          if (event.details != null && event.details!.isNotEmpty) ...[
            const Divider(height: 8),
            Text('Details:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Text(event.details.toString(), style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _copySummary() {
    if (_data == null) return;
    final text = TripBehaviourService.generateSummaryText(_data!.summary, _data!.events);
    Clipboard.setData(ClipboardData(text: text));
    UiEventRecorder.showSnackBar(context: context, message: 'Summary copied to clipboard');
  }

  void _copyTimeline() {
    if (_data == null) return;
    final text = TripBehaviourService.generateFullTimeline(_data!.events);
    Clipboard.setData(ClipboardData(text: text));
    UiEventRecorder.showSnackBar(context: context, message: 'Timeline copied to clipboard');
  }

  void _copyAiReport() {
    if (_data == null) return;
    final text = TripBehaviourService.generateAiReport(_data!.summary, _data!.events);
    Clipboard.setData(ClipboardData(text: text));
    UiEventRecorder.showSnackBar(context: context, message: 'AI report copied to clipboard');
  }

  void _exportJson() {
    if (_data == null) return;
    final text = TripBehaviourService.generateJsonExport(_data!.summary, _data!.events);
    Clipboard.setData(ClipboardData(text: text));
    UiEventRecorder.showSnackBar(context: context, message: 'JSON copied to clipboard');
  }

  void _exportMarkdown() {
    if (_data == null) return;
    final text = TripBehaviourService.generateMarkdown(_data!.summary, _data!.events);
    Clipboard.setData(ClipboardData(text: text));
    UiEventRecorder.showSnackBar(context: context, message: 'Markdown copied to clipboard');
  }

  void _shareData() {
    _copySummary(); // Copy summary then user can share from clipboard
    UiEventRecorder.showSnackBar(context: context, message: 'Summary copied. Paste into any app to share.');
  }
}
