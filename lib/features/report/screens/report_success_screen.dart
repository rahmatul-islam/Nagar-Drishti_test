import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/report_model.dart';

class ReportSuccessScreen extends StatelessWidget {
  final ReportModel report;

  const ReportSuccessScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Success Animated Check Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.statusResolvedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: AppColors.statusResolved,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'রিপোর্ট সফলভাবে জমা হয়েছে!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনার রিপোর্টটি লোকাল ডেটাবেজে সংরক্ষিত হয়েছে। সংশ্লিষ্ট কর্তৃপক্ষ শীঘ্রই সমস্যাটি পর্যালোচনা করবে।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 32),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _DetailRow(label: 'রিপোর্ট আইডি', value: report.id),
                      const Divider(height: 16),
                      _DetailRow(label: 'সমস্যার ধরণ', value: report.category),
                      const Divider(height: 16),
                      _DetailRow(
                          label: 'AI নিশ্চিতকরণ',
                          value:
                              '${(report.confidence <= 1.0 ? report.confidence * 100 : report.confidence).round()}%'),
                      const Divider(height: 16),
                      _DetailRow(label: 'স্ট্যাটাস', value: report.status.labelBangla),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                child: const Text('হোম স্ক্রিনে ফিরে যান'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  // In Home, tab 1 is My Reports
                },
                child: const Text('আমার রিপোর্টসমূহ দেখুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
