import 'package:url_launcher/url_launcher.dart';

/// Thin wrappers around url_launcher for the call/WhatsApp actions the
/// master spec calls for on client and order detail screens. Every
/// method returns whether the launch actually succeeded — silently
/// swallowing a `canLaunchUrl` false/`launchUrl` failure (the original
/// shape of these helpers) left the tap looking like a dead button
/// with zero feedback, especially for `tel:` on desktop web where
/// there's often no telephony handler at all. Callers are expected to
/// show an error toast on `false` (see AppLaunchers' call sites).
abstract class AppLaunchers {
  static Future<bool> call(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  static Future<bool> whatsapp(String phoneOrHandle) async {
    final digits = phoneOrHandle.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Requirement #12 "Картадан мекенжайын ашу" — a plain maps search
  /// query URL works on every platform without a native map SDK
  /// dependency; the device's default maps app (or browser) handles it.
  static Future<bool> openAddressOnMap(String address) async {
    final uri = Uri.https('maps.google.com', '/maps', {'q': address});
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
