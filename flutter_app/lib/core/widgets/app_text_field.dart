import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// Standard text field primitive (see COMPONENT_LIBRARY.md's `<Input>`
/// entry) — label + validation message rendered in Kazakh by the caller.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.autofillHints,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      enabled: enabled,
      inputFormatters: inputFormatters,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget + 8,
        ),
      ),
    );
  }
}
