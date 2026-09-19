import 'package:intl/intl.dart';

/// kk-KZ formatting helpers. Money is handled in integer minor units
/// (tiyn) end-to-end per DATABASE_SCHEMA.md ("never floating point") —
/// [AppFormatters.tenge] takes tiyn and only converts to a display
/// string, it never performs arithmetic on doubles.
abstract class AppFormatters {
  static final _thousands = NumberFormat.decimalPattern('kk');

  /// [minorUnits] = amount in tiyn (1 ₸ = 100 tiyn).
  static String tenge(int minorUnits) {
    final major = minorUnits ~/ 100;
    return '${_thousands.format(major)} ₸';
  }

  static String percent(num value) => '${value.round()}%';

  static String date(DateTime d) => DateFormat('dd.MM.yyyy', 'kk').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('dd.MM.yyyy HH:mm', 'kk').format(d);

  /// Formats a raw KZ phone digit string as +7 (7XX) XXX-XX-XX while typing.
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final d = digits.startsWith('8') ? '7${digits.substring(1)}' : digits;
    final buffer = StringBuffer('+7');
    if (d.length > 1) {
      buffer.write(' (${d.substring(1, d.length.clamp(1, 4))}');
    }
    if (d.length >= 4) {
      buffer.write(') ${d.substring(4, d.length.clamp(4, 7))}');
    }
    if (d.length >= 7) {
      buffer.write('-${d.substring(7, d.length.clamp(7, 9))}');
    }
    if (d.length >= 9) {
      buffer.write('-${d.substring(9, d.length.clamp(9, 11))}');
    }
    return buffer.toString();
  }
}
