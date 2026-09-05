import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/remote/appwrite_auth_service.dart';
import '../../../data/remote/appwrite_report_service.dart';
import '../../../models/report_model.dart';
import '../../home/widgets/recent_report_card.dart';
import '../../report/services/report_service.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  final _appwriteService = AppwriteReportService();
  final _authService = AppwriteAuthService();
  bool _isLoading = false;
  String? _currentUserId;

  Future<void> _loadUserAndFetchReports() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (mounted && currentUser != null) {
        setState(() {
          _currentUserId = currentUser.$id;
        });
      }
    } catch (e) {
      debugPrint('Error getting current user in MyReportsScreen: $e');
    }
    await _fetchAppwriteReports();
  }

  Future<void> _fetchAppwriteReports() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final liveReports = await _appwriteService.fetchReportsFromAppwrite();
      if (mounted && liveReports.isNotEmpty) {
        ref.read(reportListProvider.notifier).mergeReports(liveReports);
      }
    } catch (e) {
      debugPrint('Error fetching reports in MyReportsScreen handled gracefully: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchReports();
  }

  @override
  Widget build(BuildContext context) {
    final allReports = ref.watch(reportListProvider);
    final userReports = _currentUserId != null
        ? allReports.where((r) => r.userId == _currentUserId).toList()
        : <ReportModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navMyReports),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'রিফ্রেশ করুন',
            onPressed: _loadUserAndFetchReports,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserAndFetchReports,
        color: AppColors.primary,
        child: userReports.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.textLight),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading
                          ? 'তথ্য লোড হচ্ছে...'
                          : AppStrings.noReportsYet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: userReports.length,
                itemBuilder: (context, index) {
                  final report = userReports[index];
                  return RecentReportCard(
                    report: report,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/report-details',
                        arguments: report,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
