import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/recytechtheme.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../widgets/empty_state.dart';
import '../lgu/bins/bin_details_screen.dart';
import '../user/history/history_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationRepository _repository = NotificationRepository();
  late Future<List<NotificationModel>> _future;
  bool _isUpdating = false;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchNotifications(widget.role);
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _repository.fetchNotifications(widget.role);
    setState(() => _future = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    setState(() => _isUpdating = true);
    try {
      await _repository.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        _future = _repository.fetchNotifications(widget.role);
      });
    } catch (_) {
      if (mounted) _showMessage('Unable to update notification.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await _repository.markAllAsRead(widget.role);
      if (!mounted) return;
      setState(() {
        _future = _repository.fetchNotifications(widget.role);
      });
    } catch (_) {
      if (mounted) _showMessage('Unable to update notifications.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openNotification(NotificationModel notification) async {
    await _markAsRead(notification);
    if (!mounted) return;

    final destination = notification.destination;
    if (destination == null) {
      _showMessage('No linked screen is available for this notification.');
      return;
    }

    switch (destination.kind) {
      case NotificationDestinationKind.householdDropOff:
        if (widget.role != UserRole.household) {
          _showMessage('This notification is outside your role permissions.');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
        if (mounted) await _refresh();
      case NotificationDestinationKind.lguRequest:
        _showMessage(
          'Open Requests to view this Partner Organization collection request.',
        );
      case NotificationDestinationKind.lguBin:
        if (widget.role != UserRole.partnerOrg ||
            destination.entityId == null) {
          _showMessage('This notification is outside your role permissions.');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BinDetailsScreen(binId: destination.entityId!),
          ),
        );
        if (mounted) await _refresh();
      case NotificationDestinationKind.collectorAssignment:
        _showMessage(
          'Open Assigned Requests to view this collection request.',
        );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: _isUpdating ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: _isUpdating ? null : _markAllAsRead,
            child: const Text('Read all'),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading notifications…');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load notifications. Please try again.',
              onRetry: _refresh,
            );
          }

          final notifications = snapshot.data ?? <NotificationModel>[];
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _state(
                icon: Icons.notifications_none,
                title: 'You have no notifications right now.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              children: notifications.map(_notificationTile).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _notificationTile(NotificationModel notification) {
    final color = _iconColor(notification.type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openNotification(notification),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? RecyTechTheme.border
                : RecyTechTheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(_iconFor(notification.type), size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: RecyTechTheme.textDark,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: RecyTechTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _formatDate(notification.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: RecyTechTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      children: [
        EmptyState(
          icon: icon,
          title: title,
          message: message,
          action: action,
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('assignment')) return Icons.assignment_outlined;
    if (type.contains('bin') || type.contains('sensor')) {
      return Icons.delete_outline;
    }
    if (type.contains('reward') || type.contains('payout')) {
      return Icons.payments_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _iconColor(String type) {
    if (type.contains('alert') || type.contains('urgent')) {
      return RecyTechTheme.warning;
    }
    if (type.contains('cancel') || type.contains('reject')) {
      return RecyTechTheme.danger;
    }
    return RecyTechTheme.primary;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
