import 'package:flutter/material.dart';
import '../utils/document_status_style.dart';

class DocumentStatusChip extends StatelessWidget {
  final String? status;

  const DocumentStatusChip({super.key, this.status});

  @override
  Widget build(BuildContext context) {
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
}
