import 'package:chat_app/services/expiry_config_service.dart';
import 'package:chat_app/theme/app_colors.dart';
import 'package:chat_app/utils/document_status_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ExpiryConfigService.reset);

  group('Phase 8.5 — ExpiryConfigService defaults', () {
    test('keeps legacy defaults before any config is loaded', () {
      expect(ExpiryConfigService.soonDays, 31);
      expect(ExpiryConfigService.urgentDays, 7);
      expect(ExpiryConfigService.enabled, isTrue);
    });
  });

  group('Phase 8.5 — applyConfig', () {
    test('adopts configured windows from the backend payload', () {
      ExpiryConfigService.applyConfig({
        'soonDays': 45,
        'urgentDays': 10,
        'enabled': false,
      });

      expect(ExpiryConfigService.soonDays, 45);
      expect(ExpiryConfigService.urgentDays, 10);
      expect(ExpiryConfigService.enabled, isFalse);
    });

    test('ignores a null payload', () {
      ExpiryConfigService.applyConfig(null);
      expect(ExpiryConfigService.soonDays, 31);
    });

    test('ignores invalid/non-positive windows, preserving defaults', () {
      ExpiryConfigService.applyConfig({'soonDays': 0, 'urgentDays': -3});
      expect(ExpiryConfigService.soonDays, 31);
      expect(ExpiryConfigService.urgentDays, 7);
    });
  });

  group('Phase 8.5 — colour honours the configured window', () {
    test('a date 40 days out is neutral with default, warning once soonDays=45',
        () {
      final now = DateTime(2026, 8, 4);
      final expiry = DateTime(2026, 9, 13); // 40 days later

      expect(documentExpiryColor(expiry, now: now), AppColors.textTertiary);

      ExpiryConfigService.applyConfig({'soonDays': 45});
      expect(
        documentExpiryColor(expiry,
            now: now, soonDays: ExpiryConfigService.soonDays),
        AppColors.warning,
      );
    });

    test('reset restores the legacy 31-day default', () {
      ExpiryConfigService.applyConfig({'soonDays': 45});
      ExpiryConfigService.reset();
      expect(ExpiryConfigService.soonDays, 31);
    });
  });
}
