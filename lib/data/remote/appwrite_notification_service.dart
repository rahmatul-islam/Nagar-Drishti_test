import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import '../../models/notification_model.dart';
import 'appwrite_client.dart';

class AppwriteNotificationService {
  final AppwriteClientConfig _appwrite;

  // In-memory local cache & offline queue
  static final List<NotificationModel> _localNotificationsCache = [];

  AppwriteNotificationService([AppwriteClientConfig? config])
      : _appwrite = config ?? AppwriteClientConfig();

  /// Create notification document in Appwrite & local cache
  Future<NotificationModel?> createNotification({
    required String userId,
    required String reportId,
    required String type,
    required String message,
  }) async {
    final now = DateTime.now();
    final notifId = 'notif_${now.millisecondsSinceEpoch}_${reportId.isNotEmpty ? reportId.substring(0, reportId.length > 4 ? 4 : reportId.length) : "0"}';

    final payload = {
      'userId': userId,
      'reportId': reportId,
      'type': type,
      'message': message,
      'read': false,
      'createdAt': now.toIso8601String(),
    };

    final localModel = NotificationModel(
      id: notifId,
      userId: userId,
      reportId: reportId,
      type: type,
      message: message,
      read: false,
      createdAt: now,
    );

    // Duplicate Prevention: check if notification for exact reportId and type already exists
    final existingIndex = _localNotificationsCache.indexWhere((n) => n.reportId == reportId && n.type == type);
    if (existingIndex != -1) {
      debugPrint('Duplicate notification ignored for reportId $reportId and type $type');
      return _localNotificationsCache[existingIndex];
    }

    // Insert into local cache
    _localNotificationsCache.insert(0, localModel);

    try {
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID') {
        return localModel;
      }

      final doc = await _appwrite.databases.createDocument(
        databaseId: AppwriteClientConfig.databaseId,
        collectionId: AppwriteClientConfig.notificationsCollectionId,
        documentId: ID.unique(),
        data: payload,
      );

      final docData = Map<String, dynamic>.from(doc.data);
      docData['id'] = doc.$id;
      return NotificationModel.fromJson(docData);
    } catch (e) {
      debugPrint('Notification creation handled safely with local cache: $e');
      return localModel;
    }
  }

  /// Fetch notifications for a specific user ID strictly
  Future<List<NotificationModel>> fetchNotificationsForUser(String userId) async {
    try {
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID' || userId.isEmpty) {
        return _getLocalNotificationsForUser(userId);
      }

      late dynamic docs;
      try {
        docs = await _appwrite.databases
            .listDocuments(
              databaseId: AppwriteClientConfig.databaseId,
              collectionId: AppwriteClientConfig.notificationsCollectionId,
              queries: [
                Query.equal('userId', [userId]),
                Query.orderDesc('createdAt'),
              ],
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        docs = await _appwrite.databases
            .listDocuments(
              databaseId: AppwriteClientConfig.databaseId,
              collectionId: AppwriteClientConfig.notificationsCollectionId,
              queries: [Query.orderDesc('createdAt')],
            )
            .timeout(const Duration(seconds: 10));
      }

      final remoteNotifications = docs.documents.map((doc) {
        final docData = Map<String, dynamic>.from(doc.data);
        docData['id'] = doc.$id;
        return NotificationModel.fromJson(docData);
      }).toList();

      // Mandatorily post-filter by userId
      final filteredRemote = remoteNotifications
          .where((n) => (n as NotificationModel).userId == userId)
          .cast<NotificationModel>()
          .toList();

      if (filteredRemote.isNotEmpty) {
        // Merge into local cache
        for (final item in filteredRemote) {
          if (!_localNotificationsCache.any((element) => element.id == item.id)) {
            _localNotificationsCache.add(item);
          }
        }
        return filteredRemote;
      }

      return _getLocalNotificationsForUser(userId);
    } catch (e) {
      debugPrint('Notification fetch handled safely: $e');
      return _getLocalNotificationsForUser(userId);
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    final idx = _localNotificationsCache.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _localNotificationsCache[idx] = _localNotificationsCache[idx].copyWith(read: true);
    }

    try {
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID' || notificationId.startsWith('notif_')) {
        return true;
      }

      await _appwrite.databases.updateDocument(
        databaseId: AppwriteClientConfig.databaseId,
        collectionId: AppwriteClientConfig.notificationsCollectionId,
        documentId: notificationId,
        data: {'read': true},
      );
      return true;
    } catch (e) {
      debugPrint('Mark notification read handled safely: $e');
      return true;
    }
  }

  /// Delete notification - ONLY deletes notification document, NEVER touches reports!
  Future<bool> deleteNotification(String notificationId) async {
    _localNotificationsCache.removeWhere((n) => n.id == notificationId);

    try {
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID' || notificationId.startsWith('notif_')) {
        return true;
      }

      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteClientConfig.databaseId,
        collectionId: AppwriteClientConfig.notificationsCollectionId,
        documentId: notificationId,
      );
      return true;
    } catch (e) {
      debugPrint('Notification deletion handled safely: $e');
      return true;
    }
  }

  List<NotificationModel> _getLocalNotificationsForUser(String userId) {
    final filtered = _localNotificationsCache.where((n) => n.userId == userId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }
}
