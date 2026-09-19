import 'package:flutter/foundation.dart';

import '../value_objects/notification_type.dart';

/// A single notification — provider-agnostic on purpose (Stage 4 Part
/// 2's own ask: "design the domain so Firebase/APNS can be plugged in
/// later"). Nothing here assumes an FCM/APNS token, a push payload
/// shape, or a delivery channel — [NotificationRepository] is the
/// seam a future push-provider adapter implements; this entity is
/// just "what a notification IS", independent of how it got
/// delivered.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload = const {},
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// Free-form event data (e.g. `{'orderId': '...'}`,
  /// `{'daysRemaining': 7}`) — kept generic rather than one field per
  /// [NotificationType], since each type's payload shape differs.
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      payload: payload,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          read == other.read;

  @override
  int get hashCode => Object.hash(id, read);
}
