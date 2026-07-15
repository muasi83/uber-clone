import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../screens/debug_screen.dart';
import '../models/trip_events.dart';

class TripBehaviourService {
  static String _normalizeToken(String token) {
    var t = token.trim();
    if (t.length >= 2 &&
        ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'")))) {
      t = t.substring(1, t.length - 1).trim();
    }
    final lower = t.toLowerCase();
    if (lower.startsWith('bearer ')) {
      t = t.substring(7).trim();
    }
    return t;
  }

  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_normalizeToken(token)}';
    }
    return headers;
  }

  static Future<TripBehaviourResponse?> getBehaviour({
    required int rideId,
    required String token,
    String filter = '',
    String search = '',
    int page = 0,
    int size = 500,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (filter.isNotEmpty) params['filter'] = filter;
      if (search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('${StorageService.getServerUrl()}/api/admin/trips/$rideId/behaviour')
          .replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return TripBehaviourResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      addDebugMessage('TripBehaviour getBehaviour error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      addDebugMessage('TripBehaviour getBehaviour exception: $e');
      return null;
    }
  }

  static Future<TripReplayResponse?> getReplay({
    required int rideId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('${StorageService.getServerUrl()}/api/admin/trips/$rideId/replay');
      final response = await http
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return TripReplayResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      addDebugMessage('TripReplay getReplay error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      addDebugMessage('TripReplay getReplay exception: $e');
      return null;
    }
  }

  static String generateSummaryText(TripSummary? summary, List<TripBehaviourEvent> events) {
    if (summary == null) return 'No summary available.';
    final buf = StringBuffer();
    buf.writeln('Trip Summary');
    buf.writeln('=' * 40);
    buf.writeln('Status: ${summary.rideStatus ?? "N/A"}');
    buf.writeln('Duration: ${summary.duration ?? "N/A"}');
    buf.writeln('Health Score: ${summary.healthScore ?? 100}%');
    buf.writeln('Warnings: ${summary.warningCount ?? 0}');
    buf.writeln('Errors: ${summary.errorCount ?? 0}');
    buf.writeln('Recoveries: ${summary.recoveryCount ?? 0}');
    buf.writeln('Network Interruptions: ${summary.networkInterruptions ?? 0}');
    buf.writeln('WebSocket Reconnects: ${summary.wsReconnects ?? 0}');
    buf.writeln('GPS Interruptions: ${summary.gpsInterruptions ?? 0}');
    buf.writeln('Payment Retries: ${summary.paymentRetries ?? 0}');
    if (summary.longestStage != null) {
      buf.writeln('Longest Stage: ${summary.longestStage} (${summary.longestStageMs != null ? "${summary.longestStageMs! ~/ 1000}s" : "N/A"})');
    }
    if (summary.possibleIssues != null && summary.possibleIssues!.isNotEmpty) {
      buf.writeln('');
      buf.writeln('Possible Issues:');
      for (final issue in summary.possibleIssues!) {
        buf.writeln('  - $issue');
      }
    }
    buf.writeln('');
    buf.writeln('Key Events:');
    for (final event in events) {
      buf.writeln('  ${event.timestamp?.toString().substring(11, 19) ?? "??"} [${event.severity ?? "INFO"}] ${event.eventName ?? ""} - ${event.summary ?? ""}');
    }
    return buf.toString();
  }

  static String generateFullTimeline(List<TripBehaviourEvent> events) {
    if (events.isEmpty) return 'No events recorded.';
    final buf = StringBuffer();
    buf.writeln('Trip Timeline');
    buf.writeln('=' * 60);
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      buf.writeln('');
      buf.writeln('#${i + 1} - ${e.timestamp?.toString().substring(11, 19) ?? "??"}');
      buf.writeln('  Event: ${e.eventName ?? "N/A"}');
      buf.writeln('  Category: ${e.categoryDisplay}');
      buf.writeln('  Actor: ${e.actorName ?? e.actor ?? "SYSTEM"}');
      buf.writeln('  Severity: ${e.severity ?? "INFO"}');
      if (e.summary != null) buf.writeln('  Summary: ${e.summary}');
      if (e.rideStatus != null) buf.writeln('  Ride Status: ${e.rideStatus}');
      if (e.details != null && e.details!.isNotEmpty) {
        buf.writeln('  Details: ${jsonEncode(e.details)}');
      }
    }
    return buf.toString();
  }

  static String generateAiReport(TripSummary? summary, List<TripBehaviourEvent> events) {
    if (summary == null && events.isEmpty) return 'No data available.';
    final buf = StringBuffer();
    buf.writeln('TRIP BLACK BOX REPORT');
    buf.writeln('=' * 60);
    if (summary != null) {
      buf.writeln('');
      buf.writeln('## Trip Overview');
      buf.writeln('- Status: ${summary.rideStatus ?? "N/A"}');
      buf.writeln('- Duration: ${summary.duration ?? "N/A"}');
      buf.writeln('- Health Score: ${summary.healthScore ?? 100}/100');
      buf.writeln('- Anomalies: ${(summary.warningCount ?? 0) + (summary.errorCount ?? 0)} (${summary.warningCount ?? 0} warnings, ${summary.errorCount ?? 0} errors)');
      buf.writeln('- Network Issues: ${summary.networkInterruptions ?? 0}');
      buf.writeln('- WebSocket Reconnects: ${summary.wsReconnects ?? 0}');
      buf.writeln('- Payment Retries: ${summary.paymentRetries ?? 0}');
    }
    buf.writeln('');
    buf.writeln('## Event Timeline');
    for (final e in events) {
      if (e.timestamp == null) continue;
      buf.writeln('${e.timestamp!.toIso8601String()} | ${e.severity ?? "INFO"} | ${e.eventName ?? ""} | ${e.category ?? ""} | ${e.summary ?? ""}');
    }
    buf.writeln('');
    buf.writeln('## Analysis Prompt');
    buf.writeln('Analyze the above trip data and identify:');
    buf.writeln('1. What went wrong during this trip?');
    buf.writeln('2. What was the root cause of each issue?');
    buf.writeln('3. What could be improved to prevent similar issues?');
    return buf.toString();
  }

  static String generateMarkdown(TripSummary? summary, List<TripBehaviourEvent> events) {
    if (summary == null && events.isEmpty) return '# No Data';
    final buf = StringBuffer();
    buf.writeln('# Trip Black Box Report');
    buf.writeln();
    if (summary != null) {
      buf.writeln('## Summary');
      buf.writeln('| Metric | Value |');
      buf.writeln('|--------|-------|');
      buf.writeln('| Status | ${summary.rideStatus ?? "N/A"} |');
      buf.writeln('| Duration | ${summary.duration ?? "N/A"} |');
      buf.writeln('| Health Score | ${summary.healthScore ?? 100}% |');
      buf.writeln('| Warnings | ${summary.warningCount ?? 0} |');
      buf.writeln('| Errors | ${summary.errorCount ?? 0} |');
      buf.writeln('| Recoveries | ${summary.recoveryCount ?? 0} |');
      buf.writeln('| Network Interruptions | ${summary.networkInterruptions ?? 0} |');
      buf.writeln('| WebSocket Reconnects | ${summary.wsReconnects ?? 0} |');
      buf.writeln();
    }
    buf.writeln('## Timeline');
    buf.writeln('| # | Time | Event | Category | Severity | Summary |');
    buf.writeln('|---|------|-------|----------|----------|---------|');
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      final time = e.timestamp?.toString().substring(11, 19) ?? '';
      buf.writeln('| ${i + 1} | $time | ${e.eventName ?? ""} | ${e.categoryDisplay} | ${e.severity ?? "INFO"} | ${e.summary ?? ""} |');
    }
    return buf.toString();
  }

  static String generateJsonExport(TripSummary? summary, List<TripBehaviourEvent> events) {
    final data = <String, dynamic>{
      'summary': summary != null ? {
        'rideId': summary.rideId,
        'rideStatus': summary.rideStatus,
        'duration': summary.duration,
        'healthScore': summary.healthScore,
        'warningCount': summary.warningCount,
        'errorCount': summary.errorCount,
        'recoveryCount': summary.recoveryCount,
        'networkInterruptions': summary.networkInterruptions,
        'paymentRetries': summary.paymentRetries,
        'wsReconnects': summary.wsReconnects,
        'gpsInterruptions': summary.gpsInterruptions,
        'longestStage': summary.longestStage,
        'possibleIssues': summary.possibleIssues,
      } : null,
      'events': events.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
