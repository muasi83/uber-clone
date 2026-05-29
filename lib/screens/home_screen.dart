import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';

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
              }

              try {
                WebSocketService.setOffline(widget.userId);
                WebSocketService.disconnect();
              } catch (e) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: Colors.white,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            color: Colors.white,
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
            icon: const Icon(Icons.settings_outlined),
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(username: widget.username),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: Colors.white24, height: 0.5),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                      AppSpacing.gapLg,
                      Text(
                        'No users available',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapLg,
                      PremiumButton(
                        label: 'Retry',
                        variant: ButtonVariant.outline,
                        onPressed: _loadUsers,
                        height: 44,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: AppColors.primary,
                  child: ListView.separated(
                    itemCount: users.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(left: 76),
                      height: 0.5,
                      color: AppColors.outline,
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isTyping = typingStatus[user.id] ?? false;
                      final unread = unreadCounts[user.id] ?? 0;
                      final avatarColors = [
                        AppColors.primary,
                        AppColors.secondary,
                        const Color(0xFF8B5CF6),
                        const Color(0xFFF59E0B),
                        const Color(0xFF10B981),
                        const Color(0xFFEC4899),
                        const Color(0xFF3B82F6),
                        const Color(0xFFEF4444),
                      ];
                      final avatarColor = avatarColors[user.id != null ? user.id! % avatarColors.length : index % avatarColors.length];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: avatarColor,
                              child: Text(
                                user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (user.isOnline)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                    border: Border.all(
                                      color: AppColors.surface,
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
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Flexible(
                              child: Text(
                                isTyping
                                    ? 'typing...'
                                    : '@${user.username}',
                                style: TextStyle(
                                  color: isTyping
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                  fontSize: 14,
                                  fontStyle: isTyping
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isTyping)
                              const SizedBox(width: 4),
                            if (isTyping)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        trailing: unread > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
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
                      );
                    },
                  ),
                ),
    );
  }
}
