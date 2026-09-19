/// The notification categories Stage 4 Part 2 asks for. Deliberately
/// one `subscriptionExpiring` value carrying a `daysRemaining` field
/// in [AppNotification.payload] rather than three separate enum
/// values for 30/7/1 days — the distinction is data, not a different
/// kind of event.
enum NotificationType {
  newOrder,
  newPayment,
  joinRequest,
  employeeApproved,
  productionCompleted,
  warehouseShortage,
  subscriptionExpiring;

  String get dbKey => name;

  static NotificationType fromDbKey(String key) {
    return NotificationType.values.firstWhere(
      (t) => t.dbKey == key,
      orElse: () => throw ArgumentError('Unknown notification type: $key'),
    );
  }
}
