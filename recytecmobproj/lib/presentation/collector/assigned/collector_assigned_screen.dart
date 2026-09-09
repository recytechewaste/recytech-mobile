import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/models/collector_profile_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/presentation/collector/collection/collection_workflow_screen.dart';
import 'package:recytecmobproj/presentation/collector/jobs/job_detail_screen.dart';
import 'package:recytecmobproj/widgets/empty_state.dart';
import 'package:recytecmobproj/widgets/status_bagde.dart';

class CollectorAssignedScreen extends StatefulWidget {
  const CollectorAssignedScreen({super.key});

  @override
  State<CollectorAssignedScreen> createState() =>
      _CollectorAssignedScreenState();
}

class _CollectorAssignedScreenState extends State<CollectorAssignedScreen> {
  final CollectorRepository _repository = CollectorRepository();

  late Future<List<CollectorJob>> _jobsFuture;
  late Future<CollectorProfile> _profileFuture;
  String? _updatingRequestId;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchAssignedJobs();
    _profileFuture = _repository.fetchProfile();
  }

  Future<List<CollectorJob>> _fetchAssignedJobs() {
    return _repository.fetchAssignedJobs();
  }

  Future<void> _refreshJobs() async {
    final future = _fetchAssignedJobs();
    final profileFuture = _repository.fetchProfile();
    setState(() {
      _jobsFuture = future;
      _profileFuture = profileFuture;
    });

    try {
      await Future.wait([future, profileFuture]);
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

  Future<void> _continueCollection(CollectorJob job) async {
    await Navigator.push<CollectorJob>(
      context,
      MaterialPageRoute(builder: (_) => CollectionWorkflowScreen(job: job)),
    );

    if (mounted) {
      await _refreshJobs();
    }
  }

  Future<void> _updateStatus(CollectorJob job, String status) async {
    if (_updatingRequestId != null || job.id.isEmpty) return;

    setState(() => _updatingRequestId = job.id);
    try {
      await _repository.updateJobStatus(
        requestId: job.id,
        status: status,
        currentStatus: job.status,
      );
      if (mounted) await _refreshJobs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForError(e))),
      );
    } finally {
      if (mounted) setState(() => _updatingRequestId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Assigned Requests'),
      ),
      body: FutureBuilder<List<CollectorJob>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading assigned requests…');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load assigned requests. Please try again.',
              onRetry: _refreshJobs,
            );
          }

          final jobs = snapshot.data ?? <CollectorJob>[];

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: jobs.isEmpty
                ? ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _profileSummary(),
                      SizedBox(height: 12.h),
                      _messageState(
                        context,
                        'You have no assigned collection requests right now.',
                        message:
                            'New collection requests will appear here when they are assigned to you.',
                      ),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _profileSummary(),
                      SizedBox(height: 12.h),
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

  Widget _profileSummary() {
    return FutureBuilder<CollectorProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();
        final name = profile.fullName.isEmpty ? 'Collector' : profile.fullName;
        final vehicle = [profile.vehicleType, profile.vehiclePlate]
            .where((value) => value.trim().isNotEmpty)
            .join(' • ');
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: RecyTechTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: RecyTechTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style:
                      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
              if (vehicle.isNotEmpty) Text(vehicle),
              SizedBox(height: 6.h),
              Text(
                '${profile.isActive ? 'On Duty' : 'Off Duty'}  •  '
                '${profile.activeJobs} active  •  '
                '${profile.completedJobs} completed',
                style:
                    TextStyle(color: RecyTechTheme.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
        );
      },
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
        '$count current collection request${count == 1 ? '' : 's'}. Complete the active collection before starting another.',
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
          color: RecyTechTheme.card,
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
            Text(
                'Partner Organization: ${_valueOrDash(job.partnerOrganizationName)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            Text('Location: ${_valueOrDash(job.location)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            Text('Smart bin: ${_valueOrDash(job.displayItem)}',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark)),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: StatusBadge(label: job.status),
            ),
            SizedBox(height: 12.h),
            _actionButton(job),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(CollectorJob job) {
    final normalized = CollectorJobStatuses.normalize(job.status);
    final isUpdating = _updatingRequestId == job.id;

    if (normalized == CollectorJobStatuses.completed) {
      return const SizedBox.shrink();
    }

    late final String label;
    late final VoidCallback? onPressed;

    switch (normalized) {
      case CollectorJobStatuses.assigned:
        label = 'Start Trip';
        onPressed = isUpdating
            ? null
            : () => _updateStatus(job, CollectorJobStatuses.onTheWay);
      case CollectorJobStatuses.onTheWay:
        label = 'Arrived';
        onPressed = isUpdating
            ? null
            : () => _updateStatus(job, CollectorJobStatuses.arrived);
      case CollectorJobStatuses.arrived:
        label = 'Start Collection';
        onPressed = isUpdating
            ? null
            : () => _updateStatus(job, CollectorJobStatuses.inProgress);
      case CollectorJobStatuses.inProgress:
      case CollectorJobStatuses.readyForCompletion:
        label = 'Continue Collection';
        onPressed = isUpdating ? null : () => _continueCollection(job);
      case CollectorJobStatuses.completed:
      case CollectorJobStatuses.cancelled:
        label = 'View Details';
        onPressed = isUpdating ? null : () => _openJob(job);
      default:
        label = 'View Details';
        onPressed = isUpdating ? null : () => _openJob(job);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: isUpdating
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }

  String _valueOrDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }

  Widget _messageState(
    BuildContext context,
    String title, {
    String? message,
    String? actionLabel,
    Future<void> Function()? onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: EmptyState(
        icon: actionLabel == null
            ? Icons.assignment_outlined
            : Icons.error_outline,
        title: title,
        message: message,
        action: actionLabel == null || onPressed == null
            ? null
            : OutlinedButton(
                onPressed: () => onPressed(),
                child: Text(actionLabel),
              ),
      ),
    );
  }

  String _messageForError(Object error) {
    return 'Unable to load assigned requests. Please try again.';
  }
}
