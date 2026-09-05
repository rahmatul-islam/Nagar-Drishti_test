import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/appwrite_activity_log_service.dart';
import '../../../data/remote/appwrite_notification_service.dart';
import '../../../models/notification_model.dart';
import '../../../models/report_model.dart';

final reportListProvider = StateNotifierProvider<ReportNotifier, List<ReportModel>>((ref) {
  return ReportNotifier();
});

class ReportNotifier extends StateNotifier<List<ReportModel>> {
  final AppwriteActivityLogService _logService = AppwriteActivityLogService();
  final AppwriteNotificationService _notifService = AppwriteNotificationService();

  ReportNotifier() : super([]);

  void addReport(ReportModel newReport) {
    if (state.any((r) => r.id == newReport.id)) {
      state = [
        for (final report in state)
          if (report.id == newReport.id) newReport else report
      ];
    } else {
      state = [newReport, ...state];
    }

    // Trigger ActivityLog
    _safeCreateLog(
      reportId: newReport.id,
      action: 'রিপোর্ট তৈরি',
      performedBy: newReport.userId,
      userRole: 'citizen',
      details: newReport.description,
    );

    // Trigger In-App Notification (REPORT_SUBMITTED)
    _safeCreateNotification(
      userId: newReport.userId,
      reportId: newReport.id,
      type: NotificationType.reportSubmitted,
      message: 'আপনার রিপোর্ট #${newReport.id} সফলভাবে জমা দেওয়া হয়েছে।',
    );
  }

  void setReports(List<ReportModel> reports) {
    state = List<ReportModel>.from(reports)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void mergeReports(List<ReportModel> reports) {
    if (reports.isEmpty) return;
    final map = <String, ReportModel>{};
    for (final r in state) {
      map[r.id] = r;
    }
    for (final r in reports) {
      map[r.id] = r;
    }
    final mergedList = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = mergedList;
  }

  void removeReport(String reportId) {
    state = state.where((report) => report.id != reportId).toList();
  }

  void clearReports() {
    state = [];
  }

  /// Admin review, verification, risk level and department assignment.
  void adminReviewAndAssign({
    required String reportId,
    required VerificationStatus verificationStatus,
    required ReportSeverity severity,
    required int riskScore,
    required List<String> riskFactors,
    required String priority,
    String? assignedDepartment,
    String? assignedArea,
    String? adminComment,
    required String performedBy,
    bool recordActivityLog = true,
  }) {
    final targetReportIndex = state.indexWhere((r) => r.id == reportId);
    final String targetUserId = targetReportIndex != -1 ? state[targetReportIndex].userId : '';

    final bool isAssigned = (assignedArea != null && assignedArea.isNotEmpty) ||
      (assignedDepartment != null && assignedDepartment.isNotEmpty);
    final newStatus = verificationStatus == VerificationStatus.fake
        ? ReportStatus.rejected
        : (isAssigned ? ReportStatus.assigned : ReportStatus.adminReview);

    state = [
      for (final report in state)
        if (report.id == reportId)
          report.copyWith(
            verificationStatus: verificationStatus,
            severity: severity,
            riskScore: riskScore,
            riskFactors: riskFactors,
            priority: priority,
            assignedDepartment: assignedDepartment ?? report.assignedDepartment,
            assignedArea: assignedArea ?? report.assignedArea,
            adminComment: adminComment ?? report.adminComment,
            status: newStatus,
            updatedAt: DateTime.now(),
          )
        else
          report
    ];

    if (!recordActivityLog) return;

    // Trigger ActivityLogs & Notifications
    if (verificationStatus == VerificationStatus.verified) {
      _safeCreateLog(
        reportId: reportId,
        action: 'রিপোর্ট Verified করা হয়েছে',
        performedBy: performedBy,
        userRole: 'admin',
        details: adminComment,
      );
      _safeCreateNotification(
        userId: targetUserId,
        reportId: reportId,
        type: NotificationType.reportApproved,
        message: adminComment != null && adminComment.isNotEmpty
            ? 'আপনার রিপোর্ট #$reportId অনুমোদন করা হয়েছে।\nনির্দেশনা: $adminComment'
            : 'আপনার রিপোর্ট #$reportId অনুমোদন করা হয়েছে।',
      );
    } else if (verificationStatus == VerificationStatus.fake) {
      _safeCreateLog(
        reportId: reportId,
        action: 'রিপোর্ট বাতিল',
        performedBy: performedBy,
        userRole: 'admin',
        details: adminComment ?? 'ভুয়া রিপোর্ট চিহ্নিত করা হয়েছে।',
      );
      _safeCreateNotification(
        userId: targetUserId,
        reportId: reportId,
        type: NotificationType.reportRejected,
        message: adminComment != null && adminComment.isNotEmpty
            ? 'আপনার রিপোর্ট #$reportId প্রত্যাখ্যান করা হয়েছে।\nকারণ: $adminComment'
            : 'আপনার রিপোর্ট #$reportId প্রত্যাখ্যান করা হয়েছে।\nকারণ: পর্যাপ্ত প্রমাণ পাওয়া যায়নি।',
      );
    }

    if (assignedArea != null && assignedArea.isNotEmpty) {
      _safeCreateLog(
        reportId: reportId,
        action: 'কর্পোরেশন বরাদ্দ',
        performedBy: performedBy,
        userRole: 'admin',
        details: 'বিভাগ: $assignedDepartment | এলাকা: $assignedArea',
      );
    }
  }

  /// Officer Accepts Assignment
  void officerAcceptReport({
    required String reportId,
    required String officerName,
    bool recordActivityLog = true,
  }) {
    final targetReportIndex = state.indexWhere((r) => r.id == reportId);
    final String targetUserId = targetReportIndex != -1 ? state[targetReportIndex].userId : '';

    state = [
      for (final report in state)
        if (report.id == reportId)
          report.copyWith(
            status: ReportStatus.accepted,
            updatedAt: DateTime.now(),
          )
        else
          report
    ];

    if (recordActivityLog) {
      _safeCreateLog(
        reportId: reportId,
        action: 'কাজ গ্রহণ করা হয়েছে',
        performedBy: officerName,
        userRole: 'officer',
        details: 'কর্মকর্তা সফলভাবে কাজের দায়িত্ব গ্রহণ করেছেন।',
      );
      _safeCreateNotification(
        userId: targetUserId,
        reportId: reportId,
        type: NotificationType.reportInProgress,
        message: 'আপনার রিপোর্ট #$reportId বর্তমানে সমাধানের প্রক্রিয়ায় আছে।',
      );
    }
  }

  /// Officer Status Update (In Progress, On Hold, Resolved, Rejected)
  void officerUpdateReport({
    required String reportId,
    required ReportStatus newStatus,
    String? assignedTeam,
    String? officerComment,
    String? delayReason,
    String? proofBeforeUrl,
    String? proofAfterUrl,
    required String officerName,
    bool recordActivityLog = true,
  }) {
    final targetReportIndex = state.indexWhere((r) => r.id == reportId);
    final String targetUserId = targetReportIndex != -1 ? state[targetReportIndex].userId : '';

    state = [
      for (final report in state)
        if (report.id == reportId)
          report.copyWith(
            status: newStatus,
            assignedTeam: assignedTeam ?? report.assignedTeam,
            officerComment: officerComment ?? report.officerComment,
            delayReason: delayReason ?? report.delayReason,
            proofBeforeUrl: proofBeforeUrl ?? report.proofBeforeUrl,
            proofAfterUrl: proofAfterUrl ?? report.proofAfterUrl,
            updatedAt: DateTime.now(),
          )
        else
          report
    ];

    if (!recordActivityLog) return;

    if (newStatus == ReportStatus.resolved || newStatus == ReportStatus.finalVerification) {
      String detailsInfo = officerComment ?? 'কাজ সফলভাবে সমাধান করা হয়েছে।';
      if (proofAfterUrl != null && proofAfterUrl.isNotEmpty) {
        detailsInfo += ' | প্রুফ ছবি: $proofAfterUrl';
      }
      _safeCreateLog(
        reportId: reportId,
        action: 'কাজ সমাধান করা হয়েছে',
        performedBy: officerName,
        userRole: 'officer',
        details: detailsInfo,
      );
      _safeCreateNotification(
        userId: targetUserId,
        reportId: reportId,
        type: NotificationType.reportResolved,
        message: 'আপনার রিপোর্ট #$reportId সফলভাবে সমাধান করা হয়েছে।',
      );
    } else if (newStatus == ReportStatus.rejected) {
      String detailsInfo = officerComment ?? delayReason ?? 'রিপোর্টটি প্রত্যাখ্যান করা হয়েছে।';
      _safeCreateLog(
        reportId: reportId,
        action: 'রিপোর্ট বাতিল করা হয়েছে',
        performedBy: officerName,
        userRole: 'officer',
        details: detailsInfo,
      );
      _safeCreateNotification(
        userId: targetUserId,
        reportId: reportId,
        type: NotificationType.reportRejected,
        message: 'আপনার রিপোর্ট #$reportId প্রত্যাখ্যান করা হয়েছে।\nকারণ: $detailsInfo',
      );
    } else {
      String detailsInfo = officerComment ?? '';
      if (delayReason != null && delayReason.isNotEmpty) {
        detailsInfo += ' | বিলম্বের কারণ: $delayReason';
      }
      _safeCreateLog(
        reportId: reportId,
        action: 'স্ট্যাটাস পরিবর্তন: ${newStatus.labelBangla}',
        performedBy: officerName,
        userRole: 'officer',
        details: detailsInfo.isNotEmpty ? detailsInfo : null,
      );
      _safeCreateNotification(
        userId: targetUserId,
        reportId: reportId,
        type: NotificationType.reportInProgress,
        message: 'আপনার রিপোর্ট #$reportId বর্তমানে সমাধানের প্রক্রিয়ায় আছে।',
      );
    }
  }

  void updateReportStatus(String id, ReportStatus newStatus) {
    state = [
      for (final report in state)
        if (report.id == id) report.copyWith(status: newStatus) else report
    ];
  }

  void _safeCreateLog({
    required String reportId,
    required String action,
    required String performedBy,
    required String userRole,
    String? details,
  }) {
    try {
      _logService.createActivityLog(
        reportId: reportId,
        action: action,
        performedBy: performedBy,
        userRole: userRole,
        details: details,
      );
    } catch (e) {
      debugPrint('Safely caught ActivityLog creation exception: $e');
    }
  }

  void _safeCreateNotification({
    required String userId,
    required String reportId,
    required String type,
    required String message,
  }) {
    if (userId.isEmpty) return;
    try {
      _notifService.createNotification(
        userId: userId,
        reportId: reportId,
        type: type,
        message: message,
      );
    } catch (e) {
      debugPrint('Safely caught Notification creation exception: $e');
    }
  }
}
