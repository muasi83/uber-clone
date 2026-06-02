// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/crash_reporter.dart';

List<String> debugMessages = [];

void addDebugMessage(String message) {
  debugMessages.add('[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $message');
  print(message);
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _sendEmail() {
    final logs = CrashReporter.getFormattedLogs();
    Clipboard.setData(ClipboardData(text: logs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copied! Paste into an email to support@yourapp.com'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    debugMessages.clear();
    await CrashReporter.clearLogs();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Feedback'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Debug Logs'),
            Tab(text: 'Crash Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.email_outlined),
            tooltip: 'Send Feedback',
            onPressed: _sendEmail,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear All',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDebugLogs(),
          _buildCrashReports(),
        ],
      ),
    );
  }

  Widget _buildDebugLogs() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${debugMessages.length} messages',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                  onPressed: () => _copyToClipboard(debugMessages.join('\n')),
                ),
              ],
            ),
          ),
          Expanded(
            child: debugMessages.isEmpty
                ? const Center(child: Text('No debug messages', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: debugMessages.length,
                    itemBuilder: (context, index) {
                      final message = debugMessages[index];
                      Color textColor = Colors.white;
                      if (message.contains('❌') || message.contains('ERROR')) {
                        textColor = Colors.red;
                      } else if (message.contains('✅') || message.contains('SUCCESS')) {
                        textColor = Colors.green;
                      } else if (message.contains('🔍')) {
                        textColor = Colors.yellow;
                      } else if (message.contains('🚀')) {
                        textColor = Colors.cyan;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          message,
                          style: TextStyle(color: textColor, fontFamily: 'Courier', fontSize: 11),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashReports() {
    final crashLogs = CrashReporter.logs;
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${crashLogs.length} recorded errors',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                  onPressed: () => _copyToClipboard(crashLogs.join('\n')),
                ),
              ],
            ),
          ),
          Expanded(
            child: crashLogs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 16),
                        Text('No crashes recorded', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('If the app crashes, the error will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: crashLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: SelectableText(
                            crashLogs[index],
                            style: const TextStyle(color: Colors.red, fontFamily: 'Courier', fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
