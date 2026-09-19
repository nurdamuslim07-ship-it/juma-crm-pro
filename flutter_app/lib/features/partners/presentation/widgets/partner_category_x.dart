import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../domain/value_objects/partner_category.dart';

/// Kazakh label + icon per category — the exact 7-category list from
/// the Partners module requirements.
extension PartnerCategoryPresentation on PartnerCategory {
  String label(AppStrings s) {
    switch (this) {
      case PartnerCategory.gazelleDriver:
        return s.partnerCategoryGazelleDriver;
      case PartnerCategory.taxiDriver:
        return s.partnerCategoryTaxiDriver;
      case PartnerCategory.ldsp:
        return s.partnerCategoryLdsp;
      case PartnerCategory.mdfCnc:
        return s.partnerCategoryMdfCnc;
      case PartnerCategory.fittings:
        return s.partnerCategoryFittings;
      case PartnerCategory.canteen:
        return s.partnerCategoryCanteen;
      case PartnerCategory.other:
        return s.partnerCategoryOther;
    }
  }

  IconData get icon {
    switch (this) {
      case PartnerCategory.gazelleDriver:
        return LucideIcons.truck;
      case PartnerCategory.taxiDriver:
        return LucideIcons.car;
      case PartnerCategory.ldsp:
        return LucideIcons.layers;
      case PartnerCategory.mdfCnc:
        return LucideIcons.cog;
      case PartnerCategory.fittings:
        return LucideIcons.wrench;
      case PartnerCategory.canteen:
        return LucideIcons.utensils;
      case PartnerCategory.other:
        return LucideIcons.moreHorizontal;
    }
  }
}
