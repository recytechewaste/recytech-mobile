// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../bin_monitoring/widgets/bin_monitoring_components.dart';

class DepositDetectionDetailsScreen extends StatefulWidget {
  const DepositDetectionDetailsScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<DepositDetectionDetailsScreen> createState() =>
      _DepositDetectionDetailsScreenState();
}

class _DepositDetectionDetailsScreenState
    extends State<DepositDetectionDetailsScreen> {
  final BinMonitoringService _service = MockBinMonitoringService();
  late Future<DepositEvent> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = _service.fetchDepositEvent(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Deposit Details'),
      ),
      body: FutureBuilder<DepositEvent>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('Deposit event not found.'));
          }

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              CapturedObjectImage(
                imageUrl: event.imageUrl,
                height: 230.h,
              ),
              SizedBox(height: 14.h),
              if (event.isLowConfidence) ...[
                const LowConfidenceWarning(),
                SizedBox(height: 14.h),
              ],
              _panel(
                children: [
                  _infoRow('Deposit event ID', event.id),
                  _infoRow('Bin ID', event.binId),
                  _infoRow('Camera ID', event.cameraId),
                  _infoRow('Captured at', formatDateTime(event.capturedAt)),
                  _infoRow('Detection status', event.status),
                  _infoRow('Verification status', event.verificationStatus),
                  _infoRow('Error status', event.errorStatus ?? '-'),
                ],
              ),
              SizedBox(height: 14.h),
              _sectionTitle('Identification recommendations'),
              for (final detection in event.detections)
                _detectionPanel(detection),
            ],
          );
        },
      ),
    );
  }

  Widget _detectionPanel(ObjectDetection detection) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detection.objectClass,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              DetectionConfidenceChip(
                confidence: detection.confidence,
                lowConfidence: detection.confidence < 0.70,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _infoRow('Mapped category', detection.mappedCategory),
          _infoRow('Model version', detection.modelVersion),
          _infoRow(
            'Bounding box',
            'x ${detection.boundingBox.x.toStringAsFixed(0)}, y ${detection.boundingBox.y.toStringAsFixed(0)}, w ${detection.boundingBox.width.toStringAsFixed(0)}, h ${detection.boundingBox.height.toStringAsFixed(0)}',
          ),
          _infoRow(
            'Verified',
            detection.isVerified ? (detection.verifiedClass ?? 'Yes') : 'No',
          ),
        ],
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w900,
          color: RecyTechTheme.textDark,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122.w,
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
