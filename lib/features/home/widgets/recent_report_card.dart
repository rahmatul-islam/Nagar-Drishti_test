import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/report_model.dart';

class RecentReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;

  const RecentReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
      case ReportStatus.newReport:
      case ReportStatus.adminReview:
        return AppColors.statusPending;
      case ReportStatus.assigned:
      case ReportStatus.accepted:
      case ReportStatus.inProgress:
        return AppColors.statusInProgress;
      case ReportStatus.resolved:
      case ReportStatus.finalVerification:
        return AppColors.statusResolved;
      case ReportStatus.rejected:
      case ReportStatus.onHold:
      case ReportStatus.pendingSync:
      default:
        return AppColors.statusRejected;
    }
  }

  Color _getStatusBg(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
      case ReportStatus.newReport:
      case ReportStatus.adminReview:
        return AppColors.statusPendingBg;
      case ReportStatus.assigned:
      case ReportStatus.accepted:
      case ReportStatus.inProgress:
        return AppColors.statusInProgressBg;
      case ReportStatus.resolved:
      case ReportStatus.finalVerification:
        return AppColors.statusResolvedBg;
      case ReportStatus.rejected:
        return AppColors.statusRejectedBg;
      case ReportStatus.onHold:
      case ReportStatus.pendingSync:
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pothole':
        return Icons.warning_amber_rounded;
      case 'garbage':
        return Icons.delete_outline_rounded;
      case 'waterlogging':
        return Icons.water_drop_outlined;
      case 'broken street light':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);
    final statusBg = _getStatusBg(report.status);
    final formattedDate =
        DateFormat('dd MMM, yyyy - hh:mm a').format(report.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: (kIsWeb || report.imagePath.startsWith('http') || report.imagePath.startsWith('blob:'))
                      ? Image.network(
                          report.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryLight,
                            child: Icon(_getCategoryIcon(report.category),
                                color: AppColors.primary),
                          ),
                        )
                      : (!kIsWeb && File(report.imagePath).existsSync())
                          ? Image.file(
                              File(report.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primaryLight,
                                child: Icon(_getCategoryIcon(report.category),
                                    color: AppColors.primary),
                              ),
                            )
                          : Container(
                              color: AppColors.primaryLight,
                              child: Icon(_getCategoryIcon(report.category),
                                  size: 36, color: AppColors.primary),
                            ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.status.labelBangla,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
