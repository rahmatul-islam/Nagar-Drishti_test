import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

import '../../../data/remote/appwrite_report_service.dart';
import '../../../data/remote/appwrite_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _selectedLanguage = 'বাংলা (Bangla)';
  bool _isTestingConnection = false;
  UserRole _role = UserRole.unknown;
  final _authService = AppwriteAuthService();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _role = role;
      });
    }
  }

  void _testAppwriteConn() async {
    setState(() {
      _isTestingConnection = true;
    });

    final service = AppwriteReportService();
    final errorStr = await service.testAppwriteConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
      });

      if (errorStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✓ Appwrite সার্ভার, স্টোরেজ ও ডাটাবেজ সংযোগ সম্পূর্ণ সক্রিয় রয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Appwrite সংযোগ পরীক্ষা ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'আবার চেষ্টা',
              textColor: Colors.white,
              onPressed: _testAppwriteConn,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাপ সেটিংস'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appwrite Sync Badge Card
            Card(
              color: AppColors.primaryLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side:
                    BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appwrite Cloud সার্ভার',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'আপনার সমস্ত রিপোর্ট ক্লাউডে সিঙ্ক করার ব্যবস্থা',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isTestingConnection ? null : _testAppwriteConn,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isTestingConnection
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('যাচাই করুন',
                              style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // AI Vision Card
            Card(
              color: Colors.purple.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI ভিশন সিস্টেম (Secure Backend)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Appwrite Cloud সিকিউর সার্ভার দিয়ে ছবি ক্যাটাগরাইজ করা হয়।',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // General Settings Section
            const Text(
              'সাধারণ সেটিংস',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: AppColors.primary),
                    title: const Text('ভাষা (Language)'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      _showLanguageModal(context);
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined,
                        color: AppColors.primary),
                    title: const Text('ডিপ / ডার্ক মোড (Dark Theme)'),
                    value: _darkMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined,
                        color: AppColors.primary),
                    title: const Text('পুশ নোটিফিকেশন (Push Notifications)'),
                    subtitle:
                        const Text('সমস্যার সমাধান স্ট্যাটাস আপডেট জানানো হবে'),
                    value: _pushNotifications,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _pushNotifications = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Authority Portal Section
            if (_role == UserRole.admin) ...[
              const Text(
                'সিটি কর্পোরেশন কর্তৃপক্ষ পোর্টাল',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.accent),
                  title: const Text('কর্তৃপক্ষ/এডমিন প্যানেলে প্রবেশ'),
                  subtitle: const Text(
                      'দায়িত্বপ্রাপ্ত কর্মকর্তাদের জন্য সমস্যা সমাধান পোর্টাল'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/authority-dashboard');
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // App Version Footer
            const Center(
              child: Column(
                children: [
                  Text(
                    '${AppStrings.appName} v1.0.0 (Production Ready)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Powered by Flutter, Appwrite & TensorFlow',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ভাষা নির্বাচন করুন',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('বাংলা (Bangla)'),
                  trailing: _selectedLanguage == 'বাংলা (Bangla)'
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedLanguage = 'বাংলা (Bangla)');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('English'),
                  trailing: _selectedLanguage == 'English'
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedLanguage = 'English');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
