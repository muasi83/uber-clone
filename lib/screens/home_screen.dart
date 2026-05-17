import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'debug_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String token;

  const HomeScreen({
    Key? key,
    required this.userId,
    required this.username,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<User> users = [];
  bool isLoading = true;
  final Map<int, int> unreadCounts = {};
  final Map<int, bool> typingStatus = {};

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🔍 HOME SCREEN INIT');
    addDebugMessage('User ID: ${widget.userId}');
    addDebugMessage('Username: ${widget.username}');
    addDebugMessage('Token: ${widget.token.substring(0, 20)}...');
    addDebugMessage('═══════════════════════════════════════');
    
    _loadUsers();
    _connectWebSocket();
    WebSocketService.onUserOnline = _handleUserOnline;
    WebSocketService.onUserOffline = _handleUserOffline;
    WebSocketService.onTyping = _handleTypingIndicator;
  }

  @override
  void dispose() {
    WebSocketService.disconnect();
    super.dispose();
  }

  void _connectWebSocket() {
    addDebugMessage('🔌 Connecting to WebSocket...');
    WebSocketService.connect(widget.userId, widget.username);
  }

  void _handleUserOnline(int userId, String username) {
    if (!mounted) return;
    addDebugMessage('✅ User online: $username');
    setState(() {
      for (var user in users) {
        if (user.id == userId) {
          user.isOnline = true;
          break;
        }
      }
    });
  }

  void _handleUserOffline(int userId) {
    if (!mounted) return;
    addDebugMessage('❌ User offline: $userId');
    setState(() {
      for (var user in users) {
        if (user.id == userId) {
          user.isOnline = false;
          break;
        }
      }
    });
  }

  void _handleTypingIndicator(int senderId, bool isTyping) {
    if (!mounted) return;
    setState(() {
      typingStatus[senderId] = isTyping;
    });
  }

  Future<void> _loadUsers() async {
    try {
      final url = StorageService.getUsersUrl();
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔍 LOADING USERS');
      addDebugMessage('URL: $url');
      addDebugMessage('Authorization: Bearer ${widget.token.substring(0, 20)}...');
    


final response = await http.get(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer ${widget.token}',
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  },
).timeout(const Duration(seconds: 10));





      addDebugMessage('📊 Response Status: ${response.statusCode}');
      addDebugMessage('Response Headers: ${response.headers}');
      addDebugMessage('Response Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        addDebugMessage('✅ Parsed ${jsonList.length} users');
        
        setState(() {
          users = jsonList.map((u) {
            var user = User.fromJson(u);
            addDebugMessage('👤 User: ${user.fullName} (${user.username}) - Online: ${user.isOnline}');
            return user;
          }).toList();
          isLoading = false;
        });
        addDebugMessage('✅ USERS LOADED SUCCESSFULLY');
      } else if (response.statusCode == 403) {
        addDebugMessage('❌ 403 UNAUTHORIZED');
        addDebugMessage('Possible causes:');
        addDebugMessage('1. Token is invalid or expired');
        addDebugMessage('2. Token format is wrong');
        addDebugMessage('3. Authorization header format is wrong');
        setState(() => isLoading = false);
        _showError('Unauthorized (403): Token invalid. Please login again.');
      } else {
        addDebugMessage('❌ Error ${response.statusCode}');
        setState(() => isLoading = false);
        _showError('Failed to load users: ${response.statusCode}');
      }
      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ EXCEPTION: ${e.toString()}');
      addDebugMessage('Exception Type: ${e.runtimeType}');
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _logout() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (mounted) Navigator.pop(dialogContext);
              
              try {
                await http
                    .post(
                      Uri.parse(
                          '${StorageService.getServerUrl()}/api/users/${widget.userId}/logout'),
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                      },
                    )
                    .timeout(const Duration(seconds: 10));
              } catch (e) {
                // Continue logout even if API call fails
              }

              try {
                WebSocketService.setOffline(widget.userId);
                WebSocketService.disconnect();
              } catch (e) {
                // Continue logout even if WebSocket fails
              }

              await StorageService.clearAllData();

              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/splash',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      
   appBar: AppBar(
  backgroundColor: const Color(0xFF6366F1),
  elevation: 0,
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Messages',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      Text(
        'Online now',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 12,
        ),
      ),
    ],
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Debug Console',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DebugScreen(),
          ),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SettingsScreen(username: widget.username),
          ),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: _logout,
    ),
  ],
),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isTyping = typingStatus[user.id] ?? false;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFF6366F1),
                                  child: Text(
                                    user.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: user.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              isTyping
                                  ? 'typing...'
                                  : '@${user.username}',
                              style: TextStyle(
                                color: isTyping
                                    ? Colors.blue
                                    : Colors.grey[600],
                                fontSize: 13,
                                fontStyle: isTyping
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.isOnline ? 'Active' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    currentUserId: widget.userId,
                                    currentUsername: widget.username,
                                    receiverId: user.id!,
                                    receiverName: user.fullName,
                                    token: widget.token,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}