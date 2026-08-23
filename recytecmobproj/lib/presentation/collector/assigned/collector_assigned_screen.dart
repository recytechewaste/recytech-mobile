import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/presentation/collector/jobs/job_detail_screen.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

class CollectorAssignedScreen extends StatefulWidget {
  const CollectorAssignedScreen({super.key});

  @override
  State<CollectorAssignedScreen> createState() =>
      _CollectorAssignedScreenState();
}

class _CollectorAssignedScreenState extends State<CollectorAssignedScreen> {
  final CollectorRepository _repository = CollectorRepository();

  late Future<List<CollectorJob>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchAssignedJobs();
  }

  Future<List<CollectorJob>> _fetchAssignedJobs() {
    final collector = context.read<AuthProvider>().currentUser;
    final collectorName = _collectorName(collector);

    return _repository.fetchAssignedJobs(
      collectorId: collector?.id,
      collectorName: collectorName,
      collectorEmail: collector?.email,
    );
  }

  Future<void> _refreshJobs() async {
    final future = _fetchAssignedJobs();
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
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Collector Requests'),
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
              'Unable to load assigned requests.',
              actionLabel: 'Retry',
              onPressed: _refreshJobs,
            );
          }

          final jobs = snapshot.data ?? <CollectorJob>[];

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: jobs.isEmpty
                ? ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _messageState(
                        context,
                        'No assigned collection tasks yet.',
                      ),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _queueNotice(context, jobs.length),
                      SizedBox(height: 12.h),
                      for (var i = 0; i < jobs.length; i++)
                        _requestCard(context, jobs[i], i + 1),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _queueNotice(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.pill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RecyTechTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count assigned collection task${count == 1 ? '' : 's'}. Nearest scheduled tasks appear first.',
        style: TextStyle(
          fontSize: 11.sp,
          color: RecyTechTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _requestCard(BuildContext context, CollectorJob job, int position) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openJob(job),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RecyTechTheme.border),
          boxShadow: [
            BoxShadow(
              color: RecyTechTheme.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.requestCode,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: position == 1
                        ? RecyTechTheme.primary.withValues(alpha: 0.12)
                        : RecyTechTheme.pill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    position == 1 ? 'Next' : '#$position',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: position == 1
                          ? RecyTechTheme.primary
                          : RecyTechTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text('Resident: ${_valueOrDash(job.residentName)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            Text('Location: ${_valueOrDash(job.location)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            Text('Item: ${_valueOrDash(job.displayItem)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            Text('Waste type: ${_valueOrDash(job.wasteType)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            Text('Quantity: ${job.quantity}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                job.status,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(job.status),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openJob(job),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value == 'completed') return RecyTechTheme.primary;
    if (value.contains('transit') || value.contains('approved')) {
      return RecyTechTheme.accent;
    }
    return Colors.redAccent;
  }

  String _valueOrDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }

  String _collectorName(UserModel? user) {
    if (user == null) return '';
    if (user.fullName.trim().isNotEmpty) return user.fullName.trim();

    return [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  Widget _messageState(
    BuildContext context,
    String message, {
    String? actionLabel,
    Future<void> Function()? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onPressed != null) ...[
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: () => onPressed(),
                child: Text(actionLabel),
              ),
            ],
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

    return 'Unable to refresh assigned requests.';
  }
}
