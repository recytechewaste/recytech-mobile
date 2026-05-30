import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
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
  final Set<String> _declinedRequestIds = <String>{};

  late Future<List<CollectorJob>> _jobsFuture;
  String? _busyRequestId;

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

  Future<void> _acceptJob(CollectorJob job) async {
    if (_busyRequestId != null || job.id.isEmpty) return;

    setState(() {
      _busyRequestId = job.id;
    });

    CollectorJob? acceptedJob;

    try {
      final collector = context.read<AuthProvider>().currentUser;
      final collectorName = _collectorName(collector);
      final updated = await _repository.acceptJob(
        requestId: job.id,
        collectorId: collector?.id,
        collectorName: collectorName,
        collectorEmail: collector?.email,
      );

      if (!mounted) return;

      acceptedJob = updated.id.isEmpty
          ? job.copyWith(
              status: 'In-Transit',
              assignedCollector: collectorName,
              assignedCollectorId: collector?.id,
            )
          : updated;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${job.requestCode} accepted.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyRequestId = null;
        });
      }
    }

    if (acceptedJob == null || !mounted) return;

    await _refreshJobs();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: acceptedJob!),
      ),
    );

    if (mounted) {
      await _refreshJobs();
    }
  }

  void _declineJob(CollectorJob job) {
    if (job.id.isEmpty) return;

    setState(() {
      _declinedRequestIds.add(job.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${job.requestCode} declined for this session.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          final jobs = (snapshot.data ?? <CollectorJob>[])
              .where((job) => !_declinedRequestIds.contains(job.id))
              .toList();

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: jobs.isEmpty
                ? ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _messageState(
                        context,
                        'No approved collector requests available.',
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
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count approved request${count == 1 ? '' : 's'} in FIFO queue. Oldest request is shown first.',
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.green.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _requestCard(BuildContext context, CollectorJob job, int position) {
    final isBusy = _busyRequestId == job.id;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isBusy ? null : () => _openJob(job),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
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
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    position == 1 ? 'Next' : '#$position',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text('Resident: ${_valueOrDash(job.residentName)}',
                style: TextStyle(fontSize: 12.sp)),
            Text('Location: ${_valueOrDash(job.location)}',
                style: TextStyle(fontSize: 12.sp)),
            Text('Item: ${_valueOrDash(job.displayItem)}',
                style: TextStyle(fontSize: 12.sp)),
            Text('Waste type: ${_valueOrDash(job.wasteType)}',
                style: TextStyle(fontSize: 12.sp)),
            Text('Quantity: ${job.quantity}',
                style: TextStyle(fontSize: 12.sp)),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : () => _declineJob(job),
                    child: const Text('Decline'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : () => _acceptJob(job),
                    child: isBusy
                        ? SizedBox(
                            height: 18.h,
                            width: 18.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value == 'completed') return Colors.green;
    if (value.contains('transit') || value.contains('approved')) {
      return Colors.orange;
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
