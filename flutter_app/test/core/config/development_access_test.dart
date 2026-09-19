import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/config/development_access.dart';

void main() {
  bool allowed({
    bool debug = true,
    bool enabled = true,
    bool local = true,
    String account = 'developer',
    String? user = 'developer',
  }) => canSkipDevelopmentContactVerification(
    debugBuild: debug,
    enabled: enabled,
    localWeb: local,
    allowedUserId: account,
    userId: user,
  );

  test('explicit local developer can postpone contact verification', () {
    expect(allowed(), isTrue);
  });
  test(
    'release, remote hosts and default builds cannot bypass verification',
    () {
      expect(allowed(debug: false), isFalse);
      expect(allowed(local: false), isFalse);
      expect(allowed(enabled: false), isFalse);
    },
  );
  test('missing sessions and other accounts cannot bypass verification', () {
    expect(allowed(user: null), isFalse);
    expect(allowed(user: 'another-user'), isFalse);
    expect(allowed(account: '', user: ''), isFalse);
  });
}
