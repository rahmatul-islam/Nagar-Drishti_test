import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _buildLogoWidget() {
    return Image.asset(
      AppAssets.logo,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // TODO: Replace fallback Icon with Image.asset('assets/images/logo.png') when asset file is placed in assets/images/
        return const Icon(
          Icons.remove_red_eye_rounded,
          size: 54,
          color: AppColors.primary,
        );
      },
    );
  }

  Widget _buildLeftHeaderPanel(BuildContext context, {bool isDesktop = false}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildLogoWidget(),
          ),
          const SizedBox(height: 24),

          // English Title
          Text(
            AppStrings.appNameEn,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),

          // Bangla Subtitle
          Text(
            AppStrings.appNameBn,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.statusPendingBg,
            ),
          ),
          const SizedBox(height: 12),

          // English Tagline Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Text(
              AppStrings.taglineEn,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Civic Description
          Text(
            AppStrings.welcomeCivicMessage,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightActionPanel(BuildContext context,
      {bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop) const SizedBox(height: 8),

          Text(
            'শুরু করতে অপশন বেছে নিন',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'নাগরিক হিসাব দিয়ে প্রবেশ করুন অথবা নতুন রেজিস্টার করুন',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 32),

          // 1. Sign In Button
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_rounded, size: 20),
                SizedBox(width: 10),
                Text(
                  AppStrings.signInBtn,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Create Account Button
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_outlined, size: 20),
                SizedBox(width: 10),
                Text(
                  AppStrings.createAccountBtn,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. About App Button
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/about'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  AppStrings.aboutAppBtn,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Footer Security Note
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 16, color: AppColors.textSecondary),
                Text(
                  'সিটি কর্পোরেশন সমন্বিত ডিজিটাল সেবা প্ল্যাটফর্ম',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            if (isDesktop) {
              // Desktop/Web Responsive Two-Panel Layout
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child:
                                _buildLeftHeaderPanel(context, isDesktop: true),
                          ),
                          Expanded(
                            child: _buildRightActionPanel(context,
                                isDesktop: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Mobile Stacked Layout
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildLeftHeaderPanel(context, isDesktop: false),
                  _buildRightActionPanel(context, isDesktop: false),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
