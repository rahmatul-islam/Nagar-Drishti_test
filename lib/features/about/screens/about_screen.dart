import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
      appBar: AppBar(
        title: const Text('অ্যাপ সম্পর্কিত তথ্য'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Header Branding Card
            Card(
              color: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        AppAssets.logo,
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.remove_red_eye_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.appNameEn,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.appNameBn,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusPendingBg,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.appVersion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. Purpose of NAGAR-DRISHTI
            _buildSectionCard(
              context: context,
              icon: Icons.flag_outlined,
              title: 'আমাদের উদ্দেশ্য (Purpose)',
              children: [
                const Text(
                  'নগর-দৃষ্টি (NAGAR-DRISHTI) নাগরিকদের নগরের সমস্যা কর্তৃপক্ষের কাছে পৌঁছে দিতে এবং সমাধানের অগ্রগতি স্বচ্ছভাবে অনুসরণ করতে সাহায্য করে।',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Citizen Report Workflow
            _buildSectionCard(
              context: context,
              icon: Icons.alt_route_rounded,
              title: 'রিপোর্ট করার ধাপসমূহ (Citizen Workflow)',
              children: [
                _buildStepItem(
                  stepNumber: '১',
                  title: 'ছবি ও ক্যাটাগরি নির্বাচন',
                  description:
                      'সমস্যার স্পষ্ট ছবি তুলুন এবং ক্যাটাগরি বেছে নিন।',
                ),
                _buildStepItem(
                  stepNumber: '২',
                  title: 'অবস্থান ও ঝুঁকি নির্ধারণ',
                  description:
                      'লোকেশন নিশ্চিত করুন এবং সমস্যার সংক্ষিপ্ত বিবরণ লিখুন।',
                ),
                _buildStepItem(
                  stepNumber: '৩',
                  title: 'সাবমিট ও ট্র্যাকিং আইডি',
                  description:
                      'রিপোর্ট জমা দেওয়ার পর ডিজিটাল ট্র্যাকিং নম্বর পাবেন।',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Report Tracking & Admin Review Explanation
            _buildSectionCard(
              context: context,
              icon: Icons.fact_check_outlined,
              title: 'রিপোর্ট ট্র্যাকিং ও পরিদর্শনের নিয়ম',
              children: [
                const Text(
                  '• রিপোর্ট জমা দেওয়ার পর "আমার রিপোর্ট" থেকে অপেক্ষমাণ, চলমান বা সমাধানকৃত স্ট্যাটাস দেখুন।\n\n'
                  '• নিবন্ধিত প্রশাসকরা ছবি, ক্যাটাগরি, লোকেশন ও ঝুঁকির গুরুত্ব দেখে রিপোর্ট যাচাই করে অগ্রাধিকার নির্ধারণ করবেন।',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Privacy & Support Section
            _buildSectionCard(
              context: context,
              icon: Icons.security_rounded,
              title: 'গোপনীয়তা ও সহায়তা (Privacy & Support)',
              children: [
                const Text(
                  '• আপনার ব্যক্তিগত তথ্য ও পাসওয়ার্ড এনক্রিপশন প্রযুক্তির মাধ্যমে সুরক্ষিত থাকবে।\n'
                  '• নাগরিক সহায়তার জন্য ইমেইল করুন: support@nagardrishti.gov.bd',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
