/// Pure validation/normalization helpers for the registration form —
/// same regex/policy shapes as
/// `features/employees/domain/employee_validation.dart` (email format,
/// KZ phone, 8-character password minimum), kept as a separate
/// per-feature file rather than importing that one directly, matching
/// this codebase's existing convention of each feature owning its own
/// validators rather than sharing one across feature boundaries.
library;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _kzPhoneDigitsPattern = RegExp(r'^\+?[78]?\d{10}$');

String? validateFullName(String value) {
  if (value.trim().isEmpty) return 'Аты-жөнін енгізіңіз';
  return null;
}

String? validateEmail(String value) {
  if (value.trim().isEmpty) return 'Email енгізіңіз';
  if (!_emailPattern.hasMatch(value.trim())) return 'Email мекенжайы қате';
  return null;
}

String? validatePhone(String value) {
  if (value.trim().isEmpty) return 'Телефон нөмірін енгізіңіз';
  if (!_kzPhoneDigitsPattern.hasMatch(value.trim())) {
    return 'Телефон нөмірі қате. Мысалы: +77001234567';
  }
  return null;
}

String? validatePassword(String value) {
  if (value.isEmpty) return 'Құпиясөз енгізіңіз';
  if (value.length < 8) return 'Құпиясөз кемінде 8 таңбадан тұруы керек';
  return null;
}

/// Trims and lowercases — Supabase Auth itself is the source of truth
/// for uniqueness/format beyond this, this is just consistent input
/// hygiene before the request leaves the device.
String normalizeEmail(String value) => value.trim().toLowerCase();

/// Kazakhstan numbers only, always normalized to `+7XXXXXXXXXX` (E.164)
/// regardless of whether the user typed a leading `8`, `7`, or `+7` —
/// so the same value is used consistently for the `auth.signUp`
/// metadata prefill, the `updateUser(phone: ...)` call, and the
/// `verifyOTP` call, and can never silently drift between the three.
String normalizeKzPhone(String value) {
  final digits = value.trim().replaceAll(RegExp(r'[^\d]'), '');
  final tail = digits.length == 11 ? digits.substring(1) : digits;
  return '+7$tail';
}
