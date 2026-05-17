import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global list to store debug messages
List<String> debugMessages = [];

// Function to add debug message
void addDebugMessage(String message) {
  debugMessages.add('[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $message');
  print(message); // Also print to console
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _copyToClipboard() {
    final allMessages = debugMessages.join('\n');
    Clipboard.setData(ClipboardData(text: allMessages));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Debug logs copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollToBottom();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6366F1),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy All Logs',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed: () {
              setState(() {
                debugMessages.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: debugMessages.isEmpty
            ? const Center(
                child: Text(
                  'No debug messages yet...',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: debugMessages.length,
                itemBuilder: (context, index) {
                  final message = debugMessages[index];
                  
                  // Color code based on message content
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
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}