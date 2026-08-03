import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/driver_document.dart';
import '../services/admin_drivers_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'document_status_chip.dart';
import 'premium_button.dart';

class AdminDocumentViewer extends StatefulWidget {
  final int driverId;
  final int documentId;
  final DriverDocument document;
  final String token;

  const AdminDocumentViewer({
    super.key,
    required this.driverId,
    required this.documentId,
    required this.document,
    required this.token,
  });

  @override
  State<AdminDocumentViewer> createState() => _AdminDocumentViewerState();
}

class _AdminDocumentViewerState extends State<AdminDocumentViewer> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _busy = false;

  bool get _isPdf {
    final name = widget.document.fileName?.toLowerCase() ?? '';
    final mime = widget.document.mimeType?.toLowerCase() ?? '';
    return name.endsWith('.pdf') || mime.contains('pdf');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bytes =
        await AdminDriversService.fetchDocumentFile(widget.driverId, widget.documentId, widget.token);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  Future<void> _review(String action, String successLabel) async {
    if (_busy) return;
    final details = await _promptReviewDetails();
    if (details == null || !mounted) return;

    setState(() => _busy = true);
    final result = await AdminDriversService.reviewDocument(
      widget.driverId,
      widget.documentId,
      action,
      widget.token,
      adminNote: details.adminNote,
      issueDate: details.issueDate,
      expiryDate: details.expiryDate,
      documentNumber: details.documentNumber,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successLabel),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).failedToLoadDrivers),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<({String adminNote, String issueDate, String expiryDate, String documentNumber})?>
      _promptReviewDetails() async {
    final l10n = AppLocalizations.of(context);
    final d = widget.document;
    final noteCtrl = TextEditingController(text: d.adminNote ?? '');
    final issueCtrl = TextEditingController(text: d.issueDate ?? '');
    final expiryCtrl = TextEditingController(text: d.expiryDate ?? '');
    final numCtrl = TextEditingController(text: d.documentNumber ?? '');
    final result = await showDialog<({String adminNote, String issueDate, String expiryDate, String documentNumber})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminNote),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(hintText: l10n.noteHint),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: issueCtrl,
                decoration: InputDecoration(labelText: l10n.issueDate, hintText: 'yyyy-MM-dd'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: expiryCtrl,
                decoration: InputDecoration(labelText: l10n.expiresOn, hintText: 'yyyy-MM-dd'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: numCtrl,
                decoration: InputDecoration(labelText: l10n.documentNumber),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              (
                adminNote: noteCtrl.text.trim(),
                issueDate: issueCtrl.text.trim(),
                expiryDate: expiryCtrl.text.trim(),
                documentNumber: numCtrl.text.trim(),
              ),
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return result;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = widget.document;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('${driverDocumentTypeLabel(d.documentType)} · ${l10n.documentReviewTitle}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageArea(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.lgRadius,
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_bytes == null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.lgRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 10),
            Text(
              l10n.noDocuments,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_isPdf) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.lgRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 56, color: AppColors.error),
            const SizedBox(height: 10),
            Text(
              widget.document.fileName ?? 'PDF',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 420,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.memory(
            _bytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 10),
                Text(
                  l10n.noDocuments,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final d = widget.document;
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  driverDocumentTypeLabel(d.documentType),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                DocumentStatusChip(status: d.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow(l10n.uploadedOn, _formatDate(d.uploadedAt)),
            _buildRow(l10n.issueDate, _formatDate(d.issueDate)),
            _buildRow(l10n.expiresOn, _formatDate(d.expiryDate)),
            _buildRow(l10n.documentNumber, d.documentNumber ?? '-'),
            _buildRow(l10n.reviewedAt, _formatDate(d.reviewedAt)),
            _buildRow(l10n.reviewedBy, d.reviewedBy != null ? 'Admin #${d.reviewedBy}' : '-'),
            if (d.adminNote != null && d.adminNote!.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.outline),
              Text(
                '${l10n.adminNote}: ${d.adminNote}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: l10n.requestReupload,
                    icon: Icons.refresh,
                    variant: ButtonVariant.outline,
                    height: 46,
                    borderRadius: 12,
                    isLoading: _busy,
                    onPressed: _busy ? null : () => _review('request-reupload', l10n.requestReupload),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PremiumButton(
                    label: l10n.rejectDocument,
                    icon: Icons.cancel_outlined,
                    variant: ButtonVariant.danger,
                    height: 46,
                    borderRadius: 12,
                    isLoading: _busy,
                    onPressed: _busy ? null : () => _review('reject', l10n.rejected),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PremiumButton(
              label: l10n.approveDocument,
              icon: Icons.verified_outlined,
              variant: ButtonVariant.success,
              height: 46,
              borderRadius: 12,
              isLoading: _busy,
              onPressed: _busy ? null : () => _review('approve', l10n.approved),
            ),
          ],
        ),
      ),
    );
  }
}
