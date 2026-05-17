import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../screens/debug_screen.dart';
import '../screens/driver_home_screen.dart';

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
      
      // Add small delay to ensure UI is ready
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
    // Continue to show registration form even if check fails
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
      
      // Small delay to show success message
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
      
      // Try to navigate to home anyway
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        title: const Text('Complete Driver Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.directions_car,
                size: 60,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Driver Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your driver details to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // License Number
            TextField(
              controller: _licenseController,
              decoration: InputDecoration(
                labelText: 'License Number',
                hintText: 'e.g., DL123456789',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Vehicle Number
            TextField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number (Plate)',
                hintText: 'e.g., ABC-1234',
                prefixIcon: const Icon(Icons.directions_car),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Vehicle Type
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              items: const [
                DropdownMenuItem(value: 'CAR', child: Text('🚗 Car')),
                DropdownMenuItem(value: 'BIKE', child: Text('🏍️ Bike')),
                DropdownMenuItem(value: 'VAN', child: Text('🚐 Van')),
              ],
              onChanged: (value) {
                setState(() => _selectedVehicleType = value ?? 'CAR');
              },
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Vehicle Model
            TextField(
              controller: _vehicleModelController,
              decoration: InputDecoration(
                labelText: 'Vehicle Model',
                hintText: 'e.g., Toyota Camry',
                prefixIcon: const Icon(Icons.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Vehicle Color
            TextField(
              controller: _vehicleColorController,
              decoration: InputDecoration(
                labelText: 'Vehicle Color',
                hintText: 'e.g., White',
                prefixIcon: const Icon(Icons.palette),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _registerDriver,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      'Complete Registration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your profile will be verified by our admin team. You can start accepting rides after verification.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
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