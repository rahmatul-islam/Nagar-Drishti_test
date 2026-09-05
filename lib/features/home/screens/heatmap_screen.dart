import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/report_model.dart';
import '../../report/services/ai_service.dart';
import '../../report/services/report_service.dart';

/// এলাকাভিত্তিক হিটম্যাপ — প্রতিটি রিপোর্টের আসল GPS স্থানাঙ্ক থেকে
/// তৈরি লাইভ স্ক্যাটার হিটম্যাপ (কোনো এক্সটার্নাল ম্যাপ প্যাকেজ ছাড়াই)।
class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  static Color _severityColor(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.critical:
      case ReportSeverity.high:
        return const Color(0xFFEF4444);
      case ReportSeverity.medium:
        return const Color(0xFFF59E0B);
      case ReportSeverity.low:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportListProvider);

    // Category distribution (normalized)
    final categoryCounts = <String, int>{};
    // Area distribution (only reports assigned to a ward/area)
    final areaCounts = <String, int>{};
    final areaHighRisk = <String, int>{};

    for (final report in reports) {
      final cat = AiService.normalizeCategory(report.category);
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;

      final area = report.assignedArea;
      if (area != null && area.isNotEmpty) {
        areaCounts[area] = (areaCounts[area] ?? 0) + 1;
        if (report.severity == ReportSeverity.high ||
            report.severity == ReportSeverity.critical) {
          areaHighRisk[area] = (areaHighRisk[area] ?? 0) + 1;
        }
      }
    }

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedAreas = areaCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                      size: 160,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded,
                                  color: AppColors.accent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'লাইভ সিটি হিটম্যাপ',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'নাগরিক সমস্যার ভৌগোলিক বিস্তার',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'মোট লাইভ রিপোর্ট: ${reports.length} টি সমস্যা রেকর্ড করা হয়েছে',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── লাইভ লোকেশন হিটম্যাপ (GPS Scatter) ─────────────────
            const Text(
              'লাইভ লোকেশন হিটম্যাপ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1220), Color(0xFF1E293B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: reports.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'এখনো কোনো রিপোর্ট ডেটা নেই।\nরিপোর্ট জমা দিলে GPS-ভিত্তিক হিটম্যাপ এখানে দেখা যাবে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: Colors.white70, height: 1.5),
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _HeatmapPainter(reports),
                        size: const Size(double.infinity, 240),
                      ),
              ),
            ),
            if (reports.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: _severityColor(ReportSeverity.low), label: 'স্বাভাবিক'),
                  const SizedBox(width: 16),
                  _LegendDot(color: _severityColor(ReportSeverity.medium), label: 'মাঝারি'),
                  const SizedBox(width: 16),
                  _LegendDot(color: _severityColor(ReportSeverity.high), label: 'উচ্চ ঝুঁকি'),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // ── ক্যাটাগরিভিত্তিক সামারি ────────────────────────────────
            const Text(
              'ক্যাটাগরিভিত্তিক সামারি',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            if (sortedCategories.isEmpty)
              const Text('তথ্য নেই',
                  style: TextStyle(fontSize: 13, color: AppColors.textLight))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedCategories
                    .map((entry) => _CategoryChip(category: entry.key, count: entry.value))
                    .toList(),
              ),
            const SizedBox(height: 24),

            // ── এলাকাভিত্তিক (ওয়ার্ড) সামারি ─────────────────────────
            const Text(
              'এলাকাভিত্তিক (ওয়ার্ড) সামারি',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            if (sortedAreas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'এডমিন কর্তৃক এলাকা বরাদ্দ সম্পন্ন হলে এখানে ওয়ার্ডভিত্তিক তথ্য দেখা যাবে।',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              )
            else
              Column(
                children: sortedAreas.map((entry) {
                  final highRisk = areaHighRisk[entry.key] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        if (highRisk > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusRejectedBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'জরুরি: $highRisk',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.statusRejected),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'মোট: ${entry.value}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/// GPS স্থানাঙ্ক অনুযায়ী heat blob + point আঁকার CustomPainter।
class _HeatmapPainter extends CustomPainter {
  final List<ReportModel> reports;

  const _HeatmapPainter(this.reports);

  Color _colorFor(ReportSeverity severity, double opacity) {
    return HeatmapScreen._severityColor(severity).withValues(alpha: opacity);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // হালকা গ্রিড — ম্যাপের অনুভূতির জন্য
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pts =
        reports.where((r) => r.latitude != 0 || r.longitude != 0).toList();
    if (pts.isEmpty) return;

    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final r in pts) {
      if (r.latitude < minLat) minLat = r.latitude;
      if (r.latitude > maxLat) maxLat = r.latitude;
      if (r.longitude < minLng) minLng = r.longitude;
      if (r.longitude > maxLng) maxLng = r.longitude;
    }

    const pad = 36.0;
    final latSpan = (maxLat - minLat).abs() < 1e-6 ? 0.01 : (maxLat - minLat);
    final lngSpan = (maxLng - minLng).abs() < 1e-6 ? 0.01 : (maxLng - minLng);

    Offset toOffset(ReportModel r) {
      final dx = pad + ((r.longitude - minLng) / lngSpan) * (size.width - pad * 2);
      // অক্ষাংশ উত্তরে বাড়ে — স্ক্রিনের y উল্টে দিন
      final dy = pad + ((maxLat - r.latitude) / latSpan) * (size.height - pad * 2);
      return Offset(dx, dy);
    }

    // প্রথমে glow blob (heat)
    for (final r in pts) {
      final center = toOffset(r);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            _colorFor(r.severity, 0.55),
            _colorFor(r.severity, 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 30));
      canvas.drawCircle(center, 30, glowPaint);
    }

    // তারপর solid core + ring
    for (final r in pts) {
      final center = toOffset(r);
      canvas.drawCircle(center, 5, Paint()..color = _colorFor(r.severity, 0.95));
      canvas.drawCircle(
        center,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.reports != reports;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final int count;

  const _CategoryChip({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (category) {
      AiService.categoryPothole => (
          Icons.warning_amber_rounded,
          'গর্ত (Pothole)',
          Colors.deepOrange
        ),
      AiService.categoryGarbage => (
          Icons.delete_outline_rounded,
          'ময়লা-আবর্জনা',
          Colors.brown
        ),
      AiService.categoryWaterlogging => (
          Icons.water_drop_outlined,
          'জলাবদ্ধতা',
          Colors.blue
        ),
      AiService.categoryBrokenLight => (
          Icons.lightbulb_outline_rounded,
          'স্ট্রিট লাইট',
          Colors.orange
        ),
      _ => (
          Icons.category_outlined,
          'অন্যান্য',
          Colors.blueGrey
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
