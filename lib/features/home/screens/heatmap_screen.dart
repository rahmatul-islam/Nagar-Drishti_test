import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../report/services/report_service.dart';

class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportListProvider);

    final potholesCount = reports.where((r) => r.category.toLowerCase().contains('pothole')).length;
    final garbageCount = reports.where((r) => r.category.toLowerCase().contains('garbage')).length;
    final waterloggingCount = reports.where((r) => r.category.toLowerCase().contains('waterlogging')).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('এলাকাভিত্তিক হিটম্যাপ (Area Heatmap)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Visual Representation Header Card
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.map_rounded,
                      size: 180,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'লাইভ সিটি স্পেশিয়াল হিটম্যাপ',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'সিটি কর্পোরেশন এলাকার নাগরিক সমস্যার বিস্তার',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'মোট লাইভ রিপোর্ট: ${reports.length} টি সমস্যা রেকর্ড করা হয়েছে',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'এলাকাভিত্তিক লাইভ সমস্যার পরিসংখ্যান',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            // Live Appwrite Heatmap Summary Card
            _ZoneCard(
              zoneName: 'সিটি সমষ্টিক তথ্য (Appwrite Live Database)',
              activeIssues: reports.length,
              potholes: potholesCount,
              garbage: garbageCount,
              waterlogging: waterloggingCount,
              severity: reports.isEmpty ? 'তথ্য নেই' : (reports.length > 5 ? 'উচ্চ সক্রিয়' : 'স্বাভাবিক'),
              severityColor: reports.isEmpty
                  ? AppColors.textSecondary
                  : (reports.length > 5 ? AppColors.statusRejected : AppColors.statusResolved),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final String zoneName;
  final int activeIssues;
  final int potholes;
  final int garbage;
  final int waterlogging;
  final String severity;
  final Color severityColor;

  const _ZoneCard({
    required this.zoneName,
    required this.activeIssues,
    required this.potholes,
    required this.garbage,
    required this.waterlogging,
    required this.severity,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    zoneName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: severityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Tag(label: 'মোট: $activeIssues'),
                const SizedBox(width: 8),
                _Tag(label: 'গর্ত: $potholes'),
                const SizedBox(width: 8),
                _Tag(label: 'আবর্জনা: $garbage'),
                const SizedBox(width: 8),
                _Tag(label: 'জলজট: $waterlogging'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
