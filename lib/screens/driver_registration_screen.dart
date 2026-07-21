import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../screens/debug_screen.dart';
import '../screens/driver_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';
import '../services/recorded_screen_mixin.dart';

class DriverRegistrationScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String token;

  const DriverRegistrationScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.token,
  });

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

enum _RegStep { personalInfo, vehicleInfo, review }

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> with RecordedScreenMixin<DriverRegistrationScreen> {
  _RegStep _currentStep = _RegStep.personalInfo;
  final _licenseController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  String _selectedVehicleType = 'CAR';
  bool _isLoading = false;

  int get _currentStepIndex => _RegStep.values.indexOf(_currentStep);
  bool get _isFirstStep => _currentStep == _RegStep.personalInfo;
  bool get _isLastStep => _currentStep == _RegStep.review;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'DRIVER_REGISTRATION_STARTED');
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

  recordEvent(eventName: 'DRIVER_REGISTRATION_SUBMITTED');
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
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Semantics(
          label: 'Go back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
            onPressed: _isFirstStep
                ? () => Navigator.of(context).pop()
                : () => setState(() => _currentStep = _RegStep.values[_currentStepIndex - 1]),
          ),
        ),
        title: Semantics(
          label: 'Registration step ${_currentStepIndex + 1} of 3',
          child: const Text(
            'Become a Driver',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
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
              AppColors.accentContainer,
              AppColors.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.gapXl,
                    _buildStepIcon(),
                    AppSpacing.gapXxl,
                    _buildStepTitle(),
                    AppSpacing.gapSm,
                    _buildStepSubtitle(),
                    AppSpacing.gapXxxl,
                    _buildStepContent(),
                    AppSpacing.gapXl,
                    _buildNavButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Semantics(
      label: 'Step ${_currentStepIndex + 1} of 3',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
        child: Row(
          children: List.generate(_RegStep.values.length, (index) {
            final isActive = index == _currentStepIndex;
            final isCompleted = index < _currentStepIndex;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : isActive
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 18, color: AppColors.primaryLight)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive ? AppColors.primaryLight : AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  if (index < _RegStep.values.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted || isActive ? AppColors.primary : AppColors.outline,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepIcon() {
    final icon = switch (_currentStep) {
      _RegStep.personalInfo => Icons.credit_card,
      _RegStep.vehicleInfo => Icons.directions_car,
      _RegStep.review => Icons.checklist,
    };
    return Semantics(
      label: 'Step icon',
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 48, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildStepTitle() {
    final title = switch (_currentStep) {
      _RegStep.personalInfo => 'Personal Information',
      _RegStep.vehicleInfo => 'Vehicle Information',
      _RegStep.review => 'Review & Submit',
    };
    return Semantics(
      label: title,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStepSubtitle() {
    final subtitle = switch (_currentStep) {
      _RegStep.personalInfo => 'Enter your driving license details',
      _RegStep.vehicleInfo => 'Tell us about your vehicle',
      _RegStep.review => 'Verify your information before submitting',
    };
    return Text(
      subtitle,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      _RegStep.personalInfo => _buildPersonalInfoStep(),
      _RegStep.vehicleInfo => _buildVehicleInfoStep(),
      _RegStep.review => _buildReviewStep(),
    };
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        Semantics(
          label: 'License number input',
          child: PremiumTextField(
            controller: _licenseController,
            label: 'License Number',
            hint: 'e.g., DL123456789',
            prefixIcon: Icons.credit_card,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfoStep() {
    return Column(
      children: [
        Semantics(
          label: 'Vehicle number input',
          child: PremiumTextField(
            controller: _vehicleNumberController,
            label: 'Vehicle Number',
            hint: 'e.g., ABC-1234',
            prefixIcon: Icons.directions_car,
          ),
        ),
        AppSpacing.gapLg,
        Semantics(
          label: 'Vehicle type selection, selected $_selectedVehicleType',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: _selectedVehicleType.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.outline,
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedVehicleType,
              items: const [
                DropdownMenuItem(value: 'CAR', child: Text('Car')),
                DropdownMenuItem(value: 'BIKE', child: Text('Bike')),
                DropdownMenuItem(value: 'VAN', child: Text('Van')),
              ],
              onChanged: (value) {
                setState(() => _selectedVehicleType = value ?? 'CAR');
              },
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                prefixIcon: Icon(
                  Icons.category,
                  color: AppColors.textTertiary,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        AppSpacing.gapLg,
        Semantics(
          label: 'Vehicle model input',
          child: PremiumTextField(
            controller: _vehicleModelController,
            label: 'Vehicle Model',
            hint: 'e.g., Toyota Camry',
            prefixIcon: Icons.info_outline,
          ),
        ),
        AppSpacing.gapLg,
        Semantics(
          label: 'Vehicle color input',
          child: PremiumTextField(
            controller: _vehicleColorController,
            label: 'Vehicle Color',
            hint: 'e.g., White',
            prefixIcon: Icons.palette_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Semantics(
      label: 'Review your details',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: const BorderSide(color: AppColors.outline),
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('License', _licenseController.text),
              const Divider(height: 1, color: AppColors.outline),
              _buildReviewRow('Vehicle Number', _vehicleNumberController.text),
              const Divider(height: 1, color: AppColors.outline),
              _buildReviewRow('Vehicle Type', _selectedVehicleType),
              const Divider(height: 1, color: AppColors.outline),
              _buildReviewRow('Vehicle Model', _vehicleModelController.text),
              const Divider(height: 1, color: AppColors.outline),
              _buildReviewRow('Vehicle Color', _vehicleColorController.text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Column(
      children: [
        if (!_isLastStep)
          Semantics(
            label: 'Next step',
            child: PremiumButton(
              label: 'Continue',
              onPressed: _goToNextStep,
              icon: Icons.arrow_forward,
            ),
          )
        else
          Semantics(
            label: 'Submit registration',
            child: PremiumButton(
              label: 'Submit Registration',
              onPressed: _isLoading ? null : _registerDriver,
              isLoading: _isLoading,
              icon: Icons.check_circle_outline,
            ),
          ),
        if (!_isFirstStep) ...[
          AppSpacing.gapMd,
          Semantics(
            label: 'Previous step',
            child: TextButton(
              onPressed: () => setState(() => _currentStep = _RegStep.values[_currentStepIndex - 1]),
              child: const Text(
                'Back',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _goToNextStep() {
    if (_currentStep == _RegStep.personalInfo && _licenseController.text.isEmpty) {
      _showError('Please enter your license number');
      return;
    }
    if (_currentStep == _RegStep.vehicleInfo) {
      if (_vehicleNumberController.text.isEmpty ||
          _vehicleModelController.text.isEmpty ||
          _vehicleColorController.text.isEmpty) {
        _showError('Please fill all vehicle fields');
        return;
      }
    }
    setState(() => _currentStep = _RegStep.values[_currentStepIndex + 1]);
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
