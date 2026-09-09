import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/collection_request_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/status_bagde.dart';

class CollectionRequestFormScreen extends StatefulWidget {
  const CollectionRequestFormScreen({
    super.key,
    required this.bin,
    this.repository,
  });

  final RecyTechBin bin;
  final CollectionRequestRepository? repository;

  @override
  State<CollectionRequestFormScreen> createState() =>
      _CollectionRequestFormScreenState();
}

class _CollectionRequestFormScreenState
    extends State<CollectionRequestFormScreen> {
  late final CollectionRequestRepository _repository;
  final TextEditingController _remarks = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiCollectionRequestRepository();
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final requestBinId = widget.bin.requestBinId.trim();
    if (requestBinId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Collection request could not be created: This bin is missing its backend request identifier.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      await _repository.createCollectionRequest(
        lguId: widget.bin.assignedLguId ?? '',
        binId: requestBinId,
        binLocation: widget.bin.location,
        fillPercentage: widget.bin.fillPercentage,
        fullnessStatus: widget.bin.fullnessStatus,
        requestedAt: DateTime.now(),
        remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection request created.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final message = e is DuplicateCollectionRequestException
          ? e.message
          : e is CollectionRequestException
              ? 'Collection request could not be created: ${e.message}'
              : 'Unable to create request. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bin = widget.bin;
    final activeRequest = bin.hasActiveCollectionRequest;

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Request Collection')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _summary(bin),
            SizedBox(height: 14.h),
            TextField(
              controller: _remarks,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Add collection notes for the collector',
              ),
            ),
            SizedBox(height: 18.h),
            PrimaryButton(
              text: activeRequest ? 'Active Request Exists' : 'Submit Request',
              onPressed: activeRequest || _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(RecyTechBin bin) {
    final fullnessLabel = FullnessStatuses.label(bin.fullnessStatus);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bin.displayName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: RecyTechTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          _row(
            'Partner Organization',
            bin.partnerOrganizationName ?? bin.assignedLguId ?? 'Demo Partner',
          ),
          _row('Bin ID', bin.binId),
          _row('Location', bin.location),
          _row(
            'Fill',
            bin.fillPercentage == null
                ? '-'
                : '${bin.fillPercentage!.round()}%',
          ),
          _row('Fullness', fullnessLabel),
          _row('Reading timestamp', formatDateTime(bin.lastUpdatedAt)),
          _row('Reading status',
              SensorReadingFreshness.status(bin.lastUpdatedAt)),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              StatusBadge(label: fullnessLabel),
              StatusBadge(
                  label: 'Sensor: ${SensorStatuses.label(bin.sensorStatus)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
