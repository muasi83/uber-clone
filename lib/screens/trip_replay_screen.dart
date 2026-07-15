import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trip_events.dart';
import '../services/trip_behaviour_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class TripReplayScreen extends StatefulWidget {
  final int rideId;
  final void Function(int stageNumber)? onStageSelected;

  const TripReplayScreen({super.key, required this.rideId, this.onStageSelected});

  @override
  State<TripReplayScreen> createState() => TripReplayScreenState();
}

class TripReplayScreenState extends State<TripReplayScreen> {
  String? _token;
  bool _loading = true;
  String? _error;
  TripReplayResponse? _data;

  int _currentStage = 0;
  bool _playing = false;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;
  bool _showExportMenu = false;

  static const _speeds = [1.0, 2.0, 5.0, 10.0];

  List<TripReplaySnapshot> get _snapshots => _data?.snapshots ?? [];
  TripReplaySnapshot? get _current => _snapshots.isNotEmpty && _currentStage < _snapshots.length
      ? _snapshots[_currentStage] : null;

  @override
  void initState() {
    super.initState();
    _token = StorageService.getToken();
    _loadData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) return;
    setState(() => _loading = true);
    try {
      final result = await TripBehaviourService.getReplay(
        rideId: widget.rideId,
        token: _token!,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
        _error = result == null ? 'Failed to load replay data' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _togglePlay() {
    if (_playing) {
      _playbackTimer?.cancel();
      setState(() => _playing = false);
    } else {
      if (_currentStage >= _snapshots.length - 1) {
        setState(() => _currentStage = 0);
      }
      setState(() => _playing = true);
      _startPlayback();
    }
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (1000 / _playbackSpeed).round()),
      (_) {
        if (!mounted) return;
        if (_currentStage < _snapshots.length - 1) {
          setState(() => _currentStage++);
          widget.onStageSelected?.call(_currentStage);
        } else {
          _playbackTimer?.cancel();
          setState(() => _playing = false);
        }
      },
    );
  }

  void _goToStage(int stage) {
    _playbackTimer?.cancel();
    setState(() {
      _playing = false;
      _currentStage = stage.clamp(0, _snapshots.length - 1);
    });
    widget.onStageSelected?.call(_currentStage);
  }

  void _previousStage() {
    if (_currentStage > 0) {
      _playbackTimer?.cancel();
      setState(() {
        _playing = false;
        _currentStage--;
      });
      widget.onStageSelected?.call(_currentStage);
    }
  }

  void _nextStage() {
    if (_currentStage < _snapshots.length - 1) {
      _playbackTimer?.cancel();
      setState(() {
        _playing = false;
        _currentStage++;
      });
      widget.onStageSelected?.call(_currentStage);
    }
  }

  void _restart() {
    _playbackTimer?.cancel();
    setState(() {
      _playing = false;
      _currentStage = 0;
    });
    widget.onStageSelected?.call(0);
  }

  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_playing) {
      _playbackTimer?.cancel();
      _startPlayback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
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
    if (_snapshots.isEmpty) {
      return Center(
        child: Text('No replay data available for this trip.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    final current = _current;

    return Column(
      children: [
        _buildExportToolbar(),
        if (_showExportMenu) _buildExportOptions(),
        _buildCurrentStageCard(current),
        const SizedBox(height: 4),
        _buildPlaybackControls(),
        const SizedBox(height: 4),
        _buildStageTimeline(),
        const SizedBox(height: 4),
        Expanded(child: _buildReplayDetails(current)),
      ],
    );
  }

  Widget _buildExportToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Text('Trip Replay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          const Spacer(),
          Text('${_currentStage + 1}/${_snapshots.length}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          IconButton(
            icon: Icon(Icons.ios_share, size: 18, color: AppColors.textSecondary),
            onPressed: () => setState(() => _showExportMenu = !_showExportMenu),
            tooltip: 'Share / Export',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loadData,
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          _expBtn(Icons.content_copy, 'Copy\nSummary', _copyReplaySummary),
          const SizedBox(width: 8),
          _expBtn(Icons.copy_all, 'Copy\nTimeline', _copyReplayTimeline),
          const SizedBox(width: 8),
          _expBtn(Icons.auto_awesome, 'Copy\nCurrent Stage', _copyCurrentStage),
          const SizedBox(width: 8),
          _expBtn(Icons.share, 'Share', _shareReplay),
        ],
      ),
    );
  }

  Widget _expBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          Text(label, style: TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCurrentStageCard(TripReplaySnapshot? current) {
    if (current == null) return const SizedBox();

    final stage = current.stageName ?? 'Unknown';
    final time = current.timestamp?.toString().substring(11, 19) ?? '??:??:??';
    final isError = current.severity == 'ERROR';
    final isWarning = current.severity == 'WARNING';
    final bgColor = isError ? AppColors.error.withValues(alpha: 0.1)
        : isWarning ? AppColors.warning.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.05);

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isError ? AppColors.error : (isWarning ? AppColors.warning : AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Stage ${current.stageNumber ?? 0}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(stage,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _infoChip(Icons.access_time, time),
                const SizedBox(width: 8),
                if (current.rideStatus != null)
                  _infoChip(Icons.info, current.rideStatus!),
                if (current.durationMs != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('+${current.durationMs! ~/ 1000}s',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous, size: 24), onPressed: _restart, tooltip: 'Restart'),
              IconButton(icon: const Icon(Icons.skip_previous, size: 20), onPressed: _previousStage, tooltip: 'Previous'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 28, color: Colors.white),
                  onPressed: _togglePlay,
                ),
              ),
              IconButton(icon: const Icon(Icons.skip_next, size: 20), onPressed: _nextStage, tooltip: 'Next'),
              IconButton(icon: const Icon(Icons.skip_next, size: 24), onPressed: () => _goToStage(_snapshots.length - 1), tooltip: 'Last'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _speeds.map((s) {
              final active = _playbackSpeed == s;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${s}x', style: TextStyle(fontSize: 11, color: active ? Colors.white : AppColors.textSecondary)),
                  selected: active,
                  onSelected: (_) => _setSpeed(s),
                  visualDensity: VisualDensity.compact,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStageTimeline() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _snapshots.length,
        itemBuilder: (context, i) {
          final snap = _snapshots[i];
          final isCurrent = i == _currentStage;
          final isError = snap.severity == 'ERROR';
          final isWarning = snap.severity == 'WARNING';

          return GestureDetector(
            onTap: () => _goToStage(i),
            child: Container(
              width: 28,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCurrent
                    ? (isError ? AppColors.error : (isWarning ? AppColors.warning : AppColors.primary))
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? Colors.transparent : AppColors.outline,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : AppColors.textSecondary,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplayDetails(TripReplaySnapshot? current) {
    if (current == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      children: [
        Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                _detRow('Passenger', current.passengerLat != null && current.passengerLng != null
                    ? '${current.passengerLat!.toStringAsFixed(6)}, ${current.passengerLng!.toStringAsFixed(6)}'
                    : 'N/A'),
                _detRow('Driver', current.driverLat != null && current.driverLng != null
                    ? '${current.driverLat!.toStringAsFixed(6)}, ${current.driverLng!.toStringAsFixed(6)}'
                    : 'N/A'),
                if (current.gpsInfo != null) _detRow('GPS Info', current.gpsInfo!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                if (current.wsEventName != null) _detRow('WebSocket', current.wsEventName!),
                if (current.restRequest != null) _detRow('REST', current.restRequest!),
                if (current.backendActivity != null) _detRow('Backend', current.backendActivity!),
                if (current.paymentState != null) _detRow('Payment', current.paymentState!),
                if (current.notificationInfo != null) _detRow('Notification', current.notificationInfo!),
                if (current.errorInfo != null) _detRow('Error', current.errorInfo!),
                if (current.warningInfo != null) _detRow('Warning', current.warningInfo!),
                if (current.recoveryInfo != null) _detRow('Recovery', current.recoveryInfo!),
                if (current.networkInfo != null) _detRow('Network', current.networkInfo!),
                if (_data != null) _detRow('Trip Type', '${_data!.rideType ?? ""}'),
                if (_data != null) _detRow('Pickup', _data!.pickupAddress ?? ''),
                if (_data != null) _detRow('Dropoff', _data!.dropoffAddress ?? ''),
              ],
            ),
          ),
        ),
        if (current.summary != null) ...[
          const SizedBox(height: 4),
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(current.summary!, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  void _copyReplaySummary() {
    if (_data == null) return;
    final buf = StringBuffer();
    buf.writeln('Trip Replay Summary');
    buf.writeln('=' * 40);
    buf.writeln('Ride ID: ${_data!.rideId}');
    buf.writeln('Status: ${_data!.rideStatus ?? "N/A"}');
    buf.writeln('Type: ${_data!.rideType ?? "N/A"}');
    buf.writeln('Duration: ${_data!.estimatedDuration ?? "N/A"}');
    buf.writeln('Distance: ${_data!.estimatedDistance ?? "N/A"}');
    buf.writeln('Pickup: ${_data!.pickupAddress ?? "N/A"}');
    buf.writeln('Dropoff: ${_data!.dropoffAddress ?? "N/A"}');
    buf.writeln('Total Snapshots: ${_data!.totalSnapshots ?? 0}');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replay summary copied')),
    );
  }

  void _copyReplayTimeline() {
    if (_data == null) return;
    final buf = StringBuffer();
    buf.writeln('Replay Timeline');
    buf.writeln('=' * 60);
    for (int i = 0; i < _snapshots.length; i++) {
      final s = _snapshots[i];
      final time = s.timestamp?.toString().substring(11, 19) ?? '??';
      buf.writeln('Stage ${s.stageNumber ?? i + 1}: $time - ${s.stageName ?? ""} [${s.rideStatus ?? ""}]');
      if (s.summary != null) buf.writeln('  Summary: ${s.summary}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replay timeline copied')),
    );
  }

  void _copyCurrentStage() {
    final current = _current;
    if (current == null) return;
    final buf = StringBuffer();
    buf.writeln('Current Stage: ${current.stageName ?? ""} (#${current.stageNumber ?? 0})');
    buf.writeln('Timestamp: ${current.timestamp?.toString().substring(11, 19) ?? "N/A"}');
    buf.writeln('Ride Status: ${current.rideStatus ?? "N/A"}');
    buf.writeln('Severity: ${current.severity ?? "INFO"}');
    buf.writeln('Driver: ${current.driverLat?.toStringAsFixed(4)}, ${current.driverLng?.toStringAsFixed(4)}');
    buf.writeln('Passenger: ${current.passengerLat?.toStringAsFixed(4)}, ${current.passengerLng?.toStringAsFixed(4)}');
    buf.writeln('');
    if (current.wsEventName != null) buf.writeln('WS: ${current.wsEventName}');
    if (current.restRequest != null) buf.writeln('REST: ${current.restRequest}');
    if (current.paymentState != null) buf.writeln('Payment: ${current.paymentState}');
    if (current.backendActivity != null) buf.writeln('Backend: ${current.backendActivity}');
    if (current.summary != null) buf.writeln('Summary: ${current.summary}');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Current stage copied')),
    );
  }

  void _shareReplay() {
    _copyReplaySummary();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied. Paste into any app to share.')),
    );
  }
}
