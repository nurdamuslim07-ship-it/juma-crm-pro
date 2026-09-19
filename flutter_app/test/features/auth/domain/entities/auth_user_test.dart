import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/profile_status.dart';

void main() {
  group('AuthUser', () {
    test('isDirector is true for "director" or "owner" roleKeys', () {
      const director = AuthUser(
        id: '1',
        fullName: 'Директор',
        isActive: true,
        roleKeys: ['director'],
      );
      const owner = AuthUser(
        id: '3',
        fullName: 'Иесі',
        isActive: true,
        roleKeys: ['owner'],
      );
      const manager = AuthUser(
        id: '2',
        fullName: 'Менеджер',
        isActive: true,
        roleKeys: ['manager'],
      );

      expect(director.isDirector, isTrue);
      expect(owner.isDirector, isTrue);
      expect(manager.isDirector, isFalse);
      expect(owner.isOwner, isTrue);
      expect(director.isOwner, isFalse);
    });

    test('isMember is true only when status is active', () {
      const pending = AuthUser(
        id: '1',
        fullName: 'Жаңа қолданушы',
        isActive: true,
        roleKeys: [],
        companyId: 'company-1',
        status: ProfileStatus.pending,
      );
      const active = AuthUser(
        id: '2',
        fullName: 'Белсенді қолданушы',
        isActive: true,
        roleKeys: ['manager'],
        companyId: 'company-1',
        status: ProfileStatus.active,
      );
      const notLoaded = AuthUser(
        id: '3',
        fullName: 'X',
        isActive: true,
        roleKeys: [],
      );

      expect(pending.isMember, isFalse);
      expect(active.isMember, isTrue);
      expect(notLoaded.isMember, isFalse);
    });

    test('companyIsActive defaults to true when not yet loaded', () {
      const user = AuthUser(
        id: '1',
        fullName: 'X',
        isActive: true,
        roleKeys: [],
      );
      expect(user.companyIsActive, isTrue);
    });

    test('isActive (legacy) and status are independent fields', () {
      // A deactivated-but-still-a-member profile: the legacy
      // is_active toggle predates status and is not the access gate —
      // see AuthUser.isActive's own doc comment.
      const user = AuthUser(
        id: '1',
        fullName: 'X',
        isActive: false,
        roleKeys: ['manager'],
        companyId: 'company-1',
        status: ProfileStatus.active,
      );
      expect(user.isActive, isFalse);
      expect(user.isMember, isTrue);
    });

    test('hasRole checks membership in roleKeys', () {
      const user = AuthUser(
        id: '1',
        fullName: 'Қос рөл',
        isActive: true,
        roleKeys: ['manager', 'measurer'],
      );

      expect(user.hasRole('measurer'), isTrue);
      expect(user.hasRole('accountant'), isFalse);
    });

    test('isEmailVerified/isPhoneVerified come straight from Supabase Auth\'s '
        'own confirmation timestamps — null means not verified', () {
      const unverified = AuthUser(
        id: '1',
        fullName: 'X',
        isActive: true,
        roleKeys: [],
      );
      final verified = AuthUser(
        id: '1',
        fullName: 'X',
        isActive: true,
        roleKeys: const [],
        emailConfirmedAt: DateTime(2026, 1, 1),
        phoneConfirmedAt: DateTime(2026, 1, 2),
      );

      expect(unverified.isEmailVerified, isFalse);
      expect(unverified.isPhoneVerified, isFalse);
      expect(verified.isEmailVerified, isTrue);
      expect(verified.isPhoneVerified, isTrue);
    });

    test('equality is value-based, not identity-based', () {
      const a = AuthUser(
        id: '1',
        fullName: 'A',
        isActive: true,
        roleKeys: ['manager'],
      );
      const b = AuthUser(
        id: '1',
        fullName: 'A',
        isActive: true,
        roleKeys: ['manager'],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
