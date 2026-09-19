import '../../../../core/i18n/app_strings.dart';
import '../../domain/analytics_period.dart';

extension AnalyticsPeriodTypePresentation on AnalyticsPeriodType {
  String label(AppStrings s) {
    switch (this) {
      case AnalyticsPeriodType.day:
        return s.analyticsPeriodDay;
      case AnalyticsPeriodType.week:
        return s.analyticsPeriodWeek;
      case AnalyticsPeriodType.month:
        return s.analyticsPeriodMonth;
      case AnalyticsPeriodType.year:
        return s.analyticsPeriodYear;
    }
  }
}
