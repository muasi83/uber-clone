import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/premium_card.dart';

class SettingsScreen extends StatefulWidget {
  final String username;
  final int userId;
  final String token;

  const SettingsScreen({
    super.key,
    required this.username,
    required this.userId,
    required this.token,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: StorageService.getServerUrl(),
    );
    _urlController.addListener(() {
      setState(() => _isChanged = true);
    });
  }

  Future<void> _saveUrl() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL cannot be empty'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await StorageService.setServerUrl(_urlController.text);
    setState(() => _isChanged = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server URL updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(
                  Uri.parse('${StorageService.getServerUrl()}/api/users/${widget.userId}/logout'),
                  headers: {'Authorization': 'Bearer ${widget.token}'},
                ).timeout(const Duration(seconds: 10));
              } catch (_) {}

              try {
                WebSocketService.setOffline(widget.userId);
                WebSocketService.disconnect();
              } catch (_) {}

              await StorageService.clearAllData();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
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
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.primaryLight),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            _buildProfileCard(),
            AppSpacing.gapXxl,
            _buildSectionHeader('Server Configuration'),
            AppSpacing.gapMd,
            _buildServerConfigCard(),
            AppSpacing.gapXxl,
            _buildSectionHeader('About'),
            AppSpacing.gapMd,
            _buildAboutCard(),
            AppSpacing.gapXxl,
            PremiumButton(
              label: 'Logout',
              onPressed: _logout,
              variant: ButtonVariant.danger,
              icon: Icons.logout_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              widget.username.isNotEmpty
                  ? widget.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapXs,
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildServerConfigCard() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumTextField(
            controller: _urlController,
            label: 'Server URL',
            hint: 'https://your-ngrok-url.ngrok-free.dev',
            prefixIcon: Icons.link,
          ),
          AppSpacing.gapLg,
          PremiumButton(
            label: 'Save Server URL',
            onPressed: _isChanged ? _saveUrl : null,
            isDisabled: !_isChanged,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: 20,
            ),
          ),
          AppSpacing.hGapMd,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RideNow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
