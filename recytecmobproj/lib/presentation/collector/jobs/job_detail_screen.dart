import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/presentation/collector/collection/collection_workflow_screen.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    job = widget.job;
  }

  Future<void> _updateStatus(String logicalStatus) async {
    if (isUpdating) return;

    final current = CollectorJobStatuses.normalize(job.status);
    final next = CollectorJobStatuses.normalize(logicalStatus);
    if (current == next) return;

    if (!CollectorJobStatuses.canTransition(current, next)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Complete the required prior step first.')),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final collector = next == CollectorJobStatuses.onTheWay
          ? context.read<AuthProvider>().currentUser
          : null;
      final collectorName = _collectorName(collector);
      final updated = await _repository.updateJobStatus(
        requestId: job.id,
        status: CollectorJobStatuses.backendValue(logicalStatus),
        collectorId: collector?.id,
        collectorName: collectorName,
        collectorEmail: collector?.email,
      );

      if (!mounted) return;

      setState(() {
        job = updated.id.isEmpty
            ? job.copyWith(
                status: CollectorJobStatuses.backendValue(logicalStatus),
                assignedCollector: collectorName.isEmpty
                    ? job.assignedCollector
                    : collectorName,
                assignedCollectorId: collector?.id,
              )
            : updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request marked as ${CollectorJobStatuses.label(logicalStatus)}.',
          ),
        ),
      );
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
    final query = job.location.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pickup location available.')),
      );
      return;
    }

    final launched = await _mapLauncher.open(
      MapLaunchTarget(address: query),
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _startOrContinueCollection() async {
    final current = CollectorJobStatuses.normalize(job.status);
    if (current == CollectorJobStatuses.arrived) {
      await _updateStatus(CollectorJobStatuses.inProgress);
    }

    if (!mounted) return;
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CollectionWorkflowScreen(job: job)),
    );

    if (completed == true && mounted) {
      setState(() {
        job = job.copyWith(
          status: CollectorJobStatuses.backendValue(
            CollectorJobStatuses.completed,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
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
                color: Colors.white,
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
                  _infoRow('Resident', _valueOrDash(job.residentName)),
                  _infoRow('LGU', _valueOrDash(job.assignedCollector)),
                  _infoRow('Bin', _valueOrDash(job.displayItem)),
                  _infoRow('Item', _valueOrDash(job.displayItem)),
                  _infoRow('Waste Type', _valueOrDash(job.wasteType)),
                  _infoRow('Bin Location', _valueOrDash(job.location)),
                  _locationAction(),
                  _infoRow('Quantity', job.quantity.toString()),
                  _infoRow('Rate / kg', _formatMoney(job.ratePerKg)),
                  _infoRow('Email', _valueOrDash(job.residentEmail)),
                  _infoRow('Phone', _valueOrDash(job.phone)),
                  _infoRow('Status', CollectorJobStatuses.label(job.status)),
                  _infoRow('Collector', _valueOrDash(job.assignedCollector)),
                  _infoRow('Scheduled', _formatDate(job.scheduledAt)),
                  _infoRow('Priority', _priorityLabel()),
                  _infoRow('Remarks', _valueOrDash(job.detectedClass)),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Waste Image',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: RecyTechTheme.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            _imagePreview(),
            SizedBox(height: 24.h),
            _workflowActions(),
          ],
        ),
      ),
    );
  }

  Widget _locationAction() {
    if (job.location.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _openLocationInMaps,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Open in Google Maps'),
        ),
      ),
    );
  }

  Widget _workflowActions() {
    final normalized = CollectorJobStatuses.normalize(job.status);
    final next = CollectorJobStatuses.next(normalized);
    final canUpdate = !isUpdating && job.id.isNotEmpty;

    if (normalized == CollectorJobStatuses.completed) {
      return const _InfoPanel(message: 'This collection is completed.');
    }

    if (normalized == CollectorJobStatuses.inProgress ||
        normalized == CollectorJobStatuses.readyForCompletion) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canUpdate ? _startOrContinueCollection : null,
          icon: const Icon(Icons.assignment_turned_in_outlined),
          label: Text(
            normalized == CollectorJobStatuses.readyForCompletion
                ? 'Review Report'
                : 'Continue Collection',
          ),
        ),
      );
    }

    final label = next == CollectorJobStatuses.onTheWay
        ? 'On The Way'
        : next == CollectorJobStatuses.arrived
            ? 'Arrived'
            : next == CollectorJobStatuses.inProgress
                ? 'Start Collection'
                : null;

    if (label == null) {
      return const _InfoPanel(
          message: 'No action is available for this status.');
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canUpdate
            ? () {
                if (next == CollectorJobStatuses.inProgress) {
                  _startOrContinueCollection();
                } else {
                  _updateStatus(next!);
                }
              }
            : null,
        icon: isUpdating
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward),
        label: Text(label),
      ),
    );
  }

  Widget _imagePreview() {
    final image = job.wasteImage.trim();

    if (image.isEmpty) {
      return _placeholderBox('No waste image available.');
    }

    if (image.startsWith('data:image/')) {
      final bytes = _decodeDataImage(image);
      if (bytes == null) return _placeholderBox('Unable to display image.');

      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 170.h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _placeholderBox('Unable to display image.'),
        ),
      );
    }

    if (!image.startsWith('http://') && !image.startsWith('https://')) {
      return _placeholderBox(image);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        image,
        width: double.infinity,
        height: 170.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderBox(image),
      ),
    );
  }

  Uint8List? _decodeDataImage(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0 || commaIndex == value.length - 1) return null;

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _placeholderBox(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.pill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted),
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

  String _collectorName(UserModel? user) {
    if (user == null) return '';
    if (user.fullName.trim().isNotEmpty) return user.fullName.trim();

    return [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
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

  String _formatMoney(double value) {
    if (value <= 0) return '-';
    return 'PHP ${value.toStringAsFixed(2)}';
  }

  String _priorityLabel() {
    if (job.quantity >= 5) return 'High';
    if (job.quantity >= 2) return 'Normal';
    return 'Standard';
  }

  String _messageForError(Object error) {
    final text = error.toString();
    const marker = 'message: ';
    if (text.contains(marker)) {
      return text.split(marker).last.replaceAll(')', '').trim();
    }

    return 'Status update failed. Please try again.';
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
