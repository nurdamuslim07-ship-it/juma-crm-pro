import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/utils/launchers.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// A controllable fake for the url_launcher plugin's platform channel —
/// lets these tests simulate "this platform can't handle this URI"
/// (e.g. `tel:` with no telephony handler on desktop web) without a
/// real device/browser, which is exactly the silent-failure scenario
/// the [AppLaunchers] bug fix (return bool instead of swallowing the
/// result) targets.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  bool canLaunchResult = true;
  bool launchResult = true;
  String? lastUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    lastUrl = url;
    return canLaunchResult;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    return launchResult;
  }
}

void main() {
  late _FakeUrlLauncherPlatform fake;

  setUp(() {
    fake = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fake;
  });

  group('AppLaunchers — every method reports whether the launch actually '
      'succeeded, rather than silently no-oping (the original bug: a '
      'tapped call/WhatsApp/map button with zero feedback when the '
      'platform — e.g. desktop web with no telephony handler — could '
      'not handle the URI)', () {
    test('call() returns false when the platform cannot launch tel:', () async {
      fake.canLaunchResult = false;
      expect(await AppLaunchers.call('+77011234567'), isFalse);
    });

    test(
      'call() returns true when the platform launches tel: successfully',
      () async {
        fake.canLaunchResult = true;
        fake.launchResult = true;
        expect(await AppLaunchers.call('+77011234567'), isTrue);
        expect(fake.lastUrl, startsWith('tel:'));
      },
    );

    test(
      'whatsapp() returns false when the platform cannot launch it',
      () async {
        fake.canLaunchResult = false;
        expect(await AppLaunchers.whatsapp('+77011234567'), isFalse);
      },
    );

    test('whatsapp() builds a wa.me URL from digits only', () async {
      fake.canLaunchResult = true;
      fake.launchResult = true;
      expect(await AppLaunchers.whatsapp('+7 (701) 123-45-67'), isTrue);
      expect(fake.lastUrl, 'https://wa.me/77011234567');
    });

    test(
      'openAddressOnMap() returns false when the platform cannot launch it',
      () async {
        fake.canLaunchResult = false;
        expect(await AppLaunchers.openAddressOnMap('Абай көшесі, 12'), isFalse);
      },
    );

    test('openAddressOnMap() returns true on a successful launch', () async {
      fake.canLaunchResult = true;
      fake.launchResult = true;
      expect(await AppLaunchers.openAddressOnMap('Абай көшесі, 12'), isTrue);
    });

    test(
      'call()/whatsapp()/openAddressOnMap() propagate a launch()-level failure too, not just canLaunch()',
      () async {
        fake.canLaunchResult = true;
        fake.launchResult = false;
        expect(await AppLaunchers.call('+77011234567'), isFalse);
        expect(await AppLaunchers.whatsapp('+77011234567'), isFalse);
        expect(await AppLaunchers.openAddressOnMap('Абай көшесі, 12'), isFalse);
      },
    );
  });
}
