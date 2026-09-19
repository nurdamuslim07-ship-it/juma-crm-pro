import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../domain/value_objects/payment_method.dart';

/// Kazakh label + icon per payment method (requirement #5) — the one
/// place this mapping is spelled out for the UI.
extension PaymentMethodPresentation on PaymentMethod {
  String label(AppStrings s) {
    switch (this) {
      case PaymentMethod.cash:
        return s.paymentMethodCash;
      case PaymentMethod.kaspi:
        return s.paymentMethodKaspi;
      case PaymentMethod.bankTransfer:
        return s.paymentMethodBankTransfer;
      case PaymentMethod.card:
        return s.paymentMethodCard;
      case PaymentMethod.other:
        return s.paymentMethodOther;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return LucideIcons.banknote;
      case PaymentMethod.kaspi:
        return LucideIcons.smartphone;
      case PaymentMethod.bankTransfer:
        return LucideIcons.landmark;
      case PaymentMethod.card:
        return LucideIcons.creditCard;
      case PaymentMethod.other:
        return LucideIcons.circleEllipsis;
    }
  }
}
