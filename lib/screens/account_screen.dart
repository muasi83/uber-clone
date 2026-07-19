import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_colors.dart';
import 'rider_profile_screen.dart';
import 'email_verification_screen.dart';
import 'phone_verification_screen.dart';
import 'payment_methods_screen.dart';
import 'support_screen.dart';
import 'safety_screen.dart';
import 'settings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = StorageService.getUserId();
    final token = StorageService.getToken();
    if (userId == null || token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${StorageService.getServerUrl()}/api/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _user = User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (_) {}

    if (mounted && _user == null) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final userId = StorageService.getUserId();
    final token = StorageService.getToken();
    if (userId != null && token != null) {
      try {
        await http.post(
          Uri.parse('${StorageService.getServerUrl()}/api/users/$userId/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
    try {
      if (userId != null) WebSocketService.setOffline(userId);
      WebSocketService.disconnect();
    } catch (_) {}
    await StorageService.clearAllData();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = StorageService.getToken() ?? '';
    final userId = StorageService.getUserId() ?? 0;
    final username = StorageService.getUsername() ?? _user?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Manage your personal information',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderProfileScreen(
                        user: _user,
                        token: token,
                      ),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.verified_outlined,
                  title: 'Email Verification',
                  subtitle: _user?.isVerified == true ? 'Verified' : 'Verify your email',
                  trailing: _user?.isVerified == true
                      ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.phone_outlined,
                  title: 'Phone Verification',
                  subtitle: _user?.phoneVerified == true ? 'Verified' : 'Verify your phone number',
                  trailing: _user?.phoneVerified == true
                      ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  subtitle: 'Manage your payment options',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodsScreen(token: token),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Support',
                  subtitle: 'Get help and contact us',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Safety',
                  subtitle: 'Safety features and preferences',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetyScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App settings and server configuration',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        username: username,
                        userId: userId,
                        token: token,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  isDestructive: true,
                  onTap: _logout,
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user?.fullName ?? StorageService.getUsername() ?? 'User';
    final email = _user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Rider',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      if (_user?.gender != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _genderLabel(_user!.gender!),
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rider',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  String _genderLabel(String gender) {
    switch (gender) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'PREFER_NOT_TO_SAY':
        return 'Prefer not to say';
      default:
        return '';
    }
  }
}
