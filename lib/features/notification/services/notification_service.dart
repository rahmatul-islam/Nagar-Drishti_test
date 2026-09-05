import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/appwrite_notification_service.dart';
import '../../../models/notification_model.dart';

final notificationListProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  final AppwriteNotificationService _service = AppwriteNotificationService();

  NotificationNotifier() : super([]);

  void addNotification(NotificationModel notification) {
    if (state.any((n) => n.id == notification.id)) {
      state = [
        for (final item in state)
          if (item.id == notification.id) notification else item
      ];
    } else if (state.any((n) => n.reportId == notification.reportId && n.type == notification.type)) {
      return; // Duplicate notification ignored
    } else {
      state = [notification, ...state];
    }

    _safeCreateRemoteNotification(notification);
  }

  void setNotifications(List<NotificationModel> notifications) {
    state = List<NotificationModel>.from(notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void mergeNotifications(List<NotificationModel> notifications) {
    if (notifications.isEmpty) return;
    final map = <String, NotificationModel>{};
    for (final item in state) {
      map[item.id] = item;
    }
    for (final item in notifications) {
      map[item.id] = item;
    }
    final mergedList = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = mergedList;
  }

  void markAsRead(String notificationId) {
    state = [
      for (final item in state)
        if (item.id == notificationId) item.copyWith(read: true) else item
    ];
    try {
      _service.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Error marking notification read in notifier: $e');
    }
  }

  /// Delete notification from state and service.
  /// IMPORTANT: Deleting a notification NEVER touches or deletes any ReportModel!
  void deleteNotification(String notificationId) {
    state = state.where((item) => item.id != notificationId).toList();
    try {
      _service.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error deleting notification in notifier: $e');
    }
  }

  void clearNotifications() {
    state = [];
  }

  void _safeCreateRemoteNotification(NotificationModel notification) {
    try {
      _service.createNotification(
        userId: notification.userId,
        reportId: notification.reportId,
        type: notification.type,
        message: notification.message,
      );
    } catch (e) {
      debugPrint('Error dispatching remote notification safely: $e');
    }
  }
}
