import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../../models/user_model.dart';
import 'appwrite_client.dart';

enum UserRole {
  citizen,
  admin,
  officer,
  unknown,
}

extension UserRoleExtension on UserRole {
  String get labelBangla {
    switch (this) {
      case UserRole.admin:
        return 'সিটি এডমিন (Admin)';
      case UserRole.officer:
        return 'সিটি কর্পোরেশন কর্মকর্তা (Officer)';
      case UserRole.citizen:
        return 'সাধারণ নাগরিক (Citizen)';
      case UserRole.unknown:
        return 'অজানা ভূমিকা (Unknown)';
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final models.User? user;
  final UserRole role;

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.role = UserRole.unknown,
  });
}

/// Real Production Appwrite Authentication Service.
/// Strictly enforces Appwrite Email+Password session creation and Server-Controlled User Labels.
class AppwriteAuthService {
  final AppwriteClientConfig _appwrite;

  AppwriteAuthService([AppwriteClientConfig? config])
      : _appwrite = config ?? AppwriteClientConfig();

  /// Sign Up new user via Email/Phone & Password as standard Citizen account.
  Future<AuthResult> signUpUser({
    required String name,
    required String identifier,
    required String password,
  }) async {
    try {
      final cleanIdentifier = identifier.trim();
      final email = cleanIdentifier.contains('@')
          ? cleanIdentifier
          : '$cleanIdentifier@nagardrishti.gov.bd';

      if (password.length < 8) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে।',
        );
      }

      final user = await _appwrite.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Create session upon successful registration
      await _appwrite.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final verifiedRole = getUserRole(user);

      return AuthResult(
        isSuccess: true,
        user: user,
        role: verifiedRole,
      );
    } on AppwriteException catch (e) {
      debugPrint('Appwrite Sign Up Error (${e.code}): ${e.message}');
      return AuthResult(
        isSuccess: false,
        errorMessage: _mapAppwriteError(e),
      );
    } catch (e) {
      debugPrint('Sign Up Exception: $e');
      return AuthResult(
        isSuccess: false,
        errorMessage: 'ইন্টারনেট বা সংযোগে ত্রুটি: $e',
      );
    }
  }

  /// REAL Production Login requiring authentic Email & Password through Appwrite Session API
  Future<AuthResult> loginUser({
    required String identifier,
    required String password,
  }) async {
    try {
      final cleanIdentifier = identifier.trim();
      final email = cleanIdentifier.contains('@')
          ? cleanIdentifier
          : '$cleanIdentifier@nagardrishti.gov.bd';

      if (password.isEmpty) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'পাসওয়ার্ড প্রদান করা আবশ্যক।',
        );
      }

      // Real Appwrite Email+Password Session Creation
      await _appwrite.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Fetch authentic user account from Appwrite
      final user = await _appwrite.account.get();
      final verifiedRole = getUserRole(user);

      if (verifiedRole == UserRole.unknown) {
        await logout();
        return AuthResult(
          isSuccess: false,
          errorMessage: 'এই অ্যাকাউন্টে Admin বা Officer অনুমতি দেওয়া নেই।',
        );
      }

      return AuthResult(
        isSuccess: true,
        user: user,
        role: verifiedRole,
      );
    } on AppwriteException catch (e) {
      debugPrint('Appwrite Login Error (${e.code}): ${e.message}');
      return AuthResult(
        isSuccess: false,
        errorMessage: _mapAppwriteError(e),
      );
    } catch (e) {
      debugPrint('Login Exception: $e');
      return AuthResult(
        isSuccess: false,
        errorMessage: 'ইন্টারনেট সংযোগ বা অ্যাপরাইট সার্ভার সাড়া দিচ্ছে না।',
      );
    }
  }

  /// Send Phone OTP Session via Appwrite
  Future<models.Token?> sendPhoneOtp(String phoneNumber) async {
    try {
      final token = await _appwrite.account.createPhoneToken(
        userId: ID.unique(),
        phone: phoneNumber.startsWith('+') ? phoneNumber : '+88$phoneNumber',
      );
      return token;
    } catch (e) {
      debugPrint('Send Phone OTP Error: $e');
      return null;
    }
  }

  /// Verify Phone OTP Session Code with Appwrite
  Future<models.Session?> verifyPhoneOtp(String userId, String secret) async {
    try {
      if (userId.isEmpty || secret.isEmpty) return null;
      final session = await _appwrite.account.updatePhoneSession(
        userId: userId,
        secret: secret,
      );
      return session;
    } catch (e) {
      debugPrint('Verify Phone OTP Error: $e');
      return null;
    }
  }

  /// Fetch Current Logged In Account
  Future<models.User?> getCurrentUser() async {
    try {
      // Explicit timeout: a slow or unreachable server must never leave
      // callers (splash, dashboards, profile) stuck on a loading spinner.
      return await _appwrite.account
          .get()
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      return null;
    }
  }

  /// Check Verified User Role strictly from server
  Future<UserRole> getCurrentUserRole() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return UserRole.unknown;
      return getUserRole(user);
    } catch (e) {
      return UserRole.unknown;
    }
  }

  /// Determine User Role strictly from Server-Controlled Appwrite User Labels.
  /// Admin role: user.labels.contains('admin')
  /// Officer role: user.labels.contains('officer') || user.labels.contains('premium')
  static UserRole getUserRole(models.User? user) {
    if (user == null) return UserRole.unknown;

    final labels = user.labels.map((l) => l.toLowerCase()).toList();

    if (labels.contains('admin')) {
      return UserRole.admin;
    }
    if (labels.contains('officer') || labels.contains('premium')) {
      return UserRole.officer;
    }

    return UserRole.citizen;
  }

  /// Parse or construct Officer profile from authenticated Appwrite user
  UserModel getOfficerProfile(models.User user) {
    String dept = 'সড়ক ও জনপথ';
    if (user.email.contains('waste')) dept = 'বর্জ্য ব্যবস্থাপনা';
    if (user.email.contains('power')) dept = 'বিদ্যুৎ ও আলোকায়ন';
    if (user.email.contains('drainage')) dept = 'ড্রেনেজ ও নিষ্কাশন';
    if (user.email.contains('health')) dept = 'স্বাস্থ্য ও পরিবেশ';

    String area = 'ওয়ার্ড ০১ - উত্তরপাড়া';
    if (user.email.contains('02') || user.email.contains('south')) area = 'ওয়ার্ড ০২ - দক্ষিণপাড়া';
    if (user.email.contains('03') || user.email.contains('gulshan')) area = 'ওয়ার্ড ০৩ - গুলশান / বনানী';
    if (user.email.contains('04') || user.email.contains('dhanmondi')) area = 'ওয়ার্ড ০৪ - ধানমন্ডি';
    if (user.email.contains('05') || user.email.contains('mirpur')) area = 'ওয়ার্ড ০৫ - মিরপুর';

    return UserModel(
      id: user.$id,
      name: user.name.isNotEmpty ? user.name : 'সিটি কর্মকর্তা',
      email: user.email,
      phoneNumber: user.phone.isNotEmpty ? user.phone : '01700000000',
      role: UserRole.officer,
      department: dept,
      assignedArea: area,
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?u=${user.$id}',
    );
  }

  /// Logout Active Session
  Future<bool> logout() async {
    try {
      await _appwrite.account.deleteSession(sessionId: 'current');
      return true;
    } catch (e) {
      debugPrint('Logout Error: $e');
      return false;
    }
  }

  /// Consistent Appwrite Error Code Mapper
  String _mapAppwriteError(AppwriteException e) {
    switch (e.code) {
      case 404:
        return 'এই ইমেইল বা ইউজার আইডি দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি (User Not Found)।';
      case 429:
        return 'অনেকবার চেষ্টা করা হয়েছে। কয়েক মিনিট পরে আবার চেষ্টা করুন। (Rate Limit)';
      case 409:
        return 'ইমেইল বা মোবাইল নম্বরটি দিয়ে ইতিমধ্যে অ্যাকাউন্ট খোলা আছে। অনুগ্রহ করে সাইন-ইন করুন।';
      case 400:
        return 'ইনপুট ফরম্যাট সঠিক নয়। পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে।';
      case 401:
        return 'ইউজার আইডি বা পাসওয়ার্ড সঠিক নয়। (Invalid Credentials)';
      case 403:
        return 'অ্যাক্সেস অনুমতি নেই। Appwrite Console-এ Platform এবং Permissions চেক করুন।';
      default:
        return 'সমস্যা দেখা দিয়েছে (${e.code}): ${e.message ?? "Appwrite সার্ভারে সমস্যা হয়েছে।"}';
    }
  }
}
