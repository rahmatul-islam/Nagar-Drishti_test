import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import '../../models/activity_log_model.dart';
import 'appwrite_client.dart';

/// Dedicated Appwrite Service for ActivityLogs collection (ID: 6a9a245500343a980967)
class AppwriteActivityLogService {
  final AppwriteClientConfig _appwrite;

  // In-memory fallback & offline queue cache
  static final List<ActivityLogModel> _localLogsCache = [];
  static final List<Map<String, dynamic>> _pendingOfflineQueue = [];

  AppwriteActivityLogService([AppwriteClientConfig? config])
      : _appwrite = config ?? AppwriteClientConfig();

  /// Create a new ActivityLog entry in Appwrite ActivityLogs Collection
  Future<ActivityLogModel?> createActivityLog({
    required String reportId,
    required String action,
    required String performedBy,
    required String userRole,
    String? details,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final safeSub = reportId.isEmpty ? '0' : (reportId.length > 5 ? reportId.substring(0, 5) : reportId);
    final logId = 'log_${now.millisecondsSinceEpoch}_$safeSub';

    final payload = {
      'reportId': reportId,
      'action': action,
      'performedBy': performedBy,
      'userRole': userRole,
      'timestamp': now.toIso8601String(),
      if (details != null && details.isNotEmpty) 'details': details,
    };

    final localModel = ActivityLogModel(
      id: logId,
      reportId: reportId,
      action: action,
      performedBy: performedBy,
      userRole: userRole,
      timestamp: now,
      details: details,
    );

    // Save locally immediately for fast responsive UI & offline fallback
    _localLogsCache.insert(0, localModel);

    try {
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID') {
        debugPrint('Appwrite Placeholder ID: Saved ActivityLog to local cache.');
        return localModel;
      }

      final doc = await _appwrite.databases.createDocument(
        databaseId: AppwriteClientConfig.databaseId,
        collectionId: AppwriteClientConfig.activityLogsCollectionId,
        documentId: ID.unique(),
        data: payload,
      );

      final docData = Map<String, dynamic>.from(doc.data);
      docData['id'] = doc.$id;
      return ActivityLogModel.fromJson(docData);
    } on AppwriteException catch (e) {
      debugPrint('Appwrite ActivityLog Error (${e.code}): ${e.message}');
      _pendingOfflineQueue.add(payload);
      return localModel;
    } catch (e) {
      debugPrint('ActivityLog Create General Error: $e');
      _pendingOfflineQueue.add(payload);
      return localModel;
    }
  }

  /// Fetch ActivityLogs for a specific reportId from Appwrite with local cache fallback
  Future<List<ActivityLogModel>> fetchLogsByReportId(String reportId) async {
    try {
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID') {
        return _getLocalLogsForReport(reportId);
      }

      final docs = await _appwrite.databases
          .listDocuments(
            databaseId: AppwriteClientConfig.databaseId,
            collectionId: AppwriteClientConfig.activityLogsCollectionId,
            queries: [
              Query.equal('reportId', [reportId]),
              Query.orderDesc('timestamp'),
            ],
          )
          .timeout(const Duration(seconds: 10));

      final remoteLogs = docs.documents.map((doc) {
        final docData = Map<String, dynamic>.from(doc.data);
        docData['id'] = doc.$id;
        return ActivityLogModel.fromJson(docData);
      }).toList();

      if (remoteLogs.isNotEmpty) {
        return remoteLogs;
      }

      return _getLocalLogsForReport(reportId);
    } catch (e) {
      debugPrint('Appwrite ActivityLogs Fetch Error ($e). Returning local cache.');
      return _getLocalLogsForReport(reportId);
    }
  }

  /// Delete ActivityLogs for a reportId if needed
  Future<bool> deleteLogsByReportId(String reportId) async {
    try {
      _localLogsCache.removeWhere((log) => log.reportId == reportId);
      if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID') {
        return true;
      }

      final docs = await _appwrite.databases.listDocuments(
        databaseId: AppwriteClientConfig.databaseId,
        collectionId: AppwriteClientConfig.activityLogsCollectionId,
        queries: [Query.equal('reportId', [reportId])],
      );

      for (final doc in docs.documents) {
        await _appwrite.databases.deleteDocument(
          databaseId: AppwriteClientConfig.databaseId,
          collectionId: AppwriteClientConfig.activityLogsCollectionId,
          documentId: doc.$id,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting ActivityLogs for reportId $reportId: $e');
      return false;
    }
  }

  /// Flush pending offline queue if internet connection is restored
  Future<void> syncPendingOfflineLogs() async {
    if (_pendingOfflineQueue.isEmpty) return;
    if (AppwriteClientConfig.projectId == 'YOUR_APPWRITE_PROJECT_ID') return;

    final itemsToSync = List<Map<String, dynamic>>.from(_pendingOfflineQueue);
    _pendingOfflineQueue.clear();

    for (final payload in itemsToSync) {
      try {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteClientConfig.databaseId,
          collectionId: AppwriteClientConfig.activityLogsCollectionId,
          documentId: ID.unique(),
          data: payload,
        );
      } catch (e) {
        debugPrint('Sync failed for item: $e. Re-enqueuing.');
        _pendingOfflineQueue.add(payload);
      }
    }
  }

  List<ActivityLogModel> _getLocalLogsForReport(String reportId) {
    final filtered = _localLogsCache.where((l) => l.reportId == reportId).toList();
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }
}
