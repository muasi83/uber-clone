
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import 'dart:async';
import 'dart:io';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'RIDER';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    addDebugMessage('📱 Auth Screen Initialized');
  }

  /// Register new user
  Future<void> _register() async {
    try {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _fullNameController.text.isEmpty ||
          _usernameController.text.isEmpty) {
        _showError('Please fill all fields');
        return;
      }

      setState(() => _isLoading = true);

      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📝 REGISTERING NEW USER');
      addDebugMessage('Email: ${_emailController.text}');
      addDebugMessage('Username: ${_usernameController.text}');
      addDebugMessage('Role: $_selectedRole');
      addDebugMessage('═══════════════════════════════════════');

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

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        addDebugMessage('✅ Registration successful');
        addDebugMessage('User ID: ${data['userId']}');

        // Save user data
        await StorageService.saveToken(data['token'] ?? '');
        await StorageService.saveUserId(data['userId'] ?? 0);
        await StorageService.saveUsername(data['username'] ?? '');
        await StorageService.saveRole(data['role'] ?? 'RIDER');

        addDebugMessage('═══════════════════════════════════════');

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
        addDebugMessage('❌ Registration failed: ${error['message']}');
        _showError(error['message'] ?? 'Registration failed');
      }
    } on TimeoutException catch (e) {
      addDebugMessage('❌ Timeout: $e');
      _showError('Request timed out. Please try again.');
    } on SocketException catch (e) {
      addDebugMessage('❌ Socket Error: $e');
      _showError('Connection error. Check your internet.');
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Login user
  Future<void> _login() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        _showError('Please enter email and password');
        return;
      }

      setState(() => _isLoading = true);

      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔐 LOGGING IN');
      addDebugMessage('Email: ${_emailController.text}');
      addDebugMessage('═══════════════════════════════════════');

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

      addDebugMessage('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        addDebugMessage('✅ Login successful');
        addDebugMessage('User: ${data['username']}');
        addDebugMessage('Role: ${data['role']}');

        // Save user data
        await StorageService.saveToken(data['token'] ?? '');
        await StorageService.saveUserId(data['userId'] ?? 0);
        await StorageService.saveUsername(data['username'] ?? '');
        await StorageService.saveRole(data['role'] ?? 'RIDER');

        addDebugMessage('═══════════════════════════════════════');

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
        addDebugMessage('❌ Login failed: ${error['message']}');
        _showError(error['message'] ?? 'Login failed');
      }
    } on TimeoutException catch (e) {
      addDebugMessage('❌ Timeout: $e');
      _showError('Request timed out. Please try again.');
    } on SocketException catch (e) {
      addDebugMessage('❌ Socket Error: $e');
      _showError('Connection error. Check your internet.');
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: const Text(
          'Uber Clone',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // ===== TAB TOGGLE =====
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isLogin
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isLogin ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Register',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isLogin ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ===== LOGIN FORM =====
              if (_isLogin) ...[
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ]

              // ===== REGISTER FORM =====
              else ...[
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 16),

                // Role selection
                Text(
                  'Select Role',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'RIDER'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'RIDER'
                                ? const Color(0xFF6366F1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'RIDER'
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person,
                                color: _selectedRole == 'RIDER'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rider',
                                style: TextStyle(
                                  color: _selectedRole == 'RIDER'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'DRIVER'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'DRIVER'
                                ? const Color(0xFF6366F1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'DRIVER'
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: _selectedRole == 'DRIVER'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Driver',
                                style: TextStyle(
                                  color: _selectedRole == 'DRIVER'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],

              const SizedBox(height: 32),

              // Server URL settings
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    _showServerUrlDialog();
                  },
                  child: const Text('Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show server URL dialog
  void _showServerUrlDialog() {
    final urlController =
        TextEditingController(text: StorageService.getServerUrl());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'https://your-ngrok-url.ngrok-free.dev',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.setServerUrl(urlController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server URL updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}