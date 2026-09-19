import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/value_objects/order_status.dart';

/// Kazakh label + brand color per status — the one place this mapping
/// is spelled out for the UI (mirrors [OrderStatus.dbValue] being the
/// one place the DB mapping is spelled out).
extension OrderStatusPresentation on OrderStatus {
  String label(AppStrings s) {
    switch (this) {
      case OrderStatus.measurement:
        return s.orderStatusMeasurement;
      case OrderStatus.accepted:
        return s.orderStatusAccepted;
      case OrderStatus.inProgress:
        return s.orderStatusInProgress;
      case OrderStatus.ready:
        return s.orderStatusReady;
      case OrderStatus.installed:
        return s.orderStatusInstalled;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.measurement:
        return AppColors.sky;
      case OrderStatus.accepted:
        return AppColors.skyDeep;
      case OrderStatus.inProgress:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.indigo;
      case OrderStatus.installed:
        return AppColors.success;
    }
  }
}
