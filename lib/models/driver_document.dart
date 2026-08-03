const List<String> kDriverDocumentTypes = [
  'PROFILE_PHOTO',
  'LICENSE',
  'VEHICLE_REGISTRATION',
  'VEHICLE_PHOTO',
  'INSURANCE',
  'NATIONAL_ID',
];

const Map<String, String> kDriverDocumentTypeLabels = {
  'PROFILE_PHOTO': 'Profile Photo',
  'LICENSE': 'Driving License',
  'VEHICLE_REGISTRATION': 'Vehicle Registration',
  'VEHICLE_PHOTO': 'Vehicle Photo',
  'INSURANCE': 'Insurance',
  'NATIONAL_ID': 'National ID',
};

String driverDocumentTypeLabel(String? type) {
  if (type == null) return 'Document';
  return kDriverDocumentTypeLabels[type] ?? type;
}

class DriverDocument {
  final int id;
  final int? driverId;
  final String? documentType;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? status;
  final String? adminNote;
  final String? issueDate;
  final String? expiryDate;
  final String? documentNumber;
  final String? uploadedAt;
  final String? reviewedAt;
  final int? reviewedBy;

  const DriverDocument({
    required this.id,
    this.driverId,
    this.documentType,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.status,
    this.adminNote,
    this.issueDate,
    this.expiryDate,
    this.documentNumber,
    this.uploadedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      driverId: (json['driverId'] as num?)?.toInt(),
      documentType: json['documentType'] as String?,
      fileName: json['fileName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      status: json['status'] as String?,
      adminNote: json['adminNote'] as String?,
      issueDate: json['issueDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      documentNumber: json['documentNumber'] as String?,
      uploadedAt: json['uploadedAt'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      reviewedBy: (json['reviewedBy'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'status': status,
      'adminNote': adminNote,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'documentNumber': documentNumber,
      'uploadedAt': uploadedAt,
      'reviewedAt': reviewedAt,
      'reviewedBy': reviewedBy,
    };
  }
}

class DocumentCompleteness {
  final int required;
  final int uploaded;
  final List<String> missing;
  final bool readyForSubmission;

  const DocumentCompleteness({
    required this.required,
    required this.uploaded,
    required this.missing,
    required this.readyForSubmission,
  });

  factory DocumentCompleteness.fromJson(Map<String, dynamic> json) {
    final rawMissing = json['missing'];
    return DocumentCompleteness(
      required: (json['required'] as num?)?.toInt() ?? 0,
      uploaded: (json['uploaded'] as num?)?.toInt() ?? 0,
      missing: rawMissing is List
          ? rawMissing.whereType<String>().toList()
          : const [],
      readyForSubmission: json['readyForSubmission'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'required': required,
      'uploaded': uploaded,
      'missing': missing,
      'readyForSubmission': readyForSubmission,
    };
  }
}
