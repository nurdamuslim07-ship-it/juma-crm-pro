/// Pure form-validation rules (requirement: "Form validation") — kept
/// separate from the widgets so they're directly testable and so the
/// same rule can't silently drift between the create and edit forms,
/// which share this file.
library;

final _kzPhonePattern = RegExp(r'^\+?7\d{10}$');

String? validateDisplayName(String value) {
  if (value.trim().isEmpty) return 'Атауы немесе аты-жөнін енгізіңіз';
  if (value.trim().length < 2) return 'Атауы тым қысқа';
  return null;
}

String? validatePartnerPhone(String value, {bool required = false}) {
  final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.isEmpty) {
    return required ? 'Телефон нөмірін енгізіңіз' : null;
  }
  if (!_kzPhonePattern.hasMatch(digits)) {
    return 'Телефон нөмірі дұрыс емес (мысалы: +77011234567)';
  }
  return null;
}

String? validateTrustRating(int? value) {
  if (value == null) return null;
  if (value < 1 || value > 5) {
    return 'Сенімділік рейтингі 1-5 аралығында болуы керек';
  }
  return null;
}
