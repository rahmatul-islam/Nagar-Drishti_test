import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/appwrite_activity_log_service.dart';
import '../../../models/report_model.dart';
import '../../../models/activity_log_model.dart';

class ReportWorkflowDetailsModal extends StatefulWidget {
  final ReportModel report;

  const ReportWorkflowDetailsModal({
    super.key,
    required this.report,
  });

  static void show(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportWorkflowDetailsModal(report: report),
    );
  }

  @override
  State<ReportWorkflowDetailsModal> createState() => _ReportWorkflowDetailsModalState();
}

class _ReportWorkflowDetailsModalState extends State<ReportWorkflowDetailsModal> {
  final _activityLogService = AppwriteActivityLogService();
  List<ActivityLogModel> _fetchedLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadActivityLogs();
  }

  Future<void> _loadActivityLogs() async {
    try {
      final logs = await _activityLogService.fetchLogsByReportId(widget.report.id);
      if (mounted) {
        setState(() {
          _fetchedLogs = logs;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading logs: $e');
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  Color _getRiskColor(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.critical:
      case ReportSeverity.high:
        return const Color(0xFFDC2626);
      case ReportSeverity.medium:
        return const Color(0xFFD97706);
      case ReportSeverity.low:
        return const Color(0xFF047857);
    }
  }

  Color _getRiskBgColor(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.critical:
      case ReportSeverity.high:
        return const Color(0xFFFEE2E2);
      case ReportSeverity.medium:
        return const Color(0xFFFEF3C7);
      case ReportSeverity.low:
        return const Color(0xFFD1FAE5);
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.newReport:
      case ReportStatus.adminReview:
      case ReportStatus.pending:
        return AppColors.statusPending;
      case ReportStatus.assigned:
      case ReportStatus.accepted:
      case ReportStatus.inProgress:
        return AppColors.statusInProgress;
      case ReportStatus.resolved:
      case ReportStatus.finalVerification:
        return AppColors.statusResolved;
      case ReportStatus.onHold:
        return Colors.purple;
      case ReportStatus.rejected:
      case ReportStatus.pendingSync:
      default:
        return AppColors.statusRejected;
    }
  }

  Color _getStatusBgColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.newReport:
      case ReportStatus.adminReview:
      case ReportStatus.pending:
        return AppColors.statusPendingBg;
      case ReportStatus.assigned:
      case ReportStatus.accepted:
      case ReportStatus.inProgress:
        return AppColors.statusInProgressBg;
      case ReportStatus.resolved:
      case ReportStatus.finalVerification:
        return AppColors.statusResolvedBg;
      case ReportStatus.onHold:
        return const Color(0xFFF3E8FF);
      case ReportStatus.rejected:
      case ReportStatus.pendingSync:
      default:
        return AppColors.statusRejectedBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final riskColor = _getRiskColor(report.severity);
    final riskBg = _getRiskBgColor(report.severity);
    final statusColor = _getStatusColor(report.status);
    final statusBg = _getStatusBgColor(report.status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle & Modal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title.isNotEmpty ? report.title : report.category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'রিপোর্ট আইডি: ${report.id} • সাবমিট: ${DateFormat('dd MMM yyyy, hh:mm a').format(report.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Modal Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Risk Level Indicator Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: riskColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: riskColor),
                            const SizedBox(width: 4),
                            Text(
                              'Risk: ${report.severity.labelBangla}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Verification Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: report.verificationStatus == VerificationStatus.verified
                              ? const Color(0xFFD1FAE5)
                              : (report.verificationStatus == VerificationStatus.fake
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.verificationStatus.labelBangla,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: report.verificationStatus == VerificationStatus.verified
                                ? const Color(0xFF047857)
                                : (report.verificationStatus == VerificationStatus.fake
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFD97706)),
                          ),
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Status: ${report.status.labelBangla}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Image Preview section
                  if (report.imagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb || report.imagePath.startsWith('http') || report.imagePath.startsWith('blob:')
                          ? Image.network(
                              report.imagePath,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 140,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                ),
                              ),
                            )
                          : (!kIsWeb && File(report.imagePath).existsSync())
                              ? Image.file(
                                  File(report.imagePath),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 140,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                  ),
                                ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Before vs After Proof Photos Comparison
                  if (report.proofBeforeUrl != null || report.proofAfterUrl != null) ...[
                    const Text(
                      'কাজের প্রমাণপত্র (Before / After Proof):',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (report.proofBeforeUrl != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('কাজের পূর্বে (Before):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    report.proofBeforeUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.image)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (report.proofBeforeUrl != null && report.proofAfterUrl != null)
                          const SizedBox(width: 12),
                        if (report.proofAfterUrl != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('কাজ সম্পন্ন পর (After):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    report.proofAfterUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.image)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Report Details Section Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.category_rounded, 'ক্যাটাগরি:', report.category),
                        const Divider(height: 20),
                        _buildDetailRow(Icons.location_on_rounded, 'লোকেশন / ঠিকানা:', report.address),
                        const SizedBox(height: 4),
                        Text(
                          'জিইও স্থানাঙ্ক: ${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(Icons.person_outline_rounded, 'সাবমিট করেছেন:', 'নাগরিক (ID: ${report.userId})'),
                        const Divider(height: 20),
                        _buildDetailRow(Icons.description_rounded, 'বিবরণ:', report.description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Assignment & Admin/Officer Comment Card
                  if (report.assignedDepartment != null || report.adminComment != null || report.officerComment != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'দায়িত্বপ্রাপ্ত বিভাগ ও কর্মকর্তা',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (report.assignedDepartment != null)
                            Text('বিভাগ: ${report.assignedDepartment}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          if (report.assignedTeam != null)
                            Text('নিযুক্ত দল/কর্মী: ${report.assignedTeam}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          
                          if (report.adminComment != null && report.adminComment!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('এডমিন নির্দেশ: "${report.adminComment}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.primaryDark)),
                          ],
                          if (report.officerComment != null && report.officerComment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('কর্মকর্তার মন্তব্য: "${report.officerComment}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Activity Logs Collection Timeline (Fetched from Appwrite ActivityLogs Collection)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ActivityLogs কালানুক্রমিক টাইমলাইন:',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (_isLoadingLogs)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingLogs)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('ActivityLogs সংগ্রহ করা হচ্ছে...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                    )
                  else if (_fetchedLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('ActivityLogs Collection-এ কোনো হিস্ট্রি পাওয়া যায়নি।', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _fetchedLogs.length,
                      itemBuilder: (ctx, idx) {
                        final log = _fetchedLogs[idx];
                        return _buildTimelineItem(log, isLast: idx == _fetchedLogs.length - 1);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(ActivityLogModel log, {required bool isLast}) {
    Color badgeColor = AppColors.primary;
    if (log.userRole == 'admin') badgeColor = Colors.purple;
    if (log.userRole == 'officer') badgeColor = Colors.blue[700]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: badgeColor.withValues(alpha: 0.2),
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
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.userRole.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
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
