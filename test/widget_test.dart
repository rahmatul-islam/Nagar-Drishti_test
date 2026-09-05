import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/models.dart' as models;
import 'package:nagar_drishti/data/remote/appwrite_auth_service.dart';
import 'package:nagar_drishti/models/report_model.dart';

void main() {

  test('ReportModel JSON parsing test', () {
    final json = {
      'id': 'test_rep_1',
      'userId': 'user_123',
      'imageUrl': 'https://example.com/test.jpg',
      'category': 'Pothole',
      'confidence': 95.5,
      'latitude': 23.8103,
      'longitude': 90.4125,
      'address': 'Dhaka, Bangladesh',
      'description': 'Road pothole issue',
      'status': 'PENDING',
      'severity': 'HIGH',
      'riskScore': 8,
      'riskFactors': ['দুর্ঘটনার আশঙ্কা', 'ব্যস্ত সড়ক'],
      'createdAt': '2026-09-03T20:00:00.000Z',
    };

    final report = ReportModel.fromJson(json);

    expect(report.id, 'test_rep_1');
    expect(report.userId, 'user_123');
    expect(report.status, ReportStatus.pending);
    expect(report.severity, ReportSeverity.high);
    expect(report.riskScore, 8);
    expect(report.riskFactors, contains('ব্যস্ত সড়ক'));
  });

  test('RiskEngine calculation rules test', () {
    final score1 = RiskEngine.calculateTotalScore(
      'Open electrical wire/current danger',
      ['জীবনহানির সম্ভাবনা', 'দুর্ঘটনার আশঙ্কা', 'জরুরি সমাধান প্রয়োজন'],
    );
    expect(score1, 11);
    expect(RiskEngine.determineSeverity(score1), ReportSeverity.critical);

    final score2 = RiskEngine.calculateTotalScore(
      'Large pothole',
      ['ব্যস্ত সড়ক', 'দুর্ঘটনার আশঙ্কা'],
    );
    expect(score2, 7);
    expect(RiskEngine.determineSeverity(score2), ReportSeverity.high);

    final score3 = RiskEngine.calculateTotalScore('Small pothole', []);
    expect(score3, 1);
    expect(RiskEngine.determineSeverity(score3), ReportSeverity.low);
  });

  group('Authentication & Security Audit Tests', () {
    test('Unauthenticated user returns UserRole.unknown', () {
      final role = AppwriteAuthService.getUserRole(null);
      expect(role, UserRole.unknown);
    });

    test('Email pattern alone does NOT grant admin role without admin label', () {
      final userWithGovEmail = models.User.fromMap({
        '\$id': 'user_gov_1',
        '\$createdAt': '2026-09-03T20:00:00.000Z',
        '\$updatedAt': '2026-09-03T20:00:00.000Z',
        'name': 'Officer User',
        'registration': '2026-09-03T20:00:00.000Z',
        'status': true,
        'labels': <String>[], // No admin label!
        'passwordUpdate': '',
        'email': 'officer@nagardrishti.gov.bd',
        'phone': '',
        'emailVerification': true,
        'phoneVerification': false,
        'mfa': false,
        'prefs': <String, dynamic>{},
        'targets': <dynamic>[],
        'accessedAt': '2026-09-03T20:00:00.000Z',
      });

      final role = AppwriteAuthService.getUserRole(userWithGovEmail);
      expect(role, UserRole.citizen);
    });

    test('Server-controlled Appwrite user label "admin" grants admin role', () {
      final userWithAdminLabel = models.User.fromMap({
        '\$id': 'admin_user_1',
        '\$createdAt': '2026-09-03T20:00:00.000Z',
        '\$updatedAt': '2026-09-03T20:00:00.000Z',
        'name': 'Verified Admin',
        'registration': '2026-09-03T20:00:00.000Z',
        'status': true,
        'labels': <String>['admin'], // Server-controlled admin label!
        'passwordUpdate': '',
        'email': 'admin@city.gov.bd',
        'phone': '',
        'emailVerification': true,
        'phoneVerification': false,
        'mfa': false,
        'prefs': <String, dynamic>{},
        'targets': <dynamic>[],
        'accessedAt': '2026-09-03T20:00:00.000Z',
      });

      final role = AppwriteAuthService.getUserRole(userWithAdminLabel);
      expect(role, UserRole.admin);
    });
  });
}
