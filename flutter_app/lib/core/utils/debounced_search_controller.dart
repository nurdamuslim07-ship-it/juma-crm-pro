import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shared debounced-search helper — replaces the identical
/// `TextEditingController` + `Timer` + dispose boilerplate that was
/// duplicated across 11 list/picker screens (found during the
/// production-readiness audit, see PRODUCTION_AUDIT_REPORT.md).
/// No behavior change from the code it replaces: same debounce timing
/// per call site (each screen passes its own [debounce], matching
/// what it used before), same cancel-then-restart pattern.
///
/// Owns its own [textController] — wire it directly to a `TextField`;
/// call [dispose] from the widget's own `dispose()`.
class DebouncedSearchController {
  DebouncedSearchController({
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 350),
    String initialText = '',
  }) : textController = TextEditingController(text: initialText);

  final TextEditingController textController;

  /// Called once [debounce] has elapsed since the last [onChanged].
  final ValueChanged<String> onSearch;

  final Duration debounce;

  Timer? _timer;

  void onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(debounce, () => onSearch(value));
  }

  void dispose() {
    _timer?.cancel();
    textController.dispose();
  }
}
