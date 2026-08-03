import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/user_avatar.dart';

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
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late String _token;
  String _selectedGender = 'PREFER_NOT_TO_SAY';
  String? _countryCode;
  String? _photoUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedGender = widget.user?.gender ?? StorageService.getGender() ?? 'PREFER_NOT_TO_SAY';
    _countryCode = widget.user?.countryCode ?? '+966';
    _photoUrl = widget.user?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = widget.user?.id ?? StorageService.getUserId();
      if (userId == null) return;

      final body = <String, String>{
        'fullName': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'countryCode': _countryCode ?? '+966',
        'gender': _selectedGender,
      };

      final currentPw = _currentPasswordController.text;
      final newPw = _newPasswordController.text;
      final confirmPw = _confirmPasswordController.text;
      if (currentPw.isNotEmpty || newPw.isNotEmpty || confirmPw.isNotEmpty) {
        body['currentPassword'] = currentPw;
        body['newPassword'] = newPw;
        body['confirmPassword'] = confirmPw;
      }

      final response = await http.put(
        Uri.parse('${StorageService.getServerUrl()}/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final refreshedToken = data['token'];
        if (refreshedToken is String && refreshedToken.isNotEmpty) {
          _token = refreshedToken;
          await StorageService.saveToken(refreshedToken);
        }
        if (data['gender'] is String) {
          await StorageService.saveGender(data['gender'] as String);
        }
        if (data['photoUrl'] is String) {
          _photoUrl = data['photoUrl'] as String;
        }
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileUpdated)),
        );
      } else {
        String message = 'Failed to update profile';
        if (response.statusCode == 400 || response.statusCode == 401) {
          try {
            final error = jsonDecode(response.body) as Map<String, dynamic>;
            if (error['message'] is String) message = error['message'] as String;
          } catch (_) {}
        }
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty ? picked.name : 'profile_photo.png';
      if (!mounted) return;
      setState(() => _isUploading = true);
      final uploadedUrl = await PhotoService.uploadPhoto(bytes, filename, _token);
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        if (uploadedUrl != null) {
          _photoUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo upload failed. Please try again.')),
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    if (_photoUrl == null) return;
    if (!mounted) return;
    setState(() => _isUploading = true);
    final ok = await PhotoService.deletePhoto(_token);
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (ok) _photoUrl = null;
    });
  }

  void _showPhotoOptions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTopRadius,
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.profilePhoto,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(l10n.removePhoto, style: const TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        centerTitle: true,
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  photoUrl: PhotoService.resolvePhotoUrl(_photoUrl),
                  displayName: widget.user?.fullName ?? 'U',
                  radius: 48,
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _showPhotoOptions,
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
          AppSpacing.gapXxl,
          _buildField(l10n.fullName, _nameController, Icons.person_outline),
          AppSpacing.gapLg,
          _buildField(l10n.email, _emailController, Icons.email_outlined),
          AppSpacing.gapLg,
          _buildPhoneField(l10n),
          AppSpacing.gapXl,
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapSm,
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'MALE', label: Text(l10n.male)),
              ButtonSegment(value: 'FEMALE', label: Text(l10n.female)),
              ButtonSegment(value: 'PREFER_NOT_TO_SAY', label: Text(l10n.preferNotToSay)),
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
          AppSpacing.gapXxl,
          const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapMd,
          PremiumTextField(
            controller: _currentPasswordController,
            label: 'Current Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          AppSpacing.gapMd,
          PremiumTextField(
            controller: _newPasswordController,
            label: 'New Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          AppSpacing.gapMd,
          PremiumTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          AppSpacing.gapXxl,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
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

  Widget _buildPhoneField(l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: (code) => setState(() => _countryCode = code.dialCode ?? '+966'),
            initialSelection: CountryCode.fromDialCode(_countryCode ?? '+966').code ?? 'US',
            favorite: const ['+966', '+971', '+1'],
            showFlagDialog: true,
            alignLeft: false,
            textStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
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
        border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
