import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/presentation/auth/login_screen.dart';
import 'package:recytecmobproj/presentation/collector/jobs/job_detail_screen.dart';
import 'package:recytecmobproj/presentation/notifications/notification_center_screen.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  final CollectorRepository _repository = CollectorRepository();

  late Future<_CollectorHomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
  }

  Future<_CollectorHomeData> _loadHomeData() async {
    final collector = context.read<AuthProvider>().currentUser;
    final collectorName = _collectorName(collector);
    final results = await Future.wait([
      _repository.fetchAvailableJobs(),
      _repository.fetchAssignedJobs(
        collectorId: collector?.id,
        collectorName: collectorName,
        collectorEmail: collector?.email,
      ),
    ]);

    return _CollectorHomeData(
      availableJobs: results[0],
      assignedJobs: results[1],
    );
  }

  Future<void> _refreshJobs() async {
    final future = _loadHomeData();
    setState(() {
      _homeFuture = future;
    });

    try {
      await future;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForError(e))),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.route,
      (route) => false,
    );
  }

  Future<void> _openJob(CollectorJob job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );

    if (mounted) {
      await _refreshJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Collector Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(
                    role: UserRole.collector,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Refresh jobs',
            onPressed: _refreshJobs,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                _refreshJobs();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_CollectorHomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _messageState(
              context,
              title: 'Unable to load collector jobs.',
              actionLabel: 'Retry',
              onPressed: _refreshJobs,
            );
          }

          final data = snapshot.data ?? const _CollectorHomeData();
          final availableJobs = data.availableJobs;
          final assignedJobs = data.assignedJobs;
          final nextJob = _nextJob(availableJobs, assignedJobs);

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Text(
                  "Today's Overview",
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryCard(
                      context,
                      'Available',
                      availableJobs.length.toString(),
                      Icons.assignment_outlined,
                    ),
                    _summaryCard(
                      context,
                      'Assigned',
                      assignedJobs.length.toString(),
                      Icons.timelapse_outlined,
                    ),
                    _summaryCard(
                      context,
                      'Next Pickup',
                      nextJob?.requestCode ?? 'None',
                      Icons.check_circle_outline,
                    ),
                  ],
                ),
                SizedBox(height: 22.h),
                Text(
                  'Available Requests',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10.h),
                if (availableJobs.isEmpty)
                  _emptyCard(context)
                else
                  ...availableJobs.map(
                    (job) => _jobItem(context, job),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  CollectorJob? _nextJob(
    List<CollectorJob> availableJobs,
    List<CollectorJob> assignedJobs,
  ) {
    final scheduledAssigned = assignedJobs
        .where((job) => job.scheduledDate != null)
        .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));

    if (scheduledAssigned.isNotEmpty) return scheduledAssigned.first;
    if (availableJobs.isNotEmpty) return availableJobs.first;
    return null;
  }

  Widget _summaryCard(
      BuildContext context, String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RecyTechTheme.border),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.onPrimary, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      fontSize: 10.sp,
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

  Widget _jobItem(BuildContext context, CollectorJob job) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final chipFg = _statusColor(context, job.status);
    final chipBg = chipFg.withValues(alpha: 0.12);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openJob(job),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RecyTechTheme.border),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.requestCode,
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  SizedBox(height: 2.h),
                  Text(job.location.isEmpty ? 'No location' : job.location,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75))),
                  SizedBox(height: 2.h),
                  Text(job.displayItem,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65))),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: chipFg.withValues(alpha: 0.25)),
              ),
              child: Text(
                job.status,
                style: tt.bodySmall?.copyWith(
                  color: chipFg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(
        'No approved unassigned requests available.',
        style:
            tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
      ),
    );
  }

  Widget _messageState(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required Future<void> Function() onPressed,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: () => onPressed(),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  String _messageForError(Object error) {
    final text = error.toString();
    const marker = 'message: ';
    if (text.contains(marker)) {
      return text.split(marker).last.replaceAll(')', '').trim();
    }

    return 'Unable to refresh collector jobs.';
  }

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    final value = status.toLowerCase();

    if (value == 'pending') return cs.tertiary;
    if (value == 'approved' || value == 'assigned') return RecyTechTheme.accent;
    if (value.contains('transit') ||
        value.contains('pickup') ||
        value.contains('progress')) {
      return cs.secondary;
    }
    if (value == 'completed' || value == 'collected') {
      return RecyTechTheme.primary;
    }
    if (value == 'rejected' || value == 'cancelled' || value == 'canceled') {
      return Colors.redAccent;
    }

    return cs.primary;
  }

  String _collectorName(UserModel? user) {
    if (user == null) return '';
    if (user.fullName.trim().isNotEmpty) return user.fullName.trim();

    return [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
  }
}

class _CollectorHomeData {
  const _CollectorHomeData({
    this.availableJobs = const <CollectorJob>[],
    this.assignedJobs = const <CollectorJob>[],
  });

  final List<CollectorJob> availableJobs;
  final List<CollectorJob> assignedJobs;
}
