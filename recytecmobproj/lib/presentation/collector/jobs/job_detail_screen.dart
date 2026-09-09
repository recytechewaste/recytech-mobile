import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/core/utils/helpers.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/presentation/collector/collection/collection_workflow_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final CollectorJob job;

  const JobDetailScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final CollectorRepository _repository = CollectorRepository();
  final MapLauncher _mapLauncher = const MapLauncher();

  late CollectorJob job;
  bool isUpdating = false;
  bool isLoadingDetail = true;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    job = widget.job;
    _loadCanonicalDetail();
  }

  Future<void> _loadCanonicalDetail() async {
    final active = _refreshing;
    if (active != null) return active;

    final refresh = _refreshCanonicalDetail().whenComplete(() {
      _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  Future<void> _refresh() => _loadCanonicalDetail();

  Future<void> _refreshCanonicalDetail() async {
    setState(() => isLoadingDetail = true);
    try {
      final detail = await _repository.fetchRequestDetail(job.id);
      if (mounted) setState(() => job = detail);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                fallback: 'Unable to refresh request details.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _fetchCanonicalAfterUpdate() async {
    try {
      final detail = await _repository.fetchRequestDetail(job.id);
      if (mounted) setState(() => job = detail);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                fallback: 'Unable to refresh request details.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  Future<void> _startCollection() async {
    if (isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final updated = await _repository.updateJobStatus(
        requestId: job.id,
        status: CollectorJobStatuses.inProgress,
        currentStatus: job.status,
      );

      if (!mounted) return;

      setState(() {
        job = updated.id.isEmpty
            ? job.copyWith(
                status: CollectorJobStatuses.inProgress,
                startedAt: DateTime.now().toIso8601String(),
              )
            : updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection started.')),
      );
      await _fetchCanonicalAfterUpdate();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String status, String successMessage) async {
    if (isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final updated = await _repository.updateJobStatus(
        requestId: job.id,
        status: status,
        currentStatus: job.status,
      );

      if (!mounted) return;

      setState(() {
        job = updated.id.isEmpty
            ? job.copyWith(
                status: status,
                updatedAt: DateTime.now().toIso8601String(),
              )
            : updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _fetchCanonicalAfterUpdate();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> _openLocationInMaps() async {
    if (job.location.trim().isEmpty &&
        (job.latitude == null || job.longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No collection location available.')),
      );
      return;
    }

    final launched = await _mapLauncher.open(
      MapLaunchTarget(
        label: job.displayItem,
        address: job.location,
        latitude: job.latitude,
        longitude: job.longitude,
      ),
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _continueCollection() async {
    final completed = await Navigator.push<CollectorJob>(
      context,
      MaterialPageRoute(builder: (_) => CollectionWorkflowScreen(job: job)),
    );

    if (completed != null && mounted) {
      setState(() {
        job = completed;
      });
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh request details',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (isLoadingDetail) const LinearProgressIndicator(),
              if (isLoadingDetail) SizedBox(height: 12.h),
              Text(
                'Request Reference: ${job.requestCode}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: RecyTechTheme.textDark,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: RecyTechTheme.card,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: RecyTechTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: RecyTechTheme.primary.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRow(
                      'Partner Organization',
                      _valueOrDash(job.partnerOrganizationName),
                    ),
                    _infoRow('Bin', _valueOrDash(job.displayItem)),
                    _infoRow('Bin Location', _valueOrDash(job.location)),
                    _infoRow('Coordinates', _coordinatesLabel()),
                    _locationAction(),
                    _infoRow('Requested', _formatDate(job.schedule)),
                    _infoRow('Status', CollectorJobStatuses.label(job.status)),
                    _infoRow('Collector', _valueOrDash(job.assignedCollector)),
                    _infoRow(
                      'Fill',
                      job.fillPercentage == null
                          ? '-'
                          : '${job.fillPercentage!.round()}%',
                    ),
                    _infoRow('Remarks', _valueOrDash(job.remarks)),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              _workflowActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationAction() {
    if (job.location.trim().isEmpty &&
        (job.latitude == null || job.longitude == null)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _openLocationInMaps,
          icon: const Icon(Icons.map_outlined),
          label: const Text('View location on map'),
        ),
      ),
    );
  }

  Widget _workflowActions() {
    final normalized = CollectorJobStatuses.normalize(job.status);
    final canUpdate = !isUpdating && job.id.isNotEmpty;

    switch (normalized) {
      case CollectorJobStatuses.assigned:
        return _primaryAction(
          label: 'Start Trip',
          icon: Icons.directions_car_outlined,
          onPressed: canUpdate
              ? () => _updateStatus(
                    CollectorJobStatuses.onTheWay,
                    'Trip started.',
                  )
              : null,
        );
      case CollectorJobStatuses.onTheWay:
        return _primaryAction(
          label: 'Arrived',
          icon: Icons.location_on_outlined,
          onPressed: canUpdate
              ? () => _updateStatus(
                    CollectorJobStatuses.arrived,
                    'Arrival marked.',
                  )
              : null,
        );
      case CollectorJobStatuses.arrived:
        return _primaryAction(
          label: 'Start Collection',
          icon: Icons.arrow_forward,
          onPressed: canUpdate ? _startCollection : null,
        );
      case CollectorJobStatuses.inProgress:
      case CollectorJobStatuses.readyForCompletion:
        return _primaryAction(
          label: 'Continue Collection',
          icon: Icons.assignment_turned_in_outlined,
          onPressed: canUpdate ? _continueCollection : null,
        );
      case CollectorJobStatuses.completed:
        return const _InfoPanel(message: 'This collection is completed.');
      case CollectorJobStatuses.cancelled:
        return const _InfoPanel(
          message: 'No action is available for this status.',
        );
      default:
        return const _InfoPanel(
          message: 'No action is available for this status.',
        );
    }
  }

  Widget _primaryAction({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isUpdating
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  String _valueOrDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }

  String _coordinatesLabel() {
    if (job.latitude == null || job.longitude == null) return '-';
    return '${job.latitude!.toStringAsFixed(5)}, ${job.longitude!.toStringAsFixed(5)}';
  }

  String _formatDate(String value) {
    if (value.trim().isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.year}-$month-$day $hour:$minute';
  }

  String _messageForError(Object error) {
    return userFacingError(
      error,
      fallback: 'Status update failed. Please try again.',
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.pill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
