import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/remote/appwrite_auth_service.dart';
import '../../../data/remote/appwrite_notification_service.dart';
import '../../../models/notification_model.dart';
import '../../report/services/report_service.dart';
import '../services/notification_service.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _appwriteNotifService = AppwriteNotificationService();
  final _authService = AppwriteAuthService();
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchNotifications();
  }

  Future<void> _loadUserAndFetchNotifications() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUserId = user.$id;
        });
      }
    } catch (e) {
      debugPrint('Error getting current user in NotificationScreen: $e');
    }
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (_isLoading || _currentUserId == null) return;
    setState(() => _isLoading = true);

    try {
      final liveNotifs = await _appwriteNotifService.fetchNotificationsForUser(_currentUserId!);
      if (mounted && liveNotifs.isNotEmpty) {
        ref.read(notificationListProvider.notifier).mergeNotifications(liveNotifs);
      }
    } catch (e) {
      debugPrint('Error fetching notifications handled gracefully: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case NotificationType.reportApproved:
        return Colors.green;
      case NotificationType.reportRejected:
        return AppColors.statusRejected;
      case NotificationType.reportInProgress:
        return AppColors.secondary;
      case NotificationType.reportResolved:
        return AppColors.statusResolved;
      case NotificationType.reportSubmitted:
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case NotificationType.reportApproved:
        return Icons.verified_rounded;
      case NotificationType.reportRejected:
        return Icons.cancel_rounded;
      case NotificationType.reportInProgress:
        return Icons.hourglass_top_rounded;
      case NotificationType.reportResolved:
        return Icons.check_circle_rounded;
      case NotificationType.reportSubmitted:
      default:
        return Icons.assignment_turned_in_rounded;
    }
  }

  void _onNotificationTap(NotificationModel notif) {
    ref.read(notificationListProvider.notifier).markAsRead(notif.id);

    final reports = ref.read(reportListProvider);
    final targetReport = reports.where((r) => r.id == notif.reportId).firstOrNull;

    if (targetReport != null) {
      Navigator.pushNamed(context, '/report-details', arguments: targetReport);
    }
  }

  void _onDeleteNotification(NotificationModel notif) {
    // ONLY deletes the notification item from state and Appwrite notification collection.
    // DOES NOT touch or delete the report document!
    ref.read(notificationListProvider.notifier).deleteNotification(notif.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ নোটিফিকেশন মুছে ফেলা হয়েছে। (রিপোর্ট অপরিবর্তিত আছে)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNotifs = ref.watch(notificationListProvider);
    final userNotifs = _currentUserId != null
        ? allNotifs.where((n) => n.userId == _currentUserId).toList()
        : <NotificationModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ইন-অ্যাপ নোটিফিকেশন'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'রিফ্রেশ করুন',
            onPressed: _loadUserAndFetchNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserAndFetchNotifications,
        color: AppColors.primary,
        child: userNotifs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textLight),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading ? 'নোটিফিকেশন লোড হচ্ছে...' : 'কোনো নোটিফিকেশন পাওয়া যায়নি।',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: userNotifs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = userNotifs[index];
                  final typeColor = _getTypeColor(notif.type);
                  final typeIcon = _getTypeIcon(notif.type);
                  final formattedTime = DateFormat('dd MMM, hh:mm a').format(notif.createdAt);

                  return Dismissible(
                    key: Key(notif.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.statusRejected,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    onDismissed: (_) => _onDeleteNotification(notif),
                    child: Material(
                      color: notif.read ? Colors.white : AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      child: InkWell(
                        onTap: () => _onNotificationTap(notif),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(typeIcon, color: typeColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.message,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!notif.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                tooltip: 'মুছে ফেলুন',
                                onPressed: () => _onDeleteNotification(notif),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
