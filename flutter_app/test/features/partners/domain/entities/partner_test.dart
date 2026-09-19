import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/partners/domain/entities/partner.dart';
import 'package:juma_ui_crm/features/partners/domain/value_objects/partner_category.dart';

Partner _partner({
  String id = 'p1',
  int? trustRating,
  String? notes,
  String? bankDetails,
  int? balanceTiyn,
  bool hasExtendedAccess = false,
  bool hasFinancialAccess = false,
  DateTime? deletedAt,
}) {
  return Partner(
    id: id,
    displayName: 'Ерлан ЛДСП жеткізуші',
    category: PartnerCategory.ldsp,
    trustRating: trustRating,
    notes: notes,
    bankDetails: bankDetails,
    balanceTiyn: balanceTiyn,
    isActive: true,
    createdAt: DateTime(2026, 7, 13),
    deletedAt: deletedAt,
    hasExtendedAccess: hasExtendedAccess,
    hasFinancialAccess: hasFinancialAccess,
  );
}

void main() {
  group('Partner.hasExtendedAccess / hasFinancialAccess — reflect the '
      "server's own tier flags, not field nullability "
      '(trust_rating/notes/balance are legitimately nullable even when '
      'the caller has access)', () {
    test('hasExtendedAccess is false even with null trustRating/notes '
        'when the server says the tier was redacted', () {
      final partner = _partner(hasExtendedAccess: false);
      expect(partner.hasExtendedAccess, isFalse);
    });

    test('hasExtendedAccess is true even when trustRating/notes are '
        'both null, as long as the server granted the tier — an empty '
        'value is not the same as a redacted one', () {
      final partner = _partner(hasExtendedAccess: true);
      expect(partner.hasExtendedAccess, isTrue);
    });

    test('hasFinancialAccess is false when the server redacted it', () {
      final partner = _partner(hasFinancialAccess: false);
      expect(partner.hasFinancialAccess, isFalse);
    });

    test('hasFinancialAccess is true when the server granted it, even '
        'with a zero balance and no bank details on file', () {
      final partner = _partner(hasFinancialAccess: true, balanceTiyn: 0);
      expect(partner.hasFinancialAccess, isTrue);
    });
  });

  test('isDeleted reflects deletedAt', () {
    expect(_partner().isDeleted, isFalse);
    expect(_partner(deletedAt: DateTime(2026, 7, 13)).isDeleted, isTrue);
  });

  test('equality is based on id only, matching the persisted-row identity', () {
    final a = _partner(id: 'p1');
    final b = _partner(id: 'p1', hasFinancialAccess: true, balanceTiyn: 500);
    expect(a, equals(b));
  });

  test('different ids are not equal', () {
    expect(_partner(id: 'p1'), isNot(equals(_partner(id: 'p2'))));
  });
}
