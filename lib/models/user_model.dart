import '../data/remote/appwrite_auth_service.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final String? assignedArea;
  final bool isActive;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.email = '',
    this.role = UserRole.citizen,
    this.department,
    this.assignedArea,
    this.isActive = true,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    UserRole roleVal = UserRole.citizen;
    if (rawRole != null) {
      if (rawRole.toLowerCase() == 'admin') roleVal = UserRole.admin;
      if (rawRole.toLowerCase() == 'officer') roleVal = UserRole.officer;
    }

    return UserModel(
      id: json['id'] as String? ?? json['\$id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? 'অজানা ব্যবহারকারী',
      email: json['email'] as String? ?? '',
      role: roleVal,
      department: json['department'] as String?,
      assignedArea: json['assignedArea'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department,
      'assignedArea': assignedArea,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? assignedArea,
    bool? isActive,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      assignedArea: assignedArea ?? this.assignedArea,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
