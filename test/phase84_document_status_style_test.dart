import 'package:flutter/material.dart';
import 'package:chat_app/theme/app_colors.dart';
import 'package:chat_app/utils/document_status_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8.4 — documentStatusInfo', () {
    test('approved maps to success + check icon', () {
      final info = documentStatusInfo('APPROVED');
      expect(info.label, 'Approved');
      expect(info.color, AppColors.success);
      expect(info.icon, Icons.check_circle);
    });

    test('pending maps to warning + schedule, labelled Pending Review', () {
      final info = documentStatusInfo('PENDING');
      expect(info.label, 'Pending Review');
      expect(info.color, AppColors.warning);
      expect(info.icon, Icons.schedule);
    });

    test('re-upload requested is distinct from pending (info color)', () {
      final info = documentStatusInfo('REUPLOAD_REQUESTED');
      expect(info.label, 'Re-upload Requested');
      expect(info.color, AppColors.info);
      expect(info.color, isNot(AppColors.warning));
      expect(info.icon, Icons.autorenew);
    });

    test('rejected maps to error + cancel', () {
      final info = documentStatusInfo('REJECTED');
      expect(info.label, 'Rejected');
      expect(info.color, AppColors.error);
      expect(info.icon, Icons.cancel);
    });

    test('expired is urgent dark red, distinct from neutral grey', () {
      final info = documentStatusInfo('EXPIRED');
      expect(info.label, 'Expired');
      expect(info.color, AppColors.errorDark);
      expect(info.color, isNot(AppColors.textTertiary));
      expect(info.icon, Icons.event_busy);
    });

    test('null/unknown maps to neutral tertiary', () {
      final info = documentStatusInfo(null);
      expect(info.label, 'Unknown');
      expect(info.color, AppColors.textTertiary);
    });

    test('all five primary statuses have distinct colors', () {
      final colors = <Color>{
        documentStatusInfo('APPROVED').color,
        documentStatusInfo('PENDING').color,
        documentStatusInfo('REUPLOAD_REQUESTED').color,
        documentStatusInfo('REJECTED').color,
        documentStatusInfo('EXPIRED').color,
      };
      expect(colors.length, 5);
    });
  });

  group('Phase 8.4 — documentExpiryColor', () {
    final now = DateTime(2026, 8, 4);

    DateTime d(int daysOffset) => now.add(Duration(days: daysOffset));

    test('null expiry is neutral', () {
      expect(documentExpiryColor(null, now: now), AppColors.textTertiary);
    });

    test('expired date is dark red', () {
      expect(documentExpiryColor(d(-1), now: now), AppColors.errorDark);
      expect(documentExpiryColor(d(0), now: now), AppColors.errorDark);
    });

    test('expiring within 31 days is warning', () {
      expect(documentExpiryColor(d(1), now: now), AppColors.warning);
      expect(documentExpiryColor(d(15), now: now), AppColors.warning);
      expect(documentExpiryColor(d(30), now: now), AppColors.warning);
    });

    test('far-future expiry is neutral', () {
      expect(documentExpiryColor(d(31), now: now), AppColors.textTertiary);
      expect(documentExpiryColor(d(365), now: now), AppColors.textTertiary);
    });

    test('honours custom soonDays window', () {
      expect(documentExpiryColor(d(15), now: now, soonDays: 10), AppColors.textTertiary);
      expect(documentExpiryColor(d(9), now: now, soonDays: 10), AppColors.warning);
    });
  });
}
