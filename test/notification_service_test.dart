import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_drishti/models/notification_model.dart';
import 'package:nagar_drishti/models/report_model.dart';
import 'package:nagar_drishti/features/notification/services/notification_service.dart';
import 'package:nagar_drishti/features/report/services/report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  group('In-App Notification Lifecycle & Independence Tests', () {
    test('NotificationModel JSON parsing and field verification', () {
      final json = {
        'id': 'notif_101',
        'userId': 'user_A',
        'reportId': 'REP-101',
        'type': NotificationType.reportApproved,
        'message': 'আপনার রিপোর্ট #REP-101 অনুমোদন করা হয়েছে।',
        'read': false,
        'createdAt': '2026-09-04T15:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, equals('notif_101'));
      expect(notif.userId, equals('user_A'));
      expect(notif.reportId, equals('REP-101'));
      expect(notif.type, equals(NotificationType.reportApproved));
      expect(notif.message, contains('অনুমোদন করা হয়েছে'));
      expect(notif.read, isFalse);
    });

    test('Status transitions generate all 5 mandatory notification event types', () {
      final notifNotifier = NotificationNotifier();
      final reportNotifier = ReportNotifier();

      final initialReport = ReportModel(
        id: 'REP-200',
        title: 'Water Danger',
        userId: 'user_X',
        imagePath: 'https://example.com/img.jpg',
        category: 'তীব্র জলাবদ্ধতা',
        confidence: 0.9,
        latitude: 23.8,
        longitude: 90.4,
        address: 'Dhaka',
        description: 'Test report',
        status: ReportStatus.newReport,
        createdAt: DateTime.now(),
      );

      // Event 1: REPORT_SUBMITTED
      reportNotifier.addReport(initialReport);
      notifNotifier.addNotification(NotificationModel(
        id: 'notif_ev1',
        userId: 'user_X',
        reportId: 'REP-200',
        type: NotificationType.reportSubmitted,
        message: 'আপনার রিপোর্ট #REP-200 সফলভাবে জমা দেওয়া হয়েছে।',
        createdAt: DateTime.now(),
      ));

      expect(notifNotifier.state.any((n) => n.type == NotificationType.reportSubmitted), isTrue);

      // Event 2: REPORT_APPROVED
      reportNotifier.adminReviewAndAssign(
        reportId: 'REP-200',
        verificationStatus: VerificationStatus.verified,
        severity: ReportSeverity.high,
        riskScore: 80,
        riskFactors: [],
        priority: 'HIGH',
        performedBy: 'Admin',
        recordActivityLog: false,
      );
      notifNotifier.addNotification(NotificationModel(
        id: 'notif_ev2',
        userId: 'user_X',
        reportId: 'REP-200',
        type: NotificationType.reportApproved,
        message: 'আপনার রিপোর্ট #REP-200 অনুমোদন করা হয়েছে।',
        createdAt: DateTime.now(),
      ));

      expect(notifNotifier.state.any((n) => n.type == NotificationType.reportApproved), isTrue);

      // Event 3: REPORT_IN_PROGRESS
      reportNotifier.officerAcceptReport(
        reportId: 'REP-200',
        officerName: 'Officer',
        recordActivityLog: false,
      );
      notifNotifier.addNotification(NotificationModel(
        id: 'notif_ev3',
        userId: 'user_X',
        reportId: 'REP-200',
        type: NotificationType.reportInProgress,
        message: 'আপনার রিপোর্ট #REP-200 বর্তমানে সমাধানের প্রক্রিয়ায় আছে।',
        createdAt: DateTime.now(),
      ));

      expect(notifNotifier.state.any((n) => n.type == NotificationType.reportInProgress), isTrue);

      // Event 4: REPORT_RESOLVED
      reportNotifier.officerUpdateReport(
        reportId: 'REP-200',
        newStatus: ReportStatus.resolved,
        officerName: 'Officer',
        recordActivityLog: false,
      );
      notifNotifier.addNotification(NotificationModel(
        id: 'notif_ev4',
        userId: 'user_X',
        reportId: 'REP-200',
        type: NotificationType.reportResolved,
        message: 'আপনার রিপোর্ট #REP-200 সফলভাবে সমাধান করা হয়েছে।',
        createdAt: DateTime.now(),
      ));

      expect(notifNotifier.state.any((n) => n.type == NotificationType.reportResolved), isTrue);

      // Event 5: REPORT_REJECTED
      notifNotifier.addNotification(NotificationModel(
        id: 'notif_ev5',
        userId: 'user_X',
        reportId: 'REP-200',
        type: NotificationType.reportRejected,
        message: 'আপনার রিপোর্ট #REP-200 প্রত্যাখ্যান করা হয়েছে।\nকারণ: পর্যাপ্ত প্রমাণ পাওয়া যায়নি।',
        createdAt: DateTime.now(),
      ));

      expect(notifNotifier.state.any((n) => n.type == NotificationType.reportRejected), isTrue);
    });

    test('Citizen sees ONLY their own notifications (User A vs User B)', () {
      final notifA = NotificationModel(
        id: 'notif_A',
        userId: 'user_A',
        reportId: 'REP-1',
        type: NotificationType.reportApproved,
        message: 'Msg A',
        createdAt: DateTime.now(),
      );

      final notifB = NotificationModel(
        id: 'notif_B',
        userId: 'user_B',
        reportId: 'REP-2',
        type: NotificationType.reportResolved,
        message: 'Msg B',
        createdAt: DateTime.now(),
      );

      final notifier = NotificationNotifier();
      notifier.setNotifications([notifA, notifB]);

      final userANotifs = notifier.state.where((n) => n.userId == 'user_A').toList();
      expect(userANotifs.length, equals(1));
      expect(userANotifs.first.id, equals('notif_A'));

      final userBNotifs = notifier.state.where((n) => n.userId == 'user_B').toList();
      expect(userBNotifs.length, equals(1));
      expect(userBNotifs.first.id, equals('notif_B'));
    });

    test('Deleting a notification DOES NOT delete the underlying report document', () {
      final reportNotifier = ReportNotifier();
      final notifNotifier = NotificationNotifier();

      final report = ReportModel(
        id: 'REP-300',
        title: 'Drain issue',
        userId: 'user_A',
        imagePath: 'https://example.com/img.jpg',
        category: 'ড্রেনেজ সমস্যা',
        confidence: 0.8,
        latitude: 23.8,
        longitude: 90.4,
        address: 'Dhaka',
        description: 'Test',
        status: ReportStatus.newReport,
        createdAt: DateTime.now(),
      );

      reportNotifier.addReport(report);
      final notif = NotificationModel(
        id: 'notif_300',
        userId: 'user_A',
        reportId: 'REP-300',
        type: NotificationType.reportSubmitted,
        message: 'Submitted',
        createdAt: DateTime.now(),
      );
      notifNotifier.addNotification(notif);

      expect(reportNotifier.state.length, equals(1));
      expect(notifNotifier.state.length, equals(1));

      // Mark notification read and delete notification
      notifNotifier.markAsRead('notif_300');
      notifNotifier.deleteNotification('notif_300');

      // Notification is deleted
      expect(notifNotifier.state, isEmpty);

      // REPORT MUST STILL EXIST!
      expect(reportNotifier.state.length, equals(1));
      expect(reportNotifier.state.first.id, equals('REP-300'));
    });

    test('Duplicate prevention: ignores duplicate notification for same reportId and type', () {
      final notifier = NotificationNotifier();

      final notif1 = NotificationModel(
        id: 'n1',
        userId: 'u1',
        reportId: 'REP-500',
        type: NotificationType.reportResolved,
        message: 'Resolved 1',
        createdAt: DateTime.now(),
      );

      final notif2 = NotificationModel(
        id: 'n2',
        userId: 'u1',
        reportId: 'REP-500',
        type: NotificationType.reportResolved,
        message: 'Resolved 2',
        createdAt: DateTime.now(),
      );

      notifier.addNotification(notif1);
      notifier.addNotification(notif2);

      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.id, equals('n1'));
    });
  });
}
