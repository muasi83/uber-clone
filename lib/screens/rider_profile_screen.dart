import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../services/storage_service.dart';

class RiderProfileScreen extends StatefulWidget {
  final User? user;
  final String token;

  const RiderProfileScreen({
    super.key,
    this.user,
    required this.token,
  });

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedGender = 'PREFER_NOT_TO_SAY';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _selectedGender = widget.user?.gender ?? StorageService.getGender() ?? 'PREFER_NOT_TO_SAY';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = widget.user?.id ?? StorageService.getUserId();
      if (userId == null) return;

      final response = await http.put(
        Uri.parse('${StorageService.getServerUrl()}/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': _nameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
          'gender': _selectedGender,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('token')) {
          await StorageService.saveToken(data['token'] as String);
        }
        if (data.containsKey('gender')) {
          await StorageService.saveGender(data['gender'] as String);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera — requires image_picker package')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gallery — requires image_picker package')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.user?.fullName ?? 'U').isNotEmpty
        ? (widget.user?.fullName ?? 'U')[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: AppColors.textOnPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 16),
          _buildField('Email', _emailController, Icons.email_outlined),
          const SizedBox(height: 16),
          _buildField('Phone', _phoneController, Icons.phone_outlined),
          if (widget.user?.countryCode != null) ...[
            const SizedBox(height: 4),
            Text(
              'Country Code: ${widget.user!.countryCode}',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'MALE', label: Text('Male')),
              ButtonSegment(value: 'FEMALE', label: Text('Female')),
              ButtonSegment(value: 'PREFER_NOT_TO_SAY', label: Text('Prefer not to say')),
            ],
            selected: {_selectedGender},
            onSelectionChanged: (value) {
              setState(() => _selectedGender = value.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                    )
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
