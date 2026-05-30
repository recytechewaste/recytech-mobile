import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/presentation/auth/login_screen.dart';
import 'package:recytecmobproj/presentation/collector/jobs/job_detail_screen.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  final CollectorRepository _repository = CollectorRepository();
  final Set<String> _declinedRequestIds = <String>{};

  late Future<List<CollectorJob>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _repository.fetchAvailableJobs();
  }

  Future<void> _refreshJobs() async {
    final future = _repository.fetchAvailableJobs();
    setState(() {
      _jobsFuture = future;
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
    final declinedRequestId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: job),
      ),
    );

    if (declinedRequestId != null && declinedRequestId.isNotEmpty && mounted) {
      setState(() {
        _declinedRequestIds.add(declinedRequestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request declined for this session.'),
        ),
      );
    }

    if (mounted) {
      await _refreshJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Dashboard'),
        centerTitle: false,
        actions: [
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
      body: FutureBuilder<List<CollectorJob>>(
        future: _jobsFuture,
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

          final jobs = (snapshot.data ?? <CollectorJob>[])
              .where((job) => !_declinedRequestIds.contains(job.id))
              .toList();
          final visibleJobs = jobs.take(4).toList();

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
                      'Queue',
                      jobs.length.toString(),
                      Icons.assignment_outlined,
                    ),
                    _summaryCard(
                      context,
                      'Approved',
                      _statusCount(jobs, 'Approved').toString(),
                      Icons.timelapse_outlined,
                    ),
                    _summaryCard(
                      context,
                      'Next',
                      jobs.isEmpty ? '0' : '1',
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
                if (visibleJobs.isEmpty)
                  _emptyCard(context)
                else
                  ...visibleJobs.map(
                    (job) => _jobItem(context, job),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _statusCount(List<CollectorJob> jobs, String status) {
    return jobs
        .where((job) => job.status.toLowerCase() == status.toLowerCase())
        .length;
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
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
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
                  Text(label,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75))),
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

    final bool isPending = job.status.toLowerCase().contains('pending');
    final bool isProgress = job.status.toLowerCase().contains('transit') ||
        job.status.toLowerCase().contains('progress');

    final Color chipBg = isPending
        ? cs.tertiary.withValues(alpha: 0.12)
        : isProgress
            ? cs.secondary.withValues(alpha: 0.12)
            : cs.primary.withValues(alpha: 0.12);

    final Color chipFg = isPending
        ? cs.tertiary
        : isProgress
            ? cs.secondary
            : cs.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openJob(job),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        'No active requests available.',
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
}
