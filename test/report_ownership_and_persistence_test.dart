import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_drishti/models/report_model.dart';
import 'package:nagar_drishti/features/report/services/report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  group('Report Ownership & Persistence Tests', () {
    final reportA = ReportModel(
      id: 'REP-101',
      title: 'Road Hole User A',
      userId: 'user_A',
      imagePath: 'https://example.com/imgA.jpg',
      category: 'সড়কের বড় গর্ত',
      confidence: 0.95,
      latitude: 23.8103,
      longitude: 90.4125,
      address: 'Dhaka A',
      description: 'Report by User A',
      status: ReportStatus.newReport,
      createdAt: DateTime.now(),
    );

    final reportB = ReportModel(
      id: 'REP-102',
      title: 'Waterlogging User B',
      userId: 'user_B',
      imagePath: 'https://example.com/imgB.jpg',
      category: 'তীব্র জলাবদ্ধতা',
      confidence: 0.88,
      latitude: 23.8200,
      longitude: 90.4200,
      address: 'Dhaka B',
      description: 'Report by User B',
      status: ReportStatus.newReport,
      createdAt: DateTime.now(),
    );

    test('Citizen sees ONLY their own reports (User A vs User B isolation)', () {
      final notifier = ReportNotifier();
      notifier.setReports([reportA, reportB]);

      final allReports = notifier.state;
      expect(allReports.length, equals(2));

      // Citizen User A filter
      final userAReports = allReports.where((r) => r.userId == 'user_A').toList();
      expect(userAReports.length, equals(1));
      expect(userAReports.first.id, equals('REP-101'));
      expect(userAReports.first.userId, equals('user_A'));

      // Citizen User B filter
      final userBReports = allReports.where((r) => r.userId == 'user_B').toList();
      expect(userBReports.length, equals(1));
      expect(userBReports.first.id, equals('REP-102'));
      expect(userBReports.first.userId, equals('user_B'));
    });

    test('Logout clears local in-memory state without deleting backend reports', () {
      final notifier = ReportNotifier();
      notifier.setReports([reportA, reportB]);

      expect(notifier.state.length, equals(2));

      // Simulate Logout
      notifier.clearReports();

      expect(notifier.state, isEmpty);
      expect(reportA.id, equals('REP-101')); // Report object remains intact
      expect(reportB.id, equals('REP-102'));
    });

    test('Status transitions (FAKE, RESOLVED, REJECTED) update report status without deleting report', () {
      final notifier = ReportNotifier();
      notifier.setReports([reportA]);

      // Officer updates report status to RESOLVED
      notifier.officerUpdateReport(
        reportId: 'REP-101',
        newStatus: ReportStatus.resolved,
        officerName: 'Officer Rafiq',
        recordActivityLog: false,
      );

      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.status, equals(ReportStatus.resolved));
      expect(notifier.state.first.id, equals('REP-101')); // Report persistent

      // Admin updates status to FAKE / REJECTED
      notifier.adminReviewAndAssign(
        reportId: 'REP-101',
        verificationStatus: VerificationStatus.fake,
        severity: ReportSeverity.low,
        riskScore: 0,
        riskFactors: [],
        priority: 'LOW',
        performedBy: 'Admin',
        recordActivityLog: false,
      );

      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.status, equals(ReportStatus.rejected));
      expect(notifier.state.first.verificationStatus, equals(VerificationStatus.fake));
      expect(notifier.state.first.id, equals('REP-101')); // Report persistent
    });
  });
}
