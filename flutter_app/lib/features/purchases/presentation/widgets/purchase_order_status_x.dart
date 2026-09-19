import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../domain/entities/purchase_order_status.dart';

extension PurchaseOrderStatusIcon on PurchaseOrderStatus {
  IconData get icon {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return LucideIcons.fileEdit;
      case PurchaseOrderStatus.approved:
        return LucideIcons.checkCircle2;
      case PurchaseOrderStatus.rejected:
        return LucideIcons.xCircle;
      case PurchaseOrderStatus.delivered:
        return LucideIcons.truck;
      case PurchaseOrderStatus.received:
        return LucideIcons.packageCheck;
      case PurchaseOrderStatus.cancelled:
        return LucideIcons.ban;
    }
  }

  String nameKk(AppStrings strings) {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return strings.purchasesStatusDraft;
      case PurchaseOrderStatus.approved:
        return strings.purchasesStatusApproved;
      case PurchaseOrderStatus.rejected:
        return strings.purchasesStatusRejected;
      case PurchaseOrderStatus.delivered:
        return strings.purchasesStatusDelivered;
      case PurchaseOrderStatus.received:
        return strings.purchasesStatusReceived;
      case PurchaseOrderStatus.cancelled:
        return strings.purchasesStatusCancelled;
    }
  }
}
