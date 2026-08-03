import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/driver_documents_panel.dart';
import '../widgets/premium_button.dart';

class DriverDocumentsScreen extends StatefulWidget {
  final String token;
  final String? verificationStatus;

  const DriverDocumentsScreen({
    super.key,
    required this.token,
    this.verificationStatus,
  });

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  late String? _verificationStatus;
  bool _ready = false;
  bool _submitting = false;

  bool get _canSubmit => _verificationStatus == 'DRAFT' || _verificationStatus == 'REJECTED';

  @override
  void initState() {
    super.initState();
    _verificationStatus = widget.verificationStatus;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await DriverService.submitDriver(widget.token);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (result.ok) _verificationStatus = result.verificationStatus ?? 'PENDING';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? 'Profile submitted for verification'
              : result.message ?? 'Submission failed',
        ),
        backgroundColor: result.ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Documents & Verification',
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
            colors: [AppColors.accentContainer, AppColors.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 16),
              DriverDocumentsPanel(
                token: widget.token,
                verificationStatus: _verificationStatus,
                onReadinessChanged: (ready) {
                  if (mounted) setState(() => _ready = ready);
                },
              ),
              const SizedBox(height: 20),
              if (_canSubmit)
                PremiumButton(
                  label: 'Submit for Verification',
                  icon: Icons.verified_outlined,
                  onPressed: (_ready && !_submitting) ? _submit : null,
                  isLoading: _submitting,
                  variant: ButtonVariant.success,
                  height: 52,
                )
              else if (_verificationStatus == 'PENDING')
                _buildStatusNote(
                  icon: Icons.schedule,
                  color: AppColors.warning,
                  text: 'Your profile is under review. You will be able to go online once approved.',
                )
              else if (_verificationStatus == 'APPROVED')
                _buildStatusNote(
                  icon: Icons.verified,
                  color: AppColors.success,
                  text: 'Your documents are approved. You are verified and can go online.',
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final info = switch (_verificationStatus) {
      'PENDING' => (Icons.schedule, AppColors.warning, 'Pending Review'),
      'APPROVED' => (Icons.verified, AppColors.success, 'Approved'),
      'REJECTED' => (Icons.cancel_outlined, AppColors.error, 'Rejected — fix documents and resubmit'),
      _ => (Icons.edit_outlined, AppColors.textTertiary, 'Draft'),
    };
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: info.$2.withValues(alpha: 0.1),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: info.$2.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(info.$1, size: 20, color: info.$2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              info.$3,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: info.$2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusNote({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
