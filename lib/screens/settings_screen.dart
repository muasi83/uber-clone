import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/currency_service.dart';
import '../services/locale_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/premium_card.dart';
import '../services/recorded_screen_mixin.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' as app;

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
    final l10n = AppLocalizations.of(context);
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.urlCannotBeEmpty),
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
        SnackBar(
          content: Text(l10n.serverUrlUpdated),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
        ),
        title: Text(l10n.logout),
        content: Text(l10n.areYouSureYouWantToLogOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
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
            child: Text(
              l10n.logout,
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          l10n.settings,
          style: const TextStyle(color: AppColors.primaryLight),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Semantics(
        label: l10n.settings,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              _buildProfileCard(l10n),
              AppSpacing.gapXxl,
              _buildSectionHeader(l10n.language),
              AppSpacing.gapMd,
              _buildLanguageSelector(l10n),
              AppSpacing.gapXxl,
              _buildSectionHeader(l10n.notifications),
              AppSpacing.gapMd,
              _buildNotificationPrefs(l10n),
              AppSpacing.gapXxl,
              _buildSectionHeader(l10n.currency),
              AppSpacing.gapMd,
              _buildCurrencySelector(l10n),
              AppSpacing.gapXxl,
              _buildSectionHeader(l10n.about),
              AppSpacing.gapMd,
              _buildAboutCard(l10n),
              if (kDebugMode) ...[
                AppSpacing.gapXxl,
                _buildSectionHeader('Server Configuration (Dev)'),
                AppSpacing.gapMd,
                _buildServerConfigCard(l10n),
              ],
              AppSpacing.gapXxl,
              PremiumButton(
                label: l10n.logout,
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

  Widget _buildProfileCard(dynamic l10n) {
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
                Text(
                  l10n.settings,
                  style: const TextStyle(
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

  Widget _buildLanguageSelector(dynamic l10n) {
    return PremiumCard(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppRadius.mdRadius,
              ),
              child: const Icon(Icons.language, color: AppColors.primary, size: 20),
            ),
            title: Text(
              l10n.language,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            trailing: DropdownButton<String>(
              value: Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en',
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (code) {
                if (code == null) return;
                final locale = Locale(code);
                LocaleService.setLocale(locale);
                app.MyApp.localeNotifier.value = locale;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPrefs(dynamic l10n) {
    return PremiumCard(
      child: Column(
        children: [
          Semantics(
            label: 'Push notifications toggle',
            child: SwitchListTile(
              title: Text(l10n.pushNotifications, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(l10n.rideUpdatesAndOffers, style: const TextStyle(fontSize: 12)),
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
              title: Text(l10n.smsNotifications, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(l10n.receiveTextMessagesForRides, style: const TextStyle(fontSize: 12)),
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
              title: Text(l10n.emailNotifications, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(l10n.receivePromotionalEmails, style: const TextStyle(fontSize: 12)),
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

  Widget _buildServerConfigCard(dynamic l10n) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumTextField(
            controller: _urlController,
            label: l10n.serverUrl,
            hint: 'https://your-ngrok-url.ngrok-free.dev',
            prefixIcon: Icons.link,
          ),
          AppSpacing.gapLg,
          PremiumButton(
            label: l10n.saveServerUrl,
            onPressed: _isChanged ? _saveUrl : null,
            isDisabled: !_isChanged,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(dynamic l10n) {
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
        title: Text(
          l10n.displayCurrency,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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
              title: Text(l10n.displayCurrency, style: const TextStyle(fontSize: 16)),
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

  Widget _buildAboutCard(dynamic l10n) {
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
