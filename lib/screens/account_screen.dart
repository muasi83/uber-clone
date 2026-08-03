import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/photo_service.dart';
import '../services/websocket_service.dart';
import '../services/notifications_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_card.dart';
import '../widgets/user_avatar.dart';
import 'rider_profile_screen.dart';
import 'email_verification_screen.dart';
import 'phone_verification_screen.dart';
import 'payment_methods_screen.dart';
import 'support_screen.dart';
import 'safety_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final token = StorageService.getToken();
    if (token == null) return;
    final count = await NotificationsApi.getUnreadCount(token);
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _openNotifications() async {
    final token = StorageService.getToken() ?? '';
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationsScreen(token: token)),
    );
    if (mounted) _loadUnreadCount();
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
      builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
          title: Text(l10n.logOut),
          content: Text(l10n.areYouSureYouWantToLogOut),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.logOut, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
          ],
        );
        },
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
    final l10n = AppLocalizations.of(context);
    final token = StorageService.getToken() ?? '';
    final userId = StorageService.getUserId() ?? 0;
    final username = StorageService.getUsername() ?? _user?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).account),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                _buildProfileHeader(),
                AppSpacing.gapXl,
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: l10n.myProfile,
                  subtitle: 'Manage your personal information',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderProfileScreen(
                          user: _user,
                          token: token,
                        ),
                      ),
                    );
                    if (mounted) _loadUser();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.verified_outlined,
                  title: 'Email Verification',
                  subtitle: _user?.isVerified == true ? l10n.verified : l10n.verifyYourEmail,
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
                  subtitle: _user?.phoneVerified == true ? l10n.verified : 'Verify your phone number',
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
                  title: l10n.paymentMethods,
                  subtitle: 'Manage your payment options',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodsScreen(token: token),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: _unreadCount > 0
                      ? '$_unreadCount unread'
                      : 'Review your notifications',
                  trailing: _unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                  onTap: _openNotifications,
                ),
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: l10n.support,
                  subtitle: 'Get help and contact us',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: l10n.safety,
                  subtitle: 'Safety features and preferences',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetyScreen()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: l10n.settings,
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
                AppSpacing.gapLg,
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: l10n.logOut,
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
    return Semantics(
      label: 'Account profile for $name',
      child: PremiumCard(
        shadows: AppShadows.small,
        child: Row(
          children: [
            Semantics(
              label: 'Profile avatar',
              child: UserAvatar(
                photoUrl: PhotoService.resolvePhotoUrl(_user?.photoUrl),
                displayName: name,
                radius: 32,
              ),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'User name',
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Semantics(
                        label: 'Rating 4.8 out of 5',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                  AppLocalizations.of(context).rider,
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Edit profile',
              child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
            ),
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
    return Semantics(
      label: '$title, $subtitle',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: PremiumCard(
          hasRipple: true,
          onTap: onTap,
          shadows: [],
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primaryContainer,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? AppColors.error : AppColors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

}
