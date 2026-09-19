/// Pure form-validation rules (requirement: "Барлық формада validation
/// болсын") — kept separate from the widgets so they're directly
/// testable and so the same rule can't silently drift between the
/// create and edit forms, which share this file.
library;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _kzPhonePattern = RegExp(r'^\+?7\d{10}$');

String? validateFullName(String value) {
  if (value.trim().isEmpty) return 'Аты-жөнін енгізіңіз';
  if (value.trim().length < 2) return 'Аты-жөні тым қысқа';
  return null;
}

String? validateEmail(String value) {
  if (value.trim().isEmpty) return 'Email енгізіңіз';
  if (!_emailPattern.hasMatch(value.trim())) return 'Email дұрыс емес';
  return null;
}

String? validatePhone(String value, {bool required = false}) {
  final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.isEmpty) {
    return required ? 'Телефон нөмірін енгізіңіз' : null;
  }
  if (!_kzPhonePattern.hasMatch(digits)) {
    return 'Телефон нөмірі дұрыс емес (мысалы: +77011234567)';
  }
  return null;
}

String? validatePassword(String value) {
  if (value.isEmpty) return 'Құпиясөз енгізіңіз';
  if (value.length < 8) return 'Құпиясөз кемінде 8 таңбадан тұруы керек';
  return null;
}

String? validateBonusPercent(double value) {
  if (value < 0 || value > 100) {
    return 'Бонус пайызы 0-100 аралығында болуы керек';
  }
  return null;
}

String? validateBaseSalary(int amountTiyn) {
  if (amountTiyn < 0) return 'Жалақы теріс болмауы керек';
  return null;
}
