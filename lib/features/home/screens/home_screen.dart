import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/remote/appwrite_report_service.dart';
import '../../../models/report_model.dart';
import '../../my_reports/screens/my_reports_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../report/services/report_service.dart';
import '../../notification/services/notification_service.dart';
import '../widgets/recent_report_card.dart';
import '../widgets/report_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _HomeContentTab(),
      const MyReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: AppColors.surface,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: AppStrings.navMyReports,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContentTab extends ConsumerStatefulWidget {
  const _HomeContentTab();

  @override
  ConsumerState<_HomeContentTab> createState() => _HomeContentTabState();
}

class _HomeContentTabState extends ConsumerState<_HomeContentTab> {
  final _service = AppwriteReportService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveReports();
  }

  Future<void> _fetchLiveReports() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final liveReports = await _service.fetchReportsFromAppwrite();
      if (mounted && liveReports.isNotEmpty) {
        ref.read(reportListProvider.notifier).mergeReports(liveReports);
      }
    } catch (e) {
      debugPrint('Error loading home reports handled gracefully: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onStartReportFlow(BuildContext context) {
    Navigator.pushNamed(context, '/create-report');
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportListProvider);
    final inProgressCount = reports
        .where((report) => report.status == ReportStatus.inProgress)
        .length;
    final resolvedCount = reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                AppAssets.logo,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 34,
                  height: 34,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.remove_red_eye_rounded,
                      color: AppColors.primary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notifications = ref.watch(notificationListProvider);
              final unreadCount = notifications.where((n) => !n.read).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'নোটিফিকেশন',
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppColors.primary,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: 'হিটম্যাপ দেখুন',
            onPressed: () => Navigator.pushNamed(context, '/heatmap'),
            icon: const Icon(Icons.map_outlined),
            color: AppColors.primary,
          ),
          IconButton(
            tooltip: 'প্রোফাইল',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.person_outline_rounded),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLiveReports,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.homeGreeting,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(AppStrings.locationBadge,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ReportButton(onPressed: () => _onStartReportFlow(context)),
                  const SizedBox(height: 18),
                  _StatusSummary(
                    total: reports.length,
                    inProgress: inProgressCount,
                    resolved: resolvedCount,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.recentReportsTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  reports.isEmpty
                      ? _EmptyReportsState(
                          isLoading: _isLoading,
                          onCreateReport: () => _onStartReportFlow(context),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reports.length > 3 ? 3 : reports.length,
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            return RecentReportCard(
                              report: report,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/report-details',
                                arguments: report,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final int total;
  final int inProgress;
  final int resolved;

  const _StatusSummary({
    required this.total,
    required this.inProgress,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _SummaryItem(
                value: total, label: 'মোট রিপোর্ট', color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryItem(
                value: inProgress, label: 'চলমান', color: AppColors.secondary)),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryItem(
                value: resolved,
                label: 'সমাধানকৃত',
                color: AppColors.statusResolved)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _SummaryItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCreateReport;

  const _EmptyReportsState(
      {required this.isLoading, required this.onCreateReport});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 42, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(isLoading ? 'রিপোর্ট লোড হচ্ছে...' : AppStrings.noReportsYet,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          if (!isLoading) ...[
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: onCreateReport,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('প্রথম রিপোর্ট তৈরি করুন')),
          ],
        ],
      ),
    );
  }
}
