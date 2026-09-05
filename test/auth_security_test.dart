import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/models.dart' as models;
import 'package:nagar_drishti/data/remote/appwrite_auth_service.dart';

void main() {
  group('Auth Security Tests', () {
    test('getUserRole should identify admin from labels', () {
      final adminUser = models.User(
        $id: 'user_1',
        $createdAt: '',
        $updatedAt: '',
        name: 'Admin',
        registration: '',
        status: true,
        passwordUpdate: '',
        email: 'admin@test.com',
        phone: '',
        emailVerification: true,
        phoneVerification: true,
        labels: ['admin'],
        prefs: models.Preferences(data: {}),
        accessedAt: '',
        mfa: false,
        targets: [],
      );

      expect(AppwriteAuthService.getUserRole(adminUser), UserRole.admin);
    });

    test('getUserRole should identify citizen if admin label is missing', () {
      final citizenUser = models.User(
        $id: 'user_2',
        $createdAt: '',
        $updatedAt: '',
        name: 'Citizen',
        registration: '',
        status: true,
        passwordUpdate: '',
        email: 'citizen@test.com',
        phone: '',
        emailVerification: true,
        phoneVerification: true,
        labels: [],
        prefs: models.Preferences(data: {}),
        accessedAt: '',
        mfa: false,
        targets: [],
      );

      expect(AppwriteAuthService.getUserRole(citizenUser), UserRole.citizen);
    });

    test('getUserRole should not trust email patterns for admin role', () {
      final fakeAdminUser = models.User(
        $id: 'user_3',
        $createdAt: '',
        $updatedAt: '',
        name: 'Fake Admin',
        registration: '',
        status: true,
        passwordUpdate: '',
        email: 'admin@nagardrishti.gov.bd', // Suspicious email
        phone: '',
        emailVerification: true,
        phoneVerification: true,
        labels: [], // No admin label
        prefs: models.Preferences(data: {'role': 'admin'}), // Fake pref
        accessedAt: '',
        mfa: false,
        targets: [],
      );

      expect(AppwriteAuthService.getUserRole(fakeAdminUser), UserRole.citizen);
    });

    test('getUserRole returns unknown for null user', () {
      expect(AppwriteAuthService.getUserRole(null), UserRole.unknown);
    });
  });
}
