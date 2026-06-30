import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../screens/debug_screen.dart';
import 'dart:async';
import 'dart:io';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'RIDER';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  Future<void> _register() async {
    try {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _fullNameController.text.isEmpty ||
          _usernameController.text.isEmpty) {
        _showError('Please fill all fields');
        return;
      }

      if (_passwordController.text.length < 6) {
        _showError('Password must be at least 6 characters');
        return;
      }

      setState(() => _isLoading = true);

      final url = '${StorageService.getServerUrl()}/api/auth/register';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'email': _emailController.text,
              'password': _passwordController.text,
              'fullName': _fullNameController.text,
              'username': _usernameController.text,
              'role': _selectedRole,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        await StorageService.saveToken(data['token'] ?? '');
        await StorageService.saveUserId(data['userId'] ?? 0);
        await StorageService.saveUsername(data['username'] ?? '');
        await StorageService.saveRole(data['role'] ?? 'RIDER');
        await FirebaseService.sendTokenToServer();

        if (mounted) {
          final role = data['role'] ?? 'RIDER';

          if (role == 'DRIVER') {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/driver-registration',
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
        _showError(error['message'] ?? 'Registration failed');
      }
    } on TimeoutException {
      _showError('Request timed out. Please try again.');
    } on SocketException {
      _showError('Connection error. Check your internet.');
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        _showError('Please enter email and password');
        return;
      }

      setState(() => _isLoading = true);

      final url = '${StorageService.getServerUrl()}/api/auth/login';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'email': _emailController.text,
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
        await FirebaseService.sendTokenToServer();

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
        _showError(error['message'] ?? 'Login failed');
      }
    } on TimeoutException {
      _showError('Request timed out. Please try again.');
    } on SocketException {
      _showError('Connection error. Check your internet.');
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 40),
                decoration: const BoxDecoration(
                  gradient: AppColors.darkGradient,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 36,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    AppSpacing.gapLg,
                    const Text(
                      'RideNow',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryLight.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      AppSpacing.gapLg,
                      _buildPillToggle(),
                      AppSpacing.gapXxl,
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _isLogin
                                ? _buildLoginForm()
                                : _buildRegisterForm(),
                          ),
                        ),
                      ),
                      AppSpacing.gapXxl,
                      TextButton(
                        onPressed: _showServerUrlDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                        ),
                        child: const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLogin ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isLogin
                      ? [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isLogin ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLogin ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isLogin
                      ? [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Register',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isLogin
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumTextField(
          controller: _emailController,
          label: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.gapLg,
        PremiumTextField(
          controller: _passwordController,
          label: 'Password',
          prefixIcon: Icons.lock_outlined,
          isPassword: true,
          obscureText: true,
        ),
        AppSpacing.gapXl,
        PremiumButton(
          label: 'Sign In',
          onPressed: _isLoading ? null : _login,
          isLoading: _isLoading,
          variant: ButtonVariant.gradient,
        ),
        AppSpacing.gapLg,
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _emailController.text = 'rider2@test.com';
                  _passwordController.text = 'password123';
                  setState(() => _selectedRole = 'RIDER');
                },
                icon: const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                label: const Text('Rider 2'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _emailController.text = 'driver2@test.com';
                  _passwordController.text = 'password123';
                  setState(() => _selectedRole = 'DRIVER');
                },
                icon: const Icon(Icons.local_taxi_outlined, size: 16, color: AppColors.primary),
                label: const Text('Driver 2'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumTextField(
          controller: _fullNameController,
          label: 'Full Name',
          prefixIcon: Icons.person_outlined,
        ),
        AppSpacing.gapLg,
        PremiumTextField(
          controller: _usernameController,
          label: 'Username',
          prefixIcon: Icons.account_circle_outlined,
        ),
        AppSpacing.gapLg,
        PremiumTextField(
          controller: _emailController,
          label: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.gapLg,
        PremiumTextField(
          controller: _passwordController,
          label: 'Password',
          prefixIcon: Icons.lock_outlined,
          isPassword: true,
          obscureText: true,
        ),
        AppSpacing.gapXl,
        const Text(
          'I want to',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.gapSm,
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: 'RIDER',
                icon: Icons.person,
                title: 'Ride',
                subtitle: 'Request a trip',
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildRoleCard(
                role: 'DRIVER',
                icon: Icons.directions_car,
                title: 'Drive',
                subtitle: 'Earn money',
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _fullNameController.text = 'Rider Two';
                  _usernameController.text = 'rider2';
                  _emailController.text = 'rider2@test.com';
                  _passwordController.text = 'password123';
                  setState(() => _selectedRole = 'RIDER');
                },
                icon: const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                label: const Text('Rider 2'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _fullNameController.text = 'Driver Two';
                  _usernameController.text = 'driver2';
                  _emailController.text = 'driver2@test.com';
                  _passwordController.text = 'password123';
                  setState(() => _selectedRole = 'DRIVER');
                },
                icon: const Icon(Icons.local_taxi_outlined, size: 16, color: AppColors.primary),
                label: const Text('Driver 2'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapXl,
        PremiumButton(
          label: 'Create Account',
          onPressed: _isLoading ? null : _register,
          isLoading: _isLoading,
          variant: ButtonVariant.gradient,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 28,
            ),
            AppSpacing.gapSm,
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerUrlDialog() {
    final urlController =
        TextEditingController(text: StorageService.getServerUrl());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Server Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapXl,
              PremiumTextField(
                controller: urlController,
                label: 'Server URL',
                hint: 'https://your-ngrok-url.ngrok-free.dev',
              ),
              AppSpacing.gapXxl,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: PremiumButton(
                      label: 'Save',
                      onPressed: () async {
                        await StorageService.setServerUrl(urlController.text);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Server URL updated'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      variant: ButtonVariant.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
