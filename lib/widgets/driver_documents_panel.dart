import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/driver_document.dart';
import '../services/driver_service.dart';
import '../services/expiry_config_service.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/document_status_style.dart';
import '../widgets/premium_button.dart';

class DriverDocumentsPanel extends StatefulWidget {
  final String token;
  final String? verificationStatus;
  final void Function(bool ready)? onReadinessChanged;

  const DriverDocumentsPanel({
    super.key,
    required this.token,
    this.verificationStatus,
    this.onReadinessChanged,
  });

  @override
  State<DriverDocumentsPanel> createState() => _DriverDocumentsPanelState();
}

class _DriverDocumentsPanelState extends State<DriverDocumentsPanel> {
  List<DriverDocument> _docs = [];
  DocumentCompleteness? _completeness;
  String? _avatarUrl;
  bool _loading = true;
  final Map<String, bool> _uploading = {};

  bool get _isReady => _completeness?.readyForSubmission ?? false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await ExpiryConfigService.load(token: widget.token);
    final docs = await DriverService.getDriverDocuments(widget.token);
    final completeness = await DriverService.getDocumentCompleteness(widget.token);
    final profile = await DriverService.getDriverProfile(widget.token);
    if (!mounted) return;
    setState(() {
      _docs = docs;
      _completeness = completeness;
      _avatarUrl = profile?.photoUrl;
      _loading = false;
    });
    widget.onReadinessChanged?.call(_isReady);
  }

  Future<void> _pickAndUpload(String type) async {
    if (_uploading[type] == true) return;
    final source = await _chooseSource();
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final details = await _promptDocumentDetails();
    if (details == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final filename = picked.name.isNotEmpty ? picked.name : '$type.png';
    setState(() => _uploading[type] = true);
    final result = await DriverService.uploadDriverDocument(
      documentType: type,
      bytes: bytes,
      filename: filename,
      token: widget.token,
      issueDate: details.issueDate,
      expiryDate: details.expiryDate,
      documentNumber: details.documentNumber,
    );
    if (!mounted) return;
    setState(() => _uploading[type] = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result != null
            ? '${driverDocumentTypeLabel(type)} uploaded'
            : 'Upload failed. Please try again.'),
        backgroundColor: result != null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _refresh();
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<({String? issueDate, String? expiryDate, String? documentNumber})?>
      _promptDocumentDetails() async {
    final issueCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    final result = await showDialog<({String issueDate, String expiryDate, String documentNumber})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Optional document details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: issueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Issue date (yyyy-MM-dd)',
                  hintText: 'e.g. 2026-01-15',
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: expiryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expiry date (yyyy-MM-dd)',
                  hintText: 'e.g. 2028-01-15',
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: numCtrl,
                decoration: const InputDecoration(
                  labelText: 'Document number',
                  hintText: 'Optional',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              (
                issueDate: issueCtrl.text.trim(),
                expiryDate: expiryCtrl.text.trim(),
                documentNumber: numCtrl.text.trim(),
              ),
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    if (result == null) return null;
    return (
      issueDate: result.issueDate.isEmpty ? null : result.issueDate,
      expiryDate: result.expiryDate.isEmpty ? null : result.expiryDate,
      documentNumber: result.documentNumber.isEmpty ? null : result.documentNumber,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _deleteDocument(DriverDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Remove ${driverDocumentTypeLabel(doc.documentType)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await DriverService.deleteDriverDocument(doc.id, widget.token);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Document deleted' : 'Delete failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _refresh();
  }

  DriverDocument? _docOf(String type) {
    for (final d in _docs) {
      if (d.documentType == type) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_loading) _buildAvatarStatusCard(),
        if (!_loading) _buildExpiryBanner(),
        if (!_loading && _completeness != null) _buildCompletenessCard(),
        const SizedBox(height: 16),
        Text(
          'Documents',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else
          ...kDriverDocumentTypes.map((type) => _buildDocumentTile(type)),
      ],
    );
  }

  DateTime? _tryParseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isExpiredDoc(DriverDocument d) {
    final e = _tryParseDate(d.expiryDate);
    if (e == null) return false;
    return !e.isAfter(_today());
  }

  bool _isSoonExpiringDoc(DriverDocument d) {
    final e = _tryParseDate(d.expiryDate);
    if (e == null || _isExpiredDoc(d)) return false;
    return e.isBefore(_today().add(const Duration(days: 31)));
  }

  Widget _buildAvatarStatusCard() {
    final pp = _docOf('PROFILE_PHOTO');
    final underReview = pp != null && (pp.status == 'PENDING' || pp.status == 'REUPLOAD_REQUESTED');
    if (!underReview || _avatarUrl == null) return const SizedBox.shrink();
    final avatarUrl = PhotoService.resolvePhotoUrl(_avatarUrl);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.person, color: AppColors.textTertiary),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.person, color: AppColors.textTertiary),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.person, color: AppColors.textTertiary),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Current profile photo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Approved',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'New profile photo under review · submitted ${_formatDate(pp.uploadedAt)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your current approved photo stays visible everywhere until the new one is approved.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner() {
    final expired = _docs.where(_isExpiredDoc).toList();
    final soon = _docs.where(_isSoonExpiringDoc).toList();
    final banners = <Widget>[];
    if (expired.isNotEmpty) {
      banners.add(_bannerItem(
        icon: Icons.error_outline,
        color: AppColors.error,
        text: 'Expired: ${expired.map((d) => '${driverDocumentTypeLabel(d.documentType)} (${_formatDate(d.expiryDate)})').join(', ')}',
      ));
    }
    if (soon.isNotEmpty) {
      banners.add(_bannerItem(
        icon: Icons.warning_amber_outlined,
        color: AppColors.warning,
        text: 'Expiring soon: ${soon.map((d) => '${driverDocumentTypeLabel(d.documentType)} (${_formatDate(d.expiryDate)})').join(', ')}',
      ));
    }
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: banners),
    );
  }

  Widget _bannerItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessCard() {
    final c = _completeness!;
    final fraction = c.required == 0 ? 0.0 : (c.uploaded / c.required).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: _isReady ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: _isReady
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isReady ? Icons.check_circle : Icons.incomplete_circle_outlined,
                size: 20,
                color: _isReady ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isReady
                      ? 'All required documents uploaded'
                      : 'Required documents: ${c.uploaded} of ${c.required}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.outline.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                _isReady ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          if (c.missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Missing: ${c.missing.map(driverDocumentTypeLabel).join(', ')}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String type) {
    final doc = _docOf(type);
    final uploading = _uploading[type] == true;
    final isApproved = doc?.status == 'APPROVED';
    final label = driverDocumentTypeLabel(type);
    final isRequired = type != 'VEHICLE_PHOTO';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(type), size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc != null ? (doc.fileName ?? 'Uploaded') : 'Not uploaded',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (doc != null) _buildStatusChip(doc.status),
            ],
          ),
          if (doc != null) ...[
            const SizedBox(height: 10),
            _buildMetaRow('Uploaded', _formatDate(doc.uploadedAt)),
            _buildMetaRow('Expires', _formatDate(doc.expiryDate),
                valueColor: documentExpiryColor(_tryParseDate(doc.expiryDate),
                    soonDays: ExpiryConfigService.soonDays)),
            if (doc.reviewedAt != null) _buildMetaRow('Reviewed', _formatDate(doc.reviewedAt)),
            if (doc.reviewedBy != null) _buildMetaRow('Reviewed by', 'Admin #${doc.reviewedBy}'),
            if (doc.documentNumber != null && doc.documentNumber!.isNotEmpty)
              _buildMetaRow('Document no.', doc.documentNumber!),
          ],
          if (!isRequired)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Optional (used for the vehicle photo on your profile)',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: uploading
                      ? 'Uploading…'
                      : doc != null
                          ? 'Replace'
                          : 'Upload',
                  onPressed: uploading || isApproved ? null : () => _pickAndUpload(type),
                  isLoading: uploading,
                  icon: Icons.upload_file,
                  variant: ButtonVariant.outline,
                  height: 44,
                  borderRadius: 12,
                ),
              ),
              if (doc != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: isApproved ? 'Approved — locked' : 'Delete',
                  onPressed: uploading || isApproved ? null : () => _deleteDocument(doc),
                  icon: const Icon(Icons.delete_outline, color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
          if (isApproved) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.textTertiary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Approved by admin — request a re-upload to change this document.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final info = documentStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 12, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: info.color),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'PROFILE_PHOTO' => Icons.face,
      'LICENSE' => Icons.credit_card,
      'VEHICLE_REGISTRATION' => Icons.description_outlined,
      'VEHICLE_PHOTO' => Icons.directions_car,
      'INSURANCE' => Icons.shield_outlined,
      'NATIONAL_ID' => Icons.badge_outlined,
      _ => Icons.description_outlined,
    };
  }
}
