import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../screens/debug_screen.dart';
import '../screens/driver_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';

class DriverRegistrationScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String token;

  const DriverRegistrationScreen({
    Key? key,
    required this.userId,
    required this.username,
    required this.token,
  }) : super(key: key);

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _licenseController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  String _selectedVehicleType = 'CAR';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

Future<void> _checkExistingProfile() async {
  try {
    addDebugMessage('🔍 Checking for existing driver profile...');
    final profile = await DriverService.getDriverProfile(widget.token);

    if (profile != null) {
      addDebugMessage('✅ Driver profile already exists!');
      addDebugMessage('Name: ${profile.user.fullName}');
      addDebugMessage('Vehicle: ${profile.vehicleModel}');
      addDebugMessage('🔄 Navigating to DriverHomeScreen...');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverHomeScreen(
              userId: widget.userId,
              username: widget.username,
              token: widget.token,
            ),
          ),
        );
      }
    } else {
      addDebugMessage('⚠️ No existing profile - show registration form');
    }
  } catch (e) {
    addDebugMessage('⚠️ Profile check error: $e');
  }
}

  Future<void> _registerDriver() async {
  if (_licenseController.text.isEmpty ||
      _vehicleNumberController.text.isEmpty ||
      _vehicleModelController.text.isEmpty ||
      _vehicleColorController.text.isEmpty) {
    _showError('Please fill all fields');
    return;
  }

  setState(() => _isLoading = true);
  try {
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 DRIVER REGISTRATION REQUEST');
    addDebugMessage('License: ${_licenseController.text}');
    addDebugMessage('Vehicle: ${_vehicleModelController.text}');

    final result = await DriverService.registerAsDriver(
      licenseNumber: _licenseController.text,
      vehicleNumber: _vehicleNumberController.text,
      vehicleType: _selectedVehicleType,
      vehicleModel: _vehicleModelController.text,
      vehicleColor: _vehicleColorController.text,
      token: widget.token,
    );

    addDebugMessage('Registration result: $result');

    if (result) {
      _showSuccess('Driver profile registered!');

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverHomeScreen(
              userId: widget.userId,
              username: widget.username,
              token: widget.token,
            ),
          ),
        );
      }
    } else {
      addDebugMessage('❌ Registration failed - profile might already exist');
      _showError('Driver profile registration failed. You may already be registered.');

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DriverHomeScreen(
              userId: widget.userId,
              username: widget.username,
              token: widget.token,
            ),
          ),
        );
      }
    }
  } catch (e) {
    addDebugMessage('❌ Exception: $e');
    _showError('Error: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Become a Driver',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F5),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.gapXxl,
              const Text(
                'Driver Registration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm,
              const Text(
                'Enter your details to start earning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXxxl,
              PremiumTextField(
                controller: _licenseController,
                label: 'License Number',
                hint: 'e.g., DL123456789',
                prefixIcon: Icons.credit_card,
              ),
              AppSpacing.gapLg,
              PremiumTextField(
                controller: _vehicleNumberController,
                label: 'Vehicle Number',
                hint: 'e.g., ABC-1234',
                prefixIcon: Icons.directions_car,
              ),
              AppSpacing.gapLg,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedVehicleType.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.outline,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  items: const [
                    DropdownMenuItem(value: 'CAR', child: Text('Car')),
                    DropdownMenuItem(value: 'BIKE', child: Text('Bike')),
                    DropdownMenuItem(value: 'VAN', child: Text('Van')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedVehicleType = value ?? 'CAR');
                  },
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: const Icon(
                      Icons.category,
                      color: AppColors.textTertiary,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapLg,
              PremiumTextField(
                controller: _vehicleModelController,
                label: 'Vehicle Model',
                hint: 'e.g., Toyota Camry',
                prefixIcon: Icons.info_outline,
              ),
              AppSpacing.gapLg,
              PremiumTextField(
                controller: _vehicleColorController,
                label: 'Vehicle Color',
                hint: 'e.g., White',
                prefixIcon: Icons.palette_outlined,
              ),
              AppSpacing.gapXxxl,
              PremiumButton(
                label: 'Submit Registration',
                onPressed: _isLoading ? null : _registerDriver,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }
}
