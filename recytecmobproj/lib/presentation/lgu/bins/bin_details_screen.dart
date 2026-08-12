import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';
import '../requests/collection_request_form_screen.dart';

class BinDetailsScreen extends StatefulWidget {
  const BinDetailsScreen({
    super.key,
    required this.binId,
  });

  final String binId;

  @override
  State<BinDetailsScreen> createState() => _BinDetailsScreenState();
}

class _BinDetailsScreenState extends State<BinDetailsScreen> {
  final LguBinRepository _repository = MockBinMonitoringService();
  late Future<_BinDetailsData> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<_BinDetailsData> _loadDetails() async {
    final results = await Future.wait([
      _repository.fetchBin(widget.binId),
      _repository.fetchMonitoring(widget.binId),
    ]);
    return _BinDetailsData(
      bin: results[0] as RecyTechBin,
      monitoring: results[1] as BinMonitoringData,
    );
  }

  Future<void> _refresh() async {
    final future = _loadDetails();
    setState(() => _detailsFuture = future);
    await future;
  }

  Future<void> _requestCollection(RecyTechBin bin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionRequestFormScreen(bin: bin),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Bin Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh details',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_BinDetailsData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _messageState('Unable to load bin details.');
          }

          final data = snapshot.data;
          if (data == null) return _messageState('No bin details available.');

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (FullnessStatuses.normalize(data.bin.fullnessStatus) ==
                    FullnessStatuses.full)
                  _recommendationBanner(),
                _conditionPanel(data.bin, data.monitoring),
                SizedBox(height: 18.h),
                ElevatedButton.icon(
                  onPressed: data.bin.hasActiveCollectionRequest
                      ? null
                      : () => _requestCollection(data.bin),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(
                    data.bin.hasActiveCollectionRequest
                        ? 'Collection Request Active'
                        : 'Request Collection',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _recommendationBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, color: Colors.orange.shade800),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This bin is full. Review the reading and submit a collection request when ready.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conditionPanel(RecyTechBin bin, BinMonitoringData monitoring) {
    final fullnessLabel = FullnessStatuses.label(monitoring.fullnessStatus);
    final sensorLabel = SensorStatuses.label(monitoring.sensorStatus);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
          SizedBox(height: 4.h),
          _infoRow('Bin ID', bin.binId),
          _infoRow('LGU ID', bin.assignedLguId ?? '-'),
          _infoRow('Location', bin.location),
          _infoRow('Distance', _distanceLabel(monitoring.distanceCm)),
          _infoRow('Sensor reading', formatDateTime(monitoring.lastUpdatedAt)),
          _infoRow('Last collection', formatDateTime(bin.lastCollectionAt)),
          SizedBox(height: 12.h),
          FillLevelIndicator(
            fillLevel: monitoring.fillPercentage,
            status: fullnessLabel,
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              StatusBadge(label: fullnessLabel),
              StatusBadge(label: 'Sensor: $sensorLabel'),
              if ((monitoring.controllerStatus ?? '').trim().isNotEmpty)
                StatusBadge(
                  label: 'Controller: ${monitoring.controllerStatus}',
                ),
            ],
          ),
          if (bin.activeCollectionRequest != null) ...[
            SizedBox(height: 12.h),
            EmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Active request',
              message:
                  '${bin.activeCollectionRequest!.id} - ${CollectionRequestStatuses.label(bin.activeCollectionRequest!.status)}',
            ),
          ],
        ],
      ),
    );
  }

  String _distanceLabel(double? distanceCm) {
    if (distanceCm == null) return 'Not supplied';
    return '${distanceCm.toStringAsFixed(1)} cm';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
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

  Widget _messageState(String message) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        EmptyState(
          icon: Icons.error_outline,
          title: message,
          action: OutlinedButton(
            onPressed: _refresh,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _BinDetailsData {
  const _BinDetailsData({
    required this.bin,
    required this.monitoring,
  });

  final RecyTechBin bin;
  final BinMonitoringData monitoring;
}
