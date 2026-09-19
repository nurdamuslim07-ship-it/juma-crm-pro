import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_subscription_info.dart';

void main() {
  group('CompanySubscriptionInfo.isExpired', () {
    test('is false for an active, non-expired subscription', () {
      final info = CompanySubscriptionInfo(
        planKey: 'pro',
        planNameKk: 'Про',
        status: 'active',
        startedAt: DateTime(2026, 1, 1),
        remainingDays: 20,
        isTrial: false,
        companyIsActive: true,
        activeUsers: 3,
      );
      expect(info.isExpired, isFalse);
    });

    test('is true when status is not active', () {
      final info = CompanySubscriptionInfo(
        planKey: 'pro',
        planNameKk: 'Про',
        status: 'expired',
        startedAt: DateTime(2026, 1, 1),
        remainingDays: 5,
        isTrial: false,
        companyIsActive: true,
        activeUsers: 3,
      );
      expect(info.isExpired, isTrue);
    });

    test(
      'is true when remainingDays reaches zero even if status still says active',
      () {
        // The server clamps remaining_days at 0 rather than going
        // negative — a plan can be technically "active" in the
        // company_subscriptions row for a moment past its expiry date
        // before a background job flips it, so the guard checks both.
        final info = CompanySubscriptionInfo(
          planKey: 'pro',
          planNameKk: 'Про',
          status: 'active',
          startedAt: DateTime(2026, 1, 1),
          remainingDays: 0,
          isTrial: false,
          companyIsActive: true,
          activeUsers: 3,
        );
        expect(info.isExpired, isTrue);
      },
    );

    test('is false when there is no expiry at all (remainingDays null)', () {
      final info = CompanySubscriptionInfo(
        planKey: 'enterprise',
        planNameKk: 'Кәсіпорын',
        status: 'active',
        startedAt: DateTime(2026, 1, 1),
        isTrial: false,
        companyIsActive: true,
        activeUsers: 50,
      );
      expect(info.isExpired, isFalse);
    });
  });
}
