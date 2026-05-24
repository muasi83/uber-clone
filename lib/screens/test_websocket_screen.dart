import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class TestWebSocketScreen extends StatefulWidget {
  const TestWebSocketScreen({Key? key}) : super(key: key);

  @override
  State<TestWebSocketScreen> createState() => _TestWebSocketScreenState();
}

class _TestWebSocketScreenState extends State<TestWebSocketScreen> {
  String _connectionStatus = 'Disconnected';
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to connection state
    WebSocketService.connectionState.listen((state) {
      setState(() {
        _connectionStatus = state;
        _messages.add('🔄 Status: $state');
      });
    });

    // Listen to ride events
    WebSocketService.rideEvents.listen((message) {
      String type = message['type'] ?? 'unknown';
      setState(() {
        _messages.add('🚗 Event: $type');
      });
    });
  }

  void _connect() {
    setState(() => _messages.add('📤 Connecting...'));
    WebSocketService.connect(6, 'rider2');
  }

  void _disconnect() {
    setState(() => _messages.add('📤 Disconnecting...'));
    WebSocketService.disconnect();
  }

  void _sendTest() {
    setState(() => _messages.add('📤 Sent: test'));
    WebSocketService.sendRideMessage('test', {'msg': 'test'});
  }

  void _clear() {
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _connectionStatus == 'connected'
        ? Colors.green
        : _connectionStatus == 'error'
            ? Colors.red
            : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Test - $_connectionStatus'),
        backgroundColor: statusColor,
      ),
      body: Column(
        children: [
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _connectionStatus != 'connected' ? _connect : null,
                    child: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _connectionStatus == 'connected' ? _disconnect : null,
                    child: const Text('Disconnect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _connectionStatus == 'connected' ? _sendTest : null,
                    child: const Text('Send Test'),
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[_messages.length - 1 - index]),
                  dense: true,
                );
              },
            ),
          ),
          // Clear button
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _clear,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}