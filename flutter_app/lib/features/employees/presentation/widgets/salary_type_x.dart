import '../../../../core/i18n/app_strings.dart';
import '../../domain/value_objects/salary_type.dart';

extension SalaryTypePresentation on SalaryType {
  String label(AppStrings s) {
    switch (this) {
      case SalaryType.fixed:
        return s.salaryTypeFixed;
      case SalaryType.percentage:
        return s.salaryTypePercentage;
    }
  }
}
