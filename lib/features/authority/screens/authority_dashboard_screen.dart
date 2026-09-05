import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/appwrite_auth_service.dart';
import '../../../data/remote/appwrite_report_service.dart';
import '../../../data/remote/officer_service.dart';
import '../../../models/report_model.dart';
import '../../../models/user_model.dart';
import '../../report/services/report_service.dart';
import '../widgets/report_workflow_details_modal.dart';

/// Modern, Fast & Premium City Corporation Admin Dashboard
class AuthorityDashboardScreen extends ConsumerStatefulWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  ConsumerState<AuthorityDashboardScreen> createState() => _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends ConsumerState<AuthorityDashboardScreen> {
  final AppwriteAuthService _authService = AppwriteAuthService();
  final AppwriteReportService _appwriteService = AppwriteReportService();

  models.User? _currentUser;
  UserRole _userRole = UserRole.unknown;
  bool _isLoading = true;
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAndFetchReports() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _authService.getCurrentUser();
      _userRole = await _authService.getCurrentUserRole();

      if (_currentUser != null && _userRole == UserRole.admin) {
        final liveReports = await _appwriteService.fetchReportsFromAppwrite();
        if (mounted && liveReports.isNotEmpty) {
          ref.read(reportListProvider.notifier).mergeReports(liveReports);
        }
      }
    } catch (e) {
      debugPrint('Error verifying admin role: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('লগআউট নিশ্চিতকরণ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('আপনি কি এডমিন প্যানেল থেকে লগআউট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('লগআউট', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(reportListProvider.notifier).clearReports();
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showAdminReviewModal(ReportModel report) {
    VerificationStatus verifStatus = report.verificationStatus == VerificationStatus.needsReview
        ? VerificationStatus.verified
        : report.verificationStatus;
    ReportSeverity selectedSeverity = report.severity;
    String selectedDept = report.assignedDepartment ?? OfficerService.departments.first;
    String selectedArea = report.assignedArea ?? OfficerService.areas.first;
    final commentController = TextEditingController(text: report.adminComment ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'রিভিউ ও বিভাগ বরাদ্দ',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text('রিপোর্ট আইডি: ${report.id}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Verification Status
                    const Text('১. সত্যতা যাচাই (Authenticity):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => verifStatus = VerificationStatus.verified),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: verifStatus == VerificationStatus.verified ? const Color(0xFFD1FAE5) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: verifStatus == VerificationStatus.verified ? Colors.green : Colors.transparent, width: 1.5),
                              ),
                              child: const Center(child: Text('যাচাইকৃত (Verified)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => verifStatus = VerificationStatus.fake),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: verifStatus == VerificationStatus.fake ? const Color(0xFFFEE2E2) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: verifStatus == VerificationStatus.fake ? Colors.red : Colors.transparent, width: 1.5),
                              ),
                              child: const Center(child: Text('ভুয়া (Fake/Reject)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Risk Severity
                    const Text('২. ঝুকির মাত্রা (Risk Severity):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRiskChip('স্বাভাবিক (Low)', ReportSeverity.low, selectedSeverity, Colors.green, setModalState),
                        _buildRiskChip('মাঝারি (Medium)', ReportSeverity.medium, selectedSeverity, Colors.amber, setModalState),
                        _buildRiskChip('জরুরি (High)', ReportSeverity.high, selectedSeverity, Colors.orange, setModalState),
                        _buildRiskChip('ক্রিটিক্যাল (Critical)', ReportSeverity.critical, selectedSeverity, Colors.red, setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Department & Area Dropdowns
                    const Text('৩. দায়িত্বপ্রাপ্ত বিভাগ ও এলাকা:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDept,
                      decoration: InputDecoration(
                        labelText: 'বিভাগ (Department)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: OfficerService.departments.map((dept) {
                        return DropdownMenuItem(value: dept, child: Text(dept, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDept = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedArea,
                      decoration: InputDecoration(
                        labelText: 'এলাকা (Jurisdiction Area)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: OfficerService.areas.map((area) {
                        return DropdownMenuItem(value: area, child: Text(area, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedArea = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Admin Comment
                    TextFormField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'এডমিন নির্দেশ ও মন্তব্য',
                        hintText: 'মাঠপর্যায়ের জন্য সুনির্দিষ্ট নির্দেশ লিখুন...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                          setModalState(() => isSaving = true);
                          try {
                            ref.read(reportListProvider.notifier).adminReviewAndAssign(
                              reportId: report.id,
                              verificationStatus: verifStatus,
                              severity: selectedSeverity,
                              riskScore: selectedSeverity == ReportSeverity.critical ? 95 : (selectedSeverity == ReportSeverity.high ? 80 : 40),
                              riskFactors: <String>[],
                              priority: selectedSeverity.code,
                              assignedDepartment: selectedDept,
                              assignedArea: selectedArea,
                              adminComment: commentController.text.trim(),
                              performedBy: _currentUser?.name ?? 'সিটি এডমিন',
                              recordActivityLog: true,
                            );

                            Future.microtask(() {
                              if (Navigator.canPop(ctx)) {
                                Navigator.pop(ctx);
                              }
                            });

                            _appwriteService.updateReportRiskAndStatusInAppwrite(
                              report.id,
                              status: verifStatus == VerificationStatus.fake ? ReportStatus.rejected : ReportStatus.assigned,
                              severity: selectedSeverity,
                              riskScore: selectedSeverity == ReportSeverity.critical ? 95 : (selectedSeverity == ReportSeverity.high ? 80 : 40),
                              riskFactors: <String>[],
                              priority: selectedSeverity.code,
                              verificationStatus: verifStatus,
                              assignedDepartment: selectedDept,
                              assignedArea: selectedArea,
                              adminComment: commentController.text.trim(),
                              performedBy: _currentUser?.name ?? 'সিটি এডমিন',
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ বরাদ্দ সম্পন্ন: $selectedDept ($selectedArea)'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Admin assign error: $e');
                            if (ctx.mounted) {
                              setModalState(() => isSaving = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                            : const Text('বরাদ্দ সম্পন্ন করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRiskChip(String label, ReportSeverity severity, ReportSeverity selectedSeverity, Color color, StateSetter setModalState) {
    final isSelected = selectedSeverity == severity;
    return GestureDetector(
      onTap: () => setModalState(() => selectedSeverity = severity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black54)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_userRole != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('অনুমতি নেই'), backgroundColor: AppColors.statusRejected),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 64, color: AppColors.statusRejected),
              const SizedBox(height: 16),
              const Text('এডমিন অ্যাক্সেস অস্বীকৃত', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text('নাগরিক হোমে ফিরে যান'),
              ),
            ],
          ),
        ),
      );
    }

    final reports = ref.watch(reportListProvider);

    // KPI Counters
    final totalCount = reports.length;
    final pendingCount = reports.where((r) => r.verificationStatus == VerificationStatus.needsReview || r.status == ReportStatus.newReport).length;
    final assignedCount = reports.where((r) => r.status == ReportStatus.assigned || r.status == ReportStatus.accepted || r.status == ReportStatus.inProgress).length;

    // Filter Logic
    final filteredReports = reports.where((r) {
      final matchesFilter = () {
        if (_selectedFilter == 'NEW') return r.verificationStatus == VerificationStatus.needsReview || r.status == ReportStatus.newReport;
        if (_selectedFilter == 'ASSIGNED') return r.status == ReportStatus.assigned || r.status == ReportStatus.accepted || r.status == ReportStatus.inProgress;
        if (_selectedFilter == 'RESOLVED') return r.status == ReportStatus.resolved || r.status == ReportStatus.finalVerification;
        return true;
      }();

      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();

    // Priority sorting (High risk first)
    filteredReports.sort((a, b) {
      if (a.severity == ReportSeverity.critical && b.severity != ReportSeverity.critical) return -1;
      if (a.severity == ReportSeverity.high && b.severity != ReportSeverity.high) return -1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Light grey background for depth
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('সিটি এডমিন কন্ট্রোল', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: _checkRoleAndFetchReports,
            tooltip: 'রিফ্রেশ',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'লগআউট',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006A4E), Color(0xFF004D36)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'স্বাগতম, ${_currentUser?.name ?? "সিটি এডমিন"}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('নাগরিক রিপোর্ট মনিটরিং সেন্টার', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildHeaderStat('মোট', '$totalCount', Icons.folder_outlined)),
                        Expanded(child: _buildHeaderStat('নতুন', '$pendingCount', Icons.rate_review_outlined)),
                        Expanded(child: _buildHeaderStat('বরাদ্দ', '$assignedCount', Icons.assignment_turned_in_outlined)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search & Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'রিপোর্ট আইডি, ক্যাটাগরি বা এলাকা খুঁজুন...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab('ALL', 'সব', totalCount),
                          const SizedBox(width: 8),
                          _buildFilterTab('NEW', 'নতুন', pendingCount),
                          const SizedBox(width: 8),
                          _buildFilterTab('ASSIGNED', 'বরাদ্দকৃত', assignedCount),
                          const SizedBox(width: 8),
                          _buildFilterTab('RESOLVED', 'সমাধানকৃত', 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'রিপোর্টের তালিকা (${filteredReports.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('High Risk শীর্ষে', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Reports List
            if (filteredReports.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('কোনো রিপোর্ট পাওয়া যায়নি।', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, idx) => _buildAdminReportCard(filteredReports[idx]),
                  childCount: filteredReports.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.amber),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
              : [],
        ),
        child: Text(
          count > 0 || key != 'RESOLVED' ? '$label ($count)' : label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminReportCard(ReportModel report) {
    final bool isHighRisk = report.severity == ReportSeverity.high || report.severity == ReportSeverity.critical;
    final bool isMedium = report.severity == ReportSeverity.medium;
    final Color priorityColor = isHighRisk ? Colors.red : (isMedium ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ReportWorkflowDetailsModal.show(context, report),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.severity.labelBangla,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.status.labelBangla,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${report.id.substring(report.id.length > 6 ? report.id.length - 6 : 0)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report.imagePath.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb || report.imagePath.startsWith('http') || report.imagePath.startsWith('blob:')
                            ? Image.network(
                          report.imagePath,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                        )
                            : (!kIsWeb && File(report.imagePath).existsSync())
                            ? Image.file(
                          File(report.imagePath),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                            : Container(width: 72, height: 72, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                      )
                    else
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.report_problem_outlined, color: Colors.grey),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title.isNotEmpty ? report.title : report.category,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  report.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(report.createdAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => ReportWorkflowDetailsModal.show(context, report),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('বিস্তারিত', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showAdminReviewModal(report),
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                        label: const Text('রিভিউ ও বরাদ্দ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}