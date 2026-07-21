import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/premium_card.dart';
import '../services/recorded_screen_mixin.dart';

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

class _SettingsScreenState extends State<SettingsScreen> with RecordedScreenMixin<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'SETTINGS_OPENED');
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
    recordEvent(eventName: 'SERVER_URL_UPDATED');
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
          borderRadius: AppRadius.lgRadius,
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
      body: Semantics(
        label: 'Settings page',
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              _buildProfileCard(),
              AppSpacing.gapXxl,
              _buildSectionHeader('Notifications'),
              AppSpacing.gapMd,
              _buildNotificationPrefs(),
              AppSpacing.gapXxl,
              _buildSectionHeader('Currency'),
              AppSpacing.gapMd,
              _buildCurrencySelector(),
              AppSpacing.gapXxl,
              _buildSectionHeader('About'),
              AppSpacing.gapMd,
              _buildAboutCard(),
              if (kDebugMode) ...[
                AppSpacing.gapXxl,
                _buildSectionHeader('Server Configuration (Dev)'),
                AppSpacing.gapMd,
                _buildServerConfigCard(),
              ],
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
      ),
    );
  }

  Widget _buildProfileCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
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

  Widget _buildNotificationPrefs() {
    return PremiumCard(
      child: Column(
        children: [
          Semantics(
            label: 'Push notifications toggle',
            child: SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('Receive ride updates and offers', style: TextStyle(fontSize: 12)),
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          Semantics(
            label: 'SMS notifications toggle',
            child: SwitchListTile(
              title: const Text('SMS Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('Receive text messages for rides', style: TextStyle(fontSize: 12)),
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          Semantics(
            label: 'Email notifications toggle',
            child: SwitchListTile(
              title: const Text('Email Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('Receive promotional emails', style: TextStyle(fontSize: 12)),
              value: false,
              onChanged: (_) {},
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
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

  Widget _buildCurrencySelector() {
    return PremiumCard(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: AppRadius.mdRadius,
          ),
          child: const Icon(
            Icons.attach_money,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: const Text(
          'Display Currency',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          CurrencyService.symbol == '\$'
              ? 'USD (\$)'
              : '${CurrencyService.preferred.name.toUpperCase()} (${CurrencyService.symbol})',
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: () async {
          final result = await showDialog<Currency>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
              title: const Text('Display Currency', style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: Currency.values.map((c) {
                  final label = switch (c) {
                    Currency.usd => 'USD (\$)',
                    Currency.sar => 'SAR (SR)',
                    Currency.syp => 'SYP (£S)',
                  };
                  return RadioListTile<Currency>(
                    value: c,
                    groupValue: CurrencyService.preferred,
                    title: Text(label),
                    onChanged: (v) => Navigator.pop(ctx, v),
                  );
                }).toList(),
              ),
            ),
          );
          if (result != null) {
            await CurrencyService.setCurrency(result);
            setState(() {});
          }
        },
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
              borderRadius: AppRadius.mdRadius,
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
