import 'package:flutter/material.dart';

abstract class FormStyle {
  static Color fill(bool dark) =>
      dark ? const Color(0xFF17283D) : const Color(0xFFF5F9FD);
  static Color edge(bool dark) =>
      dark ? const Color(0xFF34485F) : const Color(0xFFD4E2EE);
  static InputDecorationTheme inputs(bool dark) {
    final accent = dark ? const Color(0xFF6BBEFF) : const Color(0xFF258BE0);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill(dark),
      isDense: true,
      constraints: const BoxConstraints(minHeight: 52),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(
        color: dark ? const Color(0xFFAFC5DA) : const Color(0xFF586F88),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.error)
              ? const Color(0xFFD54C59)
              : states.contains(WidgetState.focused)
              ? accent
              : dark
              ? const Color(0xFFAFC5DA)
              : const Color(0xFF586F88),
          fontWeight: FontWeight.w600,
        ),
      ),
      hintStyle: TextStyle(
        color: dark ? const Color(0xFF8298AE) : const Color(0xFF91A2B3),
        fontSize: 14,
      ),
      prefixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? accent
            : dark
            ? const Color(0xFF94B7D6)
            : const Color(0xFF6B89A5),
      ),
      suffixIconColor: accent,
      border: border(edge(dark)),
      enabledBorder: border(edge(dark)),
      focusedBorder: border(accent, 1.6),
      disabledBorder: border(edge(dark).withValues(alpha: .45)),
      errorBorder: border(const Color(0xFFD54C59)),
      focusedErrorBorder: border(const Color(0xFFD54C59), 1.6),
      errorMaxLines: 3,
    );
  }

  static BoxDecoration picker(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: fill(dark),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: edge(dark)),
    );
  }
}
