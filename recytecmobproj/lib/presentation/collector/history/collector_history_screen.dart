import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/collector_job_model.dart';
import '../../../data/repositories/collector_repository.dart';
import '../../../widgets/empty_state.dart';
import '../jobs/job_detail_screen.dart';

class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  final CollectorRepository _repository = CollectorRepository();
  late Future<List<CollectorJob>> _future;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchCompletedJobs();
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _repository.fetchCompletedJobs();
    setState(() => _future = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Collection History'),
        actions: [
          IconButton(
            tooltip: 'Refresh collection history',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<CollectorJob>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(
                message: 'Loading collection history…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load collection history. Please try again.',
              onRetry: _refresh,
            );
          }
          final jobs = snapshot.data ?? const <CollectorJob>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              children: jobs.isEmpty
                  ? const [
                      EmptyState(
                        icon: Icons.history,
                        title: 'You have no completed collection requests yet.',
                        message: 'Completed collections will appear here.',
                      ),
                    ]
                  : jobs.map(_jobCard).toList(growable: false),
            ),
          );
        },
      ),
    );
  }

  Widget _jobCard(CollectorJob job) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        );
        if (mounted) await _refresh();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RecyTechTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.requestCode,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 6.h),
            Text(
                'Partner Organization: ${_value(job.partnerOrganizationName)}'),
            Text('Bin: ${_value(job.displayItem)}'),
            Text('Scheduled: ${_value(job.schedule)}'),
            Text('Status: ${RequestStatuses.label(job.status)}'),
          ],
        ),
      ),
    );
  }

  String _value(String value) => value.trim().isEmpty ? '-' : value;
}
