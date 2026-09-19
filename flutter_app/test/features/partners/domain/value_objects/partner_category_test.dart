import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/partners/domain/value_objects/partner_category.dart';

void main() {
  group('PartnerCategory.dbKey / fromDbKey', () {
    test('round-trips every category through its partner_category '
        'Postgres enum value', () {
      for (final category in PartnerCategory.values) {
        expect(PartnerCategory.fromDbKey(category.dbKey), category);
      }
    });

    test('matches the exact 7-category list: '
        'ГАЗЕЛИСТ/ТАКСИСТ/ЛДСП/МДФ ЧПУ/ФУРНИТУРА/АСХАНА/БАСҚА', () {
      expect(PartnerCategory.gazelleDriver.dbKey, 'gazelle_driver');
      expect(PartnerCategory.taxiDriver.dbKey, 'taxi_driver');
      expect(PartnerCategory.ldsp.dbKey, 'ldsp');
      expect(PartnerCategory.mdfCnc.dbKey, 'mdf_cnc');
      expect(PartnerCategory.fittings.dbKey, 'fittings');
      expect(PartnerCategory.canteen.dbKey, 'canteen');
      expect(PartnerCategory.other.dbKey, 'other');
    });

    test('throws on an unknown key instead of silently returning null', () {
      expect(
        () => PartnerCategory.fromDbKey('blacksmith'),
        throwsArgumentError,
      );
    });
  });
}
