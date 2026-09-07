import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';
import '../requests/collection_request_form_screen.dart';
import '../requests/collection_request_tracking_screen.dart';

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
  final LguBinRepository _repository = ApiPartnerBinRepository();
  final MapLauncher _mapLauncher = const MapLauncher();
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
    if (bin.hasActiveCollectionRequest) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CollectionRequestTrackingScreen(),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionRequestFormScreen(bin: bin),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openMaps(RecyTechBin bin) async {
    final opened = await _mapLauncher.open(
      MapLaunchTarget(
        label: bin.displayName,
        address: bin.location,
        latitude: bin.latitude,
        longitude: bin.longitude,
      ),
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No bin coordinates or map app available.')),
      );
    }
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
            return const AppLoadingState(message: 'Loading smart bin details…');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load smart bin data. Please try again.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return AppErrorState(
              title: 'Unable to load smart bin data. Please try again.',
              onRetry: _refresh,
            );
          }

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
                  onPressed: () => _requestCollection(data.bin),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(
                    data.bin.hasActiveCollectionRequest
                        ? 'View Active Request'
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
    final warning = RecyTechTheme.warning;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warning.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, color: warning),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This bin is full. Review the reading and submit a collection request when ready.',
              style: TextStyle(
                color: warning,
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
    final freshnessLabel =
        SensorReadingFreshness.status(monitoring.lastUpdatedAt);
    final hasSensorReading = monitoring.lastUpdatedAt != null ||
        monitoring.distanceCm != null ||
        monitoring.fillPercentage != null;

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
          SizedBox(height: 4.h),
          _infoRow('Bin ID', bin.binId),
          _infoRow(
            'Partner',
            bin.partnerOrganizationName ?? bin.assignedLguId ?? '-',
          ),
          _infoRow('Location', bin.location),
          _infoRow('Coordinates', _coordinatesLabel(bin)),
          if (hasSensorReading) ...[
            _infoRow('Distance', _distanceLabel(monitoring.distanceCm)),
            _infoRow(
              'Latest Stored Reading',
              formatDateTime(monitoring.lastUpdatedAt),
            ),
            _infoRow('Reading status', freshnessLabel),
          ],
          _infoRow('Last collection', formatDateTime(bin.lastCollectionAt)),
          if (bin.acceptedCategoryLabels.isNotEmpty)
            _infoRow('Accepts', bin.acceptedCategoryLabels.join(', ')),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openMaps(bin),
              icon: const Icon(Icons.map_outlined),
              label: const Text('View location on map'),
            ),
          ),
          SizedBox(height: 12.h),
          if (!hasSensorReading)
            const EmptyState(
              icon: Icons.sensors_off_outlined,
              title: 'Sensor data is not available yet.',
              message: 'No recent sensor reading is available.',
            )
          else ...[
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
                StatusBadge(label: 'Reading: $freshnessLabel'),
                if ((monitoring.controllerStatus ?? '').trim().isNotEmpty)
                  StatusBadge(
                    label: 'Controller: ${monitoring.controllerStatus}',
                  ),
              ],
            ),
            if (freshnessLabel == 'Stale') ...[
              SizedBox(height: 12.h),
              _staleReadingWarning(),
            ],
          ],
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

  String _coordinatesLabel(RecyTechBin bin) {
    if (bin.latitude == null || bin.longitude == null) return 'Not supplied';
    return '${bin.latitude!.toStringAsFixed(5)}, ${bin.longitude!.toStringAsFixed(5)}';
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

  Widget _staleReadingWarning() {
    final warning = RecyTechTheme.warning;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warning.withValues(alpha: 0.32)),
      ),
      child: Text(
        'This stored reading is older than the expected sync window. Refresh or verify the backend value before acting on it.',
        style: TextStyle(
          color: warning,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
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
