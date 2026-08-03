import 'package:chat_app/models/driver_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3C2 — document types', () {
    test('defines exactly the six backend document types', () {
      expect(kDriverDocumentTypes, [
        'PROFILE_PHOTO',
        'LICENSE',
        'VEHICLE_REGISTRATION',
        'VEHICLE_PHOTO',
        'INSURANCE',
        'NATIONAL_ID',
      ]);
    });

    test('labels every backend type', () {
      for (final type in kDriverDocumentTypes) {
        expect(kDriverDocumentTypeLabels[type], isNotNull);
        expect(kDriverDocumentTypeLabels[type], isNotEmpty);
      }
    });

    test('label falls back to raw type for unknown values', () {
      expect(driverDocumentTypeLabel('UNKNOWN_TYPE'), 'UNKNOWN_TYPE');
      expect(driverDocumentTypeLabel(null), 'Document');
    });
  });

  group('Phase 3C2 — DriverDocument parsing', () {
    test('fromJson parses all fields', () {
      final d = DriverDocument.fromJson({
        'id': 31,
        'driverId': 22,
        'documentType': 'LICENSE',
        'fileName': 'license.jpg',
        'fileUrl': '/uploads/documents/22/22_abc.jpg',
        'fileSize': 102400,
        'mimeType': 'image/jpeg',
        'status': 'PENDING',
        'adminNote': null,
        'issueDate': '2026-01-01',
        'expiryDate': '2030-01-01',
        'documentNumber': 'DL123456789',
        'uploadedAt': '2026-08-02T10:00:00',
      });
      expect(d.id, 31);
      expect(d.driverId, 22);
      expect(d.documentType, 'LICENSE');
      expect(d.fileName, 'license.jpg');
      expect(d.fileUrl, '/uploads/documents/22/22_abc.jpg');
      expect(d.fileSize, 102400);
      expect(d.mimeType, 'image/jpeg');
      expect(d.status, 'PENDING');
      expect(d.documentNumber, 'DL123456789');
    });

    test('toJson round-trips', () {
      final d = DriverDocument.fromJson({
        'id': 32,
        'driverId': 22,
        'documentType': 'VEHICLE_PHOTO',
        'fileName': 'car.png',
        'fileUrl': '/uploads/documents/22/22_car.png',
        'fileSize': 2048,
        'mimeType': 'image/png',
        'status': 'APPROVED',
      });
      final json = d.toJson();
      expect(json['documentType'], 'VEHICLE_PHOTO');
      expect(json['status'], 'APPROVED');
      final back = DriverDocument.fromJson(json);
      expect(back.id, 32);
      expect(back.documentType, 'VEHICLE_PHOTO');
    });
  });

  group('Phase 3C2 — DocumentCompleteness parsing', () {
    test('parses not-ready response', () {
      final c = DocumentCompleteness.fromJson({
        'required': 5,
        'uploaded': 2,
        'missing': ['LICENSE', 'INSURANCE', 'NATIONAL_ID'],
        'readyForSubmission': false,
      });
      expect(c.required, 5);
      expect(c.uploaded, 2);
      expect(c.missing, ['LICENSE', 'INSURANCE', 'NATIONAL_ID']);
      expect(c.readyForSubmission, isFalse);
    });

    test('parses ready response', () {
      final c = DocumentCompleteness.fromJson({
        'required': 5,
        'uploaded': 5,
        'missing': <String>[],
        'readyForSubmission': true,
      });
      expect(c.readyForSubmission, isTrue);
      expect(c.missing, isEmpty);
      final json = c.toJson();
      expect(json['readyForSubmission'], true);
      expect(DocumentCompleteness.fromJson(json).uploaded, 5);
    });

    test('tolerates missing fields', () {
      final c = DocumentCompleteness.fromJson({});
      expect(c.required, 0);
      expect(c.uploaded, 0);
      expect(c.missing, isEmpty);
      expect(c.readyForSubmission, isFalse);
    });
  });
}
