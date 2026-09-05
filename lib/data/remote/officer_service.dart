import '../../models/user_model.dart';
import 'appwrite_auth_service.dart';

class OfficerService {
  static final List<UserModel> defaultOfficers = [
    UserModel(
      id: 'off_001',
      name: 'ইঞ্জি. রফিকুল ইসলাম',
      email: 'rafiq.roads@nagardrishti.gov.bd',
      phoneNumber: '01711112233',
      role: UserRole.officer,
      department: 'সড়ক ও জনপথ',
      assignedArea: 'ওয়ার্ড ০১ - উত্তরপাড়া',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=11',
    ),
    UserModel(
      id: 'off_002',
      name: 'ইঞ্জি. ফাহিম আহমেদ',
      email: 'fahim.roads@nagardrishti.gov.bd',
      phoneNumber: '01711112244',
      role: UserRole.officer,
      department: 'সড়ক ও জনপথ',
      assignedArea: 'ওয়ার্ড ০২ - দক্ষিণপাড়া',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    UserModel(
      id: 'off_003',
      name: 'মোঃ শামীম আহসান',
      email: 'shamim.waste@nagardrishti.gov.bd',
      phoneNumber: '01711112255',
      role: UserRole.officer,
      department: 'বর্জ্য ব্যবস্থাপনা',
      assignedArea: 'ওয়ার্ড ০৩ - গুলশান / বনানী',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=13',
    ),
    UserModel(
      id: 'off_004',
      name: 'রোকসানা বেগম',
      email: 'roksana.waste@nagardrishti.gov.bd',
      phoneNumber: '01711112266',
      role: UserRole.officer,
      department: 'বর্জ্য ব্যবস্থাপনা',
      assignedArea: 'ওয়ার্ড ০৪ - ধানমন্ডি',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=49',
    ),
    UserModel(
      id: 'off_005',
      name: 'ইঞ্জি. তানভীর হোসেন',
      email: 'tanvir.power@nagardrishti.gov.bd',
      phoneNumber: '01711112277',
      role: UserRole.officer,
      department: 'বিদ্যুৎ ও আলোকায়ন',
      assignedArea: 'ওয়ার্ড ০৫ - মিরপুর',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=53',
    ),
    UserModel(
      id: 'off_006',
      name: 'ইঞ্জি. মোস্তাক আহমেদ',
      email: 'mostak.drainage@nagardrishti.gov.bd',
      phoneNumber: '01711112288',
      role: UserRole.officer,
      department: 'ড্রেনেজ ও নিষ্কাশন',
      assignedArea: 'ওয়ার্ড ০১ - উত্তরপাড়া',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=68',
    ),
    UserModel(
      id: 'off_007',
      name: 'ড. ফারহানা হক',
      email: 'farhana.health@nagardrishti.gov.bd',
      phoneNumber: '01711112299',
      role: UserRole.officer,
      department: 'স্বাস্থ্য ও পরিবেশ',
      assignedArea: 'ওয়ার্ড ০২ - দক্ষিণপাড়া',
      isActive: true,
      profileImageUrl: 'https://i.pravatar.cc/150?img=45',
    ),
  ];

  static const List<String> departments = [
    'সড়ক ও জনপথ',
    'বর্জ্য ব্যবস্থাপনা',
    'বিদ্যুৎ ও আলোকায়ন',
    'ড্রেনেজ ও নিষ্কাশন',
    'স্বাস্থ্য ও পরিবেশ',
  ];

  static const List<String> areas = [
    'ওয়ার্ড ০১ - উত্তরপাড়া',
    'ওয়ার্ড ০২ - দক্ষিণপাড়া',
    'ওয়ার্ড ০৩ - গুলশান / বনানী',
    'ওয়ার্ড ০৪ - ধানমন্ডি',
    'ওয়ার্ড ০৫ - মিরপুর',
  ];

  /// Get list of all active officers
  List<UserModel> getAllOfficers() {
    return defaultOfficers.where((o) => o.isActive).toList();
  }

  /// Get officers by department
  List<UserModel> getOfficersByDepartment(String department) {
    return defaultOfficers
        .where((o) => o.isActive && o.department == department)
        .toList();
  }

  /// Get officer by ID
  UserModel? getOfficerById(String id) {
    try {
      return defaultOfficers.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get officer by Email
  UserModel? getOfficerByEmail(String email) {
    try {
      final clean = email.trim().toLowerCase();
      return defaultOfficers.firstWhere(
        (o) => o.email.toLowerCase() == clean || o.id.toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }
}
