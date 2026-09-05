import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/appwrite_auth_service.dart';
import '../../../data/remote/appwrite_report_service.dart';
import '../../../models/report_model.dart';
import '../../../models/user_model.dart';
import '../../report/services/report_service.dart';
import '../widgets/report_workflow_details_modal.dart';

/// Clean & Modern City Corporation Officer Dashboard
class OfficerDashboardScreen extends ConsumerStatefulWidget {
  final String? initialOfficerId;

  const OfficerDashboardScreen({
    super.key,
    this.initialOfficerId,
  });

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  final AppwriteAuthService _authService = AppwriteAuthService();
  final AppwriteReportService _reportService = AppwriteReportService();

  bool _isVerifyingRole = true;
  UserModel _officerProfile = UserModel(
    id: 'off_001',
    name: 'ইঞ্জি. রফিকুল ইসলাম',
    email: 'officer@dhaka.gov.bd',
    phoneNumber: '01711112233',
    role: UserRole.officer,
    department: 'সড়ক ও জনপথ',
    assignedArea: 'ওয়ার্ড ০১ - ঢাকা',
    isActive: true,
  );

  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuthenticOfficerProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthenticOfficerProfile() async {
    setState(() => _isVerifyingRole = true);

    try {
      final user = await _authService.getCurrentUser();
      final role = await _authService.getCurrentUserRole();

      if (!mounted) return;

      if (user != null && role == UserRole.officer) {
        _officerProfile = _authService.getOfficerProfile(user);
        try {
          final assignedReports = await _reportService.fetchReportsFromAppwrite();
          if (mounted && assignedReports.isNotEmpty) {
            ref.read(reportListProvider.notifier).mergeReports(assignedReports);
          }
        } catch (e) {
          debugPrint('Officer reports fetch fallback: $e');
        }
      } else if (user != null && role == UserRole.admin) {
        _officerProfile = UserModel(
          id: user.$id,
          name: user.name.isNotEmpty ? user.name : 'মেয়রিয়াল এডমিন',
          email: user.email,
          phoneNumber: '01711112233',
          role: UserRole.admin,
          department: 'সড়ক ও জনপথ',
          assignedArea: 'সিটি কর্পোরেশন সকল ওয়ার্ড',
          isActive: true,
        );
      }
    } catch (e) {
      debugPrint('Error loading officer profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isVerifyingRole = false);
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('লগআউট নিশ্চিতকরণ'),
        content: const Text('আপনি কি কর্মকর্তা ড্যাশবোর্ড থেকে লগআউট করতে চান?'),
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

  Future<void> _confirmAndDeleteReport(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('রিপোর্ট মুছে ফেলা'),
          ],
        ),
        content: const Text(
          'আপনি কি নিশ্চিত যে এই কাজটি আপনার ড্যাশবোর্ড থেকে মুছে ফেলতে চান? এটি ডাটাবেজ থেকেও রিমুভ হয়ে যাবে।',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.white),
            label: const Text('ডিলিট করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // ১. লোকাল স্টেট থেকে রিমুভ করা
      ref.read(reportListProvider.notifier).removeReport(report.id);
      try {
        // ২. ডাটাবেজ থেকে রিমুভ করা
        await _reportService.deleteReportFromAppwrite(report.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ রিপোর্ট (${report.id}) সফলভাবে মুছে ফেলা হয়েছে।'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        debugPrint("Delete error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ রিপোর্ট ডিলিট করতে সমস্যা হয়েছে!'),
              backgroundColor: Colors.deepOrange,
            ),
          );
        }
      }
    }
  }

  void _showOfficerActionModal(ReportModel report) {
    ReportStatus currentStatus = report.status;
    bool isSaving = false;
    final teamController = TextEditingController(text: report.assignedTeam ?? '');
    final commentController = TextEditingController(text: report.officerComment ?? '');
    final delayController = TextEditingController(text: report.delayReason ?? '');
    final beforeUrlController = TextEditingController(text: report.proofBeforeUrl ?? report.imagePath);
    final afterUrlController = TextEditingController(text: report.proofAfterUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDelayedStatus = currentStatus == ReportStatus.onHold;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 16,
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
                        width: 40,
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.engineering_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'অ্যাকশন ও আপডেট প্যানেল',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'আইডি: ${report.id}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Workflow Status Chips
                    const Text(
                      'রিপোর্টের Status নির্ধারণ করুন:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChoiceChip('বরাদ্দকৃত', ReportStatus.assigned, currentStatus, setModalState),
                        _buildModalChoiceChip('গৃহীত', ReportStatus.accepted, currentStatus, setModalState),
                        _buildModalChoiceChip('কাজ চলমান', ReportStatus.inProgress, currentStatus, setModalState),
                        _buildModalChoiceChip('স্থগিত', ReportStatus.onHold, currentStatus, setModalState),
                        _buildModalChoiceChip('সমাধানকৃত', ReportStatus.resolved, currentStatus, setModalState),
                        _buildModalChoiceChip('বাতিল', ReportStatus.rejected, currentStatus, setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: teamController,
                      decoration: const InputDecoration(
                        labelText: 'নিযুক্ত টিম (Assigned Team)',
                        hintText: 'যেমন: টিম Alpha - ৪ জন',
                        prefixIcon: Icon(Icons.groups_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: commentController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'অগ্রগতির বিবরণ (Progress Notes)',
                        prefixIcon: Icon(Icons.rate_review_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (isDelayedStatus) ...[
                      TextFormField(
                        controller: delayController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'বিলম্বের কারণ (Delay Reason)',
                          prefixIcon: Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: beforeUrlController,
                      decoration: const InputDecoration(
                        labelText: 'আগের ছবির URL (Before Proof)',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: afterUrlController,
                      decoration: const InputDecoration(
                        labelText: 'পরের ছবির URL (After Proof)',
                        prefixIcon: Icon(Icons.add_a_photo_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                          if (report.id.trim().isEmpty) return;
                          setModalState(() => isSaving = true);
                          try {
                            ref.read(reportListProvider.notifier).officerUpdateReport(
                              reportId: report.id,
                              newStatus: currentStatus,
                              assignedTeam: teamController.text.trim(),
                              officerComment: commentController.text.trim(),
                              delayReason: delayController.text.trim(),
                              proofBeforeUrl: beforeUrlController.text.trim(),
                              proofAfterUrl: afterUrlController.text.trim(),
                              officerName: _officerProfile.name,
                              recordActivityLog: true,
                            );

                            _reportService.updateOfficerReportInAppwrite(
                              reportId: report.id,
                              status: currentStatus,
                              officerName: _officerProfile.name,
                              assignedTeam: teamController.text.trim(),
                              officerComment: commentController.text.trim(),
                              delayReason: delayController.text.trim(),
                              proofBeforeUrl: beforeUrlController.text.trim(),
                              proofAfterUrl: afterUrlController.text.trim(),
                            );

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (mounted) {
                              setState(() => _selectedFilter = 'ALL');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ স্ট্যাটাস আপডেট সফল: ${currentStatus.labelBangla}'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (error) {
                            debugPrint('Officer status update error: $error');
                            if (ctx.mounted) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('⚠️ সমস্যা: ${error.toString().split('\n').first}'),
                                  backgroundColor: Colors.deepOrange,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('আপডেট সংরক্ষণ করুন'),
                      ),
                    ),

                    // সমাধানকৃত বা বাতিল হলে ডিলিট বাটন দেখানোর লজিক
                    if (currentStatus == ReportStatus.resolved || currentStatus == ReportStatus.rejected) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // মডাল বন্ধ করে দিবে
                            _confirmAndDeleteReport(report); // এরপর ডিলিট ডায়ালগ দেখাবে
                          },
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          label: const Text('এই কাজটি ডিলিট করুন', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalChoiceChip(String label, ReportStatus status, ReportStatus currentStatus, StateSetter setModalState) {
    return ChoiceChip(
      label: Text(label),
      selected: currentStatus == status,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: currentStatus == status ? AppColors.primary : AppColors.textPrimary,
        fontWeight: currentStatus == status ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (s) {
        if (s) setModalState(() => currentStatus = status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifyingRole) {
      // Freeze-proofing: show the shell (AppBar + Back) even while the
      // officer profile / reports are loading, so the user is never stuck.
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('কর্মকর্তা ড্যাশবোর্ড', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text('লোড হচ্ছে...', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    final allReports = ref.watch(reportListProvider);

    final officerReports = allReports.where((r) {
      final dept = _officerProfile.department;
      if (dept == null || dept.isEmpty || dept == 'সব বিভাগ') {
        return true;
      }
      return r.assignedDepartment == null ||
          r.assignedDepartment!.isEmpty ||
          r.assignedDepartment == dept;
    }).toList();

    final assignedCount = officerReports.where((r) => r.status == ReportStatus.assigned).length;
    final highPriorityCount = officerReports.where((r) => r.severity == ReportSeverity.high || r.severity == ReportSeverity.critical).length;
    final acceptedCount = officerReports.where((r) => r.status == ReportStatus.accepted).length;
    final ongoingCount = officerReports.where((r) => r.status == ReportStatus.inProgress).length;
    final resolvedCount = officerReports.where((r) => r.status == ReportStatus.resolved || r.status == ReportStatus.finalVerification).length;
    final delayedCount = officerReports.where((r) => r.status == ReportStatus.onHold || (r.delayReason != null && r.delayReason!.isNotEmpty)).length;

    final filteredReports = officerReports.where((r) {
      final matchesFilter = () {
        if (_selectedFilter == 'HIGH_PRIORITY') return r.severity == ReportSeverity.high || r.severity == ReportSeverity.critical;
        if (_selectedFilter == 'ASSIGNED') return r.status == ReportStatus.assigned;
        if (_selectedFilter == 'ACCEPTED') return r.status == ReportStatus.accepted;
        if (_selectedFilter == 'IN_PROGRESS') return r.status == ReportStatus.inProgress;
        if (_selectedFilter == 'ON_HOLD') return r.status == ReportStatus.onHold;
        if (_selectedFilter == 'RESOLVED') return r.status == ReportStatus.resolved || r.status == ReportStatus.finalVerification;
        if (_selectedFilter == 'DELAYED') return r.status == ReportStatus.onHold || (r.delayReason != null && r.delayReason!.isNotEmpty);
        return true;
      }();

      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();

    filteredReports.sort((a, b) {
      if (a.severity == ReportSeverity.critical && b.severity != ReportSeverity.critical) return -1;
      if (a.severity == ReportSeverity.high && b.severity != ReportSeverity.high) return -1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('কর্মকর্তা ড্যাশবোর্ড', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_officerProfile.name} • ${_officerProfile.department}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAuthenticOfficerProfile,
            tooltip: 'রিফ্রেশ',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'লগআউট',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
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
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          backgroundImage: _officerProfile.profileImageUrl != null && _officerProfile.profileImageUrl!.isNotEmpty
                              ? NetworkImage(_officerProfile.profileImageUrl!)
                              : null,
                          child: _officerProfile.profileImageUrl == null || _officerProfile.profileImageUrl!.isEmpty
                              ? const Icon(Icons.person_rounded, size: 30, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _officerProfile.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: Colors.amber, size: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _officerProfile.assignedArea ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // KPI Section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'কাজের সামারি',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('অর্পিত', '$assignedCount', Icons.assignment_outlined, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('জরুরি', '$highPriorityCount', Icons.warning_amber_rounded, Colors.red)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('গৃহীত', '$acceptedCount', Icons.thumb_up_alt_outlined, Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('চলমান', '$ongoingCount', Icons.autorenew_rounded, Colors.indigo)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('সম্পন্ন', '$resolvedCount', Icons.check_circle_outline_rounded, Colors.green)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('বিলম্বিত', '$delayedCount', Icons.hourglass_bottom_rounded, Colors.purple)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'আইডি, বিষয় বা এলাকা খুঁজুন...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'সব কাজ (${officerReports.length})'),
                          _buildFilterChip('HIGH_PRIORITY', 'জরুরি ($highPriorityCount)'),
                          _buildFilterChip('ASSIGNED', 'অর্পিত ($assignedCount)'),
                          _buildFilterChip('IN_PROGRESS', 'চলমান ($ongoingCount)'),
                          _buildFilterChip('RESOLVED', 'সম্পন্ন ($resolvedCount)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'রিপোর্টের তালিকা (${filteredReports.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

            // Report List
            filteredReports.isEmpty
                ? const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('কোনো রিপোর্ট পাওয়া যায়নি।', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                    final report = filteredReports[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildOfficerReportCard(report),
                    );
                  },
                  childCount: filteredReports.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = key);
        },
      ),
    );
  }

  Widget _buildOfficerReportCard(ReportModel report) {
    final bool isHighRisk = report.severity == ReportSeverity.high || report.severity == ReportSeverity.critical;
    final bool isMedium = report.severity == ReportSeverity.medium;
    final Color priorityColor = isHighRisk ? Colors.red : (isMedium ? Colors.amber[800]! : Colors.green);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        report.severity.labelBangla,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.status.labelBangla,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
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
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: kIsWeb || report.imagePath.startsWith('http') || report.imagePath.startsWith('blob:')
                          ? Image.network(
                        report.imagePath,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                          : (!kIsWeb && File(report.imagePath).existsSync())
                          ? Image.file(File(report.imagePath), fit: BoxFit.cover)
                          : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title.isNotEmpty ? report.title : report.category,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'আইডি: ${report.id} • ${DateFormat('dd MMM, hh:mm a').format(report.createdAt)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (report.delayReason != null && report.delayReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'বিলম্বিত: ${report.delayReason}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => ReportWorkflowDetailsModal.show(context, report),
                    icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
                    label: const Text('বিস্তারিত', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _showOfficerActionModal(report),
                    icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                    label: const Text('আপডেট', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}