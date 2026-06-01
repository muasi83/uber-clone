import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/debug_screen.dart';

class CrashReporter {
  static final CrashReporter _instance = CrashReporter._();
  static CrashReporter get instance => _instance;
  CrashReporter._();

  static final List<String> _crashLogs = [];
  static StreamController<List<String>>? _logController;

  static void init() {
    FlutterError.onError = (FlutterErrorDetails details) {
      _recordError(details.exception, details.stack);
      FlutterError.presentError(details);
    };

    _loadPersistedLogs();
  }

  static void _loadPersistedLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        final lines = await file.readAsLines();
        _crashLogs.addAll(lines.take(200));
        _notify();
      }
    } catch (_) {}
  }

  static Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/crash_logs.txt');
  }

  static void _recordError(Object error, StackTrace? stack) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] ERROR: $error\n$stack';
    _crashLogs.add(entry);
    addDebugMessage(' CRASH: $error');
    _persist(entry);
    _notify();
  }

  static void _persist(String entry) async {
    try {
      final file = await _getLogFile();
      await file.writeAsString('$entry\n', mode: FileMode.append);
    } catch (_) {}
  }

  static void _notify() {
    _logController?.add(List.unmodifiable(_crashLogs));
  }

  static void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';
    _crashLogs.add(entry);
    _persist(entry);
    _notify();
  }

  static List<String> get logs => List.unmodifiable(_crashLogs);

  static Stream<List<String>> get logStream {
    _logController ??= StreamController<List<String>>.broadcast();
    return _logController!.stream;
  }

  static String getFormattedLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== Crash Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('---');
    for (final msg in debugMessages) {
      buffer.writeln(msg);
    }
    buffer.writeln('');
    buffer.writeln('=== Unhandled Errors ===');
    for (final log in _crashLogs) {
      buffer.writeln(log);
    }
    return buffer.toString();
  }

  static Future<void> clearLogs() async {
    _crashLogs.clear();
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    _notify();
  }

  static void dispose() {
    _logController?.close();
    _logController = null;
  }
}
