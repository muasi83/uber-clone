import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../services/storage_service.dart';
import 'otp_screen.dart';
import 'reset_password_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = StorageService.getAuthForgotPasswordUrl();
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': _emailController.text}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                email: _emailController.text,
                title: 'Reset your password',
                subtitle: 'We sent a reset code to',
                verifyUrl: StorageService.getAuthVerifyResetOtpUrl(),
                onVerified: (_, code) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(
                        email: _emailController.text,
                        code: code,
                      ),
                    ),
                  );
                },
                resendOtp: () {
                  _sendOtp();
                },
              ),
            ),
          );
        }
      } else {
        final json = jsonDecode(response.body);
        _showError(json['message'] ?? 'Failed to send OTP');
      }
    } on TimeoutException {
      _showError('Request timed out. Please try again.');
    } on SocketException {
      _showError('Connection error. Check your internet.');
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.gapXxl,
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapMd,
                const Text(
                  'Enter your email and we\'ll send you a code to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapXxxl,
                PremiumTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                AppSpacing.gapXxl,
                PremiumButton(
                  label: 'Send Reset Code',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _sendOtp,
                  variant: ButtonVariant.gradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
