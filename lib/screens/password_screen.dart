import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../services/recorded_screen_mixin.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';
import '../l10n/app_localizations.dart';
import 'otp_screen.dart';

class PasswordScreen extends StatefulWidget {
  final String email;

  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with RecordedScreenMixin<PasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _passwordError = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final pwd = _passwordController.text;
    if (pwd.isNotEmpty && pwd.length < 6) {
      setState(() => _passwordError = AppLocalizations.of(context).passwordMustBeAtLeast6Characters);
    } else if (_passwordError.isNotEmpty) {
      setState(() => _passwordError = '');
    }
  }

  Future<void> _login() async {
    if (_passwordController.text.isEmpty) {
      _showError(AppLocalizations.of(context).pleaseEnterAPassword);
      return;
    }

    setState(() => _isLoading = true);

    recordEvent(
      eventName: 'LOGIN_ATTEMPT',
      category: 'BUSINESS',
      summary: 'User attempted login',
    );

    try {
      final url = '${StorageService.getServerUrl()}/api/auth/login';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'email': widget.email,
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await StorageService.saveToken(data['token'] ?? '');
        await StorageService.saveUserId(data['userId'] ?? 0);
        await StorageService.saveUsername(data['username'] ?? '');
        await StorageService.saveRole(data['role'] ?? 'RIDER');
        await StorageService.saveGender(data['gender'] ?? 'PREFER_NOT_TO_SAY');
        await FirebaseService.sendTokenToServer();

        recordEvent(
          eventName: 'LOGIN_SUCCESS',
          category: 'BUSINESS',
          summary: 'User logged in successfully',
        );

        if (mounted) {
          final role = data['role'] ?? 'RIDER';

          if (role == 'DRIVER') {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/driver-home',
              (route) => false,
            );
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/rider-home',
              (route) => false,
            );
          }
        }
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['message'] ?? AppLocalizations.of(context).loginFailedPleaseCheckYourCredentialsAndTryAgain;
        recordEvent(
          eventName: 'LOGIN_FAILED',
          category: 'BUSINESS',
          severity: 'ERROR',
          summary: 'Login failed: $errorMsg',
        );
        _showError(errorMsg);
      }
    } on TimeoutException {
      recordEvent(
        eventName: 'LOGIN_FAILED',
        category: 'BUSINESS',
        severity: 'ERROR',
        summary: 'Login failed: Request timed out',
      );
      _showError('Request timed out. Please try again.');
    } on SocketException {
      recordEvent(
        eventName: 'LOGIN_FAILED',
        category: 'BUSINESS',
        severity: 'ERROR',
        summary: 'Login failed: Connection error',
      );
      _showError('Connection error. Check your internet.');
    } catch (e) {
      recordEvent(
        eventName: 'LOGIN_FAILED',
        category: 'BUSINESS',
        severity: 'ERROR',
        summary: 'Login failed: $e',
      );
      _showError(AppLocalizations.of(context).anUnexpectedErrorOccurred);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    recordEvent(
      eventName: 'ERROR_SNACKBAR',
      category: 'UI',
      severity: 'ERROR',
      summary: message,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        margin: AppSpacing.cardPadding,
      ),
    );
  }

  Future<void> _sendLoginOtp() async {
    setState(() => _isLoading = true);
    try {
      final url = '${StorageService.getServerUrl()}/api/auth/send-login-otp';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                email: widget.email,
                title: 'Check your email',
                subtitle: 'We sent a login code to',
                onVerified: (json, code) {
                  _handleOtpVerified(json);
                },
                resendOtp: () {
                  _sendLoginOtp();
                },
              ),
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? AppLocalizations.of(context).failedToSendOtpPleaseTryAgain);
      }
    } on TimeoutException {
      _showError('Request timed out. Please try again.');
    } on SocketException {
      _showError('Connection error. Check your internet.');
    } catch (e) {
      _showError(AppLocalizations.of(context).anUnexpectedErrorOccurred);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleOtpVerified(Map<String, dynamic> data) async {
    await StorageService.saveToken(data['token'] ?? '');
    await StorageService.saveUserId(data['userId'] ?? 0);
    await StorageService.saveUsername(data['username'] ?? '');
    await StorageService.saveRole(data['role'] ?? 'RIDER');
    await StorageService.saveGender(data['gender'] ?? 'PREFER_NOT_TO_SAY');
    await FirebaseService.sendTokenToServer();

    if (!mounted) return;
    final role = data['role'] ?? 'RIDER';
    if (role == 'DRIVER') {
      Navigator.of(context).pushNamedAndRemoveUntil('/driver-home', (route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/rider-home', (route) => false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canLogin = _passwordController.text.isNotEmpty &&
        _passwordError.isEmpty &&
        !_isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadius.xlRadius,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.gapXxl,
                Text(
                  AppLocalizations.of(context).welcomeBack,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapXxxl,
                PremiumTextField(
                  controller: _passwordController,
                  label: AppLocalizations.of(context).password,
                  prefixIcon: Icons.lock_outlined,
                  isPassword: true,
                  obscureText: true,
                  errorText: _passwordError.isNotEmpty ? _passwordError : null,
                ),
                AppSpacing.gapMd,
                PremiumButton(
                  label: 'Sign In',
                  onPressed: canLogin ? _login : null,
                  isLoading: _isLoading,
                  variant: ButtonVariant.gradient,
                ),
                AppSpacing.gapLg,
                TextButton(
                  onPressed: _isLoading ? null : _sendLoginOtp,
                  child: Text(
                    AppLocalizations.of(context).useOtpInstead,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
