import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/remote/appwrite_auth_service.dart';
import '../../../models/report_model.dart';
import '../../report/services/report_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _authService = AppwriteAuthService();
  models.User? _user;
  UserRole _role = UserRole.unknown;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _user = user;
        _role = role;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('লগআউট'),
        content: const Text('আপনি কি অ্যাপ থেকে সাইন-আউট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusRejected),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('সাইন-আউট'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(reportListProvider.notifier).clearReports();
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allReports = ref.watch(reportListProvider);
    final userReports = _user != null
        ? allReports.where((r) => r.userId == _user!.$id).toList()
        : allReports;
    final totalCount = userReports.length;
    final resolvedCount =
        userReports.where((r) => r.status == ReportStatus.resolved).length;
    final pendingCount =
        userReports.where((r) => r.status == ReportStatus.pending).length;

    final userName =
        _user?.name.isNotEmpty == true ? _user!.name : 'সচেতন নাগরিক';
    final userContact = _user?.phone.isNotEmpty == true
        ? _user!.phone
        : (_user?.email.isNotEmpty == true
            ? _user!.email
            : 'অ্যাাকাউন্ট সাইন-ইন রয়েছে');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(Icons.person_rounded,
                          size: 54, color: AppColors.primary),
                    ),
                    const SizedBox(height: 14),
                    _isLoadingUser
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      userContact,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: AppStrings.totalReports,
                    count: '$totalCount',
                    color: AppColors.primary,
                    bgColor: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: AppStrings.resolvedReports,
                    count: '$resolvedCount',
                    color: AppColors.statusResolved,
                    bgColor: AppColors.statusResolvedBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: AppStrings.pendingReports,
                    count: '$pendingCount',
                    color: AppColors.statusPending,
                    bgColor: AppColors.statusPendingBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings & Actions Options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined,
                        color: AppColors.primary),
                    title: const Text(AppStrings.settings),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  if (_role == UserRole.admin) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.accent),
                      title: const Text('সিটি কর্পোরেশন এডমিন পোর্টাল'),
                      subtitle: const Text(
                          'কর্মকর্তাদের জন্য সুরক্ষিত এডমিন প্যানেল'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pushNamed(context, '/authority-dashboard');
                      },
                    ),
                  ],
                  const Divider(height: 1, color: AppColors.divider),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: AppColors.statusRejected),
                    title: const Text(
                      AppStrings.logout,
                      style: TextStyle(
                          color: AppColors.statusRejected,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
