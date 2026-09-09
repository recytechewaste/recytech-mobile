import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';
import '../requests/collection_request_form_screen.dart';
import '../requests/collection_request_tracking_screen.dart';
import '../sensor_incidents/sensor_incident_form_screen.dart';
import '../sensor_incidents/sensor_incident_history_screen.dart';

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
  Future<void>? _refreshing;

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
    final active = _refreshing;
    if (active != null) return active;

    final future = _loadDetails();
    setState(() => _detailsFuture = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
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

  Future<void> _reportSensorIssue(RecyTechBin bin) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SensorIncidentFormScreen(bin: bin),
      ),
    );
    if (created == true && mounted) await _refresh();
  }

  Future<void> _openIncidentHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SensorIncidentHistoryScreen(),
      ),
    );
  }

  Future<void> _updateBin(RecyTechBin bin) async {
    final input = await showDialog<_BinUpdateInput>(
      context: context,
      builder: (_) => _BinStatusDialog(bin: bin),
    );
    if (input == null) return;
    try {
      await _repository.updateBinStatus(
        binId: bin.apiId,
        status: input.status,
        fillLevelKg: input.fillLevelKg,
        notes: input.notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bin status updated.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      final forbidden =
          error is DioException && error.response?.statusCode == 403;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(forbidden
              ? 'You are not allowed to update this bin.'
              : userFacingError(error,
                  fallback: 'Bin status could not be updated.')),
        ),
      );
    }
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              children: [
                if (FullnessStatuses.normalize(data.bin.fullnessStatus) ==
                    FullnessStatuses.full)
                  _recommendationBanner(),
                _conditionPanel(data.bin, data.monitoring),
                SizedBox(height: 18.h),
                OutlinedButton.icon(
                  onPressed: () => _updateBin(data.bin),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update Bin Status'),
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  key: const Key('report-sensor-issue'),
                  onPressed: () => _reportSensorIssue(data.bin),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Report Sensor Issue'),
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed: _openIncidentHistory,
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Incident History'),
                ),
                SizedBox(height: 10.h),
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
          _infoRow('Status', bin.apiStatus ?? 'Not supplied'),
          _infoRow(
            'Fill level (kg)',
            bin.fillLevelKg == null ? 'Not supplied' : '${bin.fillLevelKg} kg',
          ),
          if ((bin.notes ?? '').trim().isNotEmpty)
            _infoRow('Notes', bin.notes!),
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

class _BinUpdateInput {
  const _BinUpdateInput({
    required this.status,
    this.fillLevelKg,
    this.notes,
  });

  final String status;
  final double? fillLevelKg;
  final String? notes;
}

class _BinStatusDialog extends StatefulWidget {
  const _BinStatusDialog({required this.bin});

  final RecyTechBin bin;

  @override
  State<_BinStatusDialog> createState() => _BinStatusDialogState();
}

class _BinStatusDialogState extends State<_BinStatusDialog> {
  String? _status;
  late final TextEditingController _fill;
  late final TextEditingController _notes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = PartnerBinStatuses.isValid(widget.bin.apiStatus)
        ? widget.bin.apiStatus
        : null;
    _fill = TextEditingController(
      text: widget.bin.fillLevelKg?.toString() ?? '',
    );
    _notes = TextEditingController(text: widget.bin.notes ?? '');
  }

  @override
  void dispose() {
    _fill.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_status == null) {
      setState(() => _error = 'Select a bin status.');
      return;
    }
    final text = _fill.text.trim();
    final fill = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty &&
        (fill == null || !fill.isFinite || fill.isNegative)) {
      setState(() => _error = 'Fill level must be a non-negative number.');
      return;
    }
    Navigator.pop(
      context,
      _BinUpdateInput(
        status: _status!,
        fillLevelKg: fill,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Bin Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: PartnerBinStatuses.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            TextField(
              controller: _fill,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fill level (kg)'),
            ),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Update')),
      ],
    );
  }
}
