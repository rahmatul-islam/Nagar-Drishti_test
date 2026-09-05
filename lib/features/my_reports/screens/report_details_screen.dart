import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/appwrite_activity_log_service.dart';
import '../../../models/report_model.dart';
import '../../../models/activity_log_model.dart';

class ReportDetailsScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final _activityLogService = AppwriteActivityLogService();
  List<ActivityLogModel> _activityLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityLogs();
  }

  Future<void> _fetchActivityLogs() async {
    try {
      final logs = await _activityLogService.fetchLogsByReportId(widget.report.id);
      if (mounted) {
        setState(() {
          _activityLogs = logs;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ActivityLogs for ReportDetailsScreen: $e');
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final statusColor = _getStatusColor(report.status);
    final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(report.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('রিপোর্ট বিবরণী'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner
            SizedBox(
              height: 240,
              width: double.infinity,
              child: kIsWeb || report.imagePath.startsWith('http') || report.imagePath.startsWith('blob:')
                  ? Image.network(
                      report.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.image_not_supported_rounded, size: 64, color: AppColors.primary),
                      ),
                    )
                  : File(report.imagePath).existsSync()
                      ? Image.file(
                          File(report.imagePath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.image_rounded, size: 64, color: AppColors.primary),
                        ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Status Badge Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report.category,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                  const SizedBox(height: 8),

                  // Submitted Date & ID
                  Text(
                    'রিপোর্ট ID: ${report.id} • $formattedDate',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            report.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Description
                  const Text(
                    'আপনার বিবরণ:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.description.isNotEmpty ? report.description : 'কোনো বিবরণ প্রদান করা হয়নি।',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Dedicated Appwrite ActivityLogs Collection Timeline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'কার্যক্রমের বিবরণ (ActivityLogs Timeline):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_isLoadingLogs)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_isLoadingLogs)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('ActivityLogs ডাটাবেজ থেকে লোড হচ্ছে...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    )
                  else if (_activityLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('এখনো কোনো অ্যাক্টিভিটি রেকর্ড করা হয়নি।', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activityLogs.length,
                      itemBuilder: (context, index) {
                        final log = _activityLogs[index];
                        final isLast = index == _activityLogs.length - 1;
                        return _buildActivityLogItem(log, isLast: isLast);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogItem(ActivityLogModel log, {required bool isLast}) {
    Color roleColor = AppColors.primary;
    if (log.userRole == 'admin') roleColor = Colors.purple;
    if (log.userRole == 'officer') roleColor = Colors.blue[700]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: roleColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: roleColor.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        log.action,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM hh:mm a').format(log.timestamp),
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.userRole.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log.performedBy,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (log.details != null && log.details!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.details!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
