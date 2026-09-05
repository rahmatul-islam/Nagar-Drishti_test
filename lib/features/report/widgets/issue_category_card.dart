import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/report_model.dart';

class IssueCategoryCard extends StatelessWidget {
  final String category;
  final ValueChanged<String?> onCategoryChanged;

  const IssueCategoryCard({
    super.key,
    required this.category,
    required this.onCategoryChanged,
  });

  static const List<String> availableCategories = [
    'Open electrical wire/current danger',
    'Large pothole',
    'Small pothole',
    'Severe waterlogging',
    'Drainage problem',
    'Broken street light',
    'Garbage/illegal dumping',
    'Footpath problem',
    'Other',
  ];

  static String getCategoryBangla(String cat) {
    final catLower = cat.toLowerCase();
    if (catLower.contains('electrical') || catLower.contains('তার')) {
      return '⚡ খোলা বিদ্যুতের তার / বিদ্যুৎ বিপদ';
    } else if (catLower.contains('large') || catLower.contains('বড় গর্ত')) {
      return '🕳️ বড় গর্ত (Large Pothole)';
    } else if (catLower.contains('pothole') || catLower.contains('ছোট গর্ত')) {
      return '🚗 ছোট গর্ত (Small Pothole)';
    } else if (catLower.contains('water') || catLower.contains('জলাবদ্ধতা')) {
      return '🌊 তীব্র জলাবদ্ধতা (Waterlogging)';
    } else if (catLower.contains('drain') || catLower.contains('ড্রেন')) {
      return '💧 ড্রেনেজ ও ড্রেন সমস্যা';
    } else if (catLower.contains('light') || catLower.contains('লাইট')) {
      return '💡 নষ্ট ল্যাম্পপোস্ট / স্ট্রিট লাইট';
    } else if (catLower.contains('garbage') || catLower.contains('আবর্জনা')) {
      return '🗑️ ময়লা-আবর্জনা (Garbage)';
    } else if (catLower.contains('footpath') || catLower.contains('ফুটপাত')) {
      return '🚶 ফুটপাতের সমস্যা (Footpath)';
    } else {
      return '📌 অন্যান্য সমস্যা (Other)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCat =
        availableCategories.contains(category) ? category : 'Other';
    final baseRiskScore = RiskEngine.calculateBaseScore(currentCat);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'সমস্যার ধরণ নির্বাচন করুন (Category)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: currentCat,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              items: availableCategories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(
                    getCategoryBangla(cat),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'প্রাথমিক ক্যাটাগরি ঝুঁকি স্কোর: $baseRiskScore/4',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
