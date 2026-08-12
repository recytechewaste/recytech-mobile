import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';
import 'bin_details_screen.dart';

class AssignedBinsScreen extends StatefulWidget {
  const AssignedBinsScreen({super.key});

  @override
  State<AssignedBinsScreen> createState() => _AssignedBinsScreenState();
}

class _AssignedBinsScreenState extends State<AssignedBinsScreen> {
  final LguBinRepository _repository = MockBinMonitoringService();
  late Future<List<RecyTechBin>> _binsFuture;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _binsFuture = _repository.fetchAssignedBins();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchAssignedBins();
    setState(() => _binsFuture = future);
    await future;
  }

  void _openBin(RecyTechBin bin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BinDetailsScreen(binId: bin.binId),
      ),
    );
  }

  List<RecyTechBin> _filteredBins(List<RecyTechBin> bins) {
    if (_filter == 'all') return bins;
    return bins
        .where((bin) => FullnessStatuses.normalize(bin.fullnessStatus) == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Assigned Bins'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh bins',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<RecyTechBin>>(
        future: _binsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingState();
          }

          if (snapshot.hasError) {
            return _errorState();
          }

          final bins = snapshot.data ?? <RecyTechBin>[];
          final filtered = _filteredBins(bins);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _filterBar(),
                SizedBox(height: 12.h),
                if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.delete_outline,
                    title: 'No bins found',
                    message: _filter == 'all'
                        ? 'No assigned bins are available yet.'
                        : 'No bins match the selected status.',
                  )
                else
                  for (final bin in filtered) _binCard(bin),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    final filters = <String, String>{
      'all': 'All',
      FullnessStatuses.full: 'Full',
      FullnessStatuses.nearlyFull: 'Nearly Full',
      FullnessStatuses.requiresInspection: 'Inspect',
      FullnessStatuses.sensorOffline: 'Offline',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = _filter == entry.key;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => setState(() => _filter = entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _binCard(RecyTechBin bin) {
    final fullnessLabel = FullnessStatuses.label(bin.fullnessStatus);
    final sensorLabel = SensorStatuses.label(bin.sensorStatus);

    return InkWell(
      onTap: () => _openBin(bin),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RecyTechTheme.border),
          boxShadow: [
            BoxShadow(
              color: RecyTechTheme.primary.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 7),
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
                    bin.displayName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              bin.binId,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
            SizedBox(height: 8.h),
            Text(
              bin.location,
              style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textDark),
            ),
            SizedBox(height: 12.h),
            FillLevelIndicator(
              fillLevel: bin.fillPercentage,
              status: fullnessLabel,
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                StatusBadge(label: fullnessLabel),
                StatusBadge(label: 'Sensor: $sensorLabel'),
                if (bin.hasActiveCollectionRequest)
                  StatusBadge(
                    label:
                        'Request: ${CollectionRequestStatuses.label(bin.activeCollectionRequest!.status)}',
                    color: RecyTechTheme.accent,
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'Updated: ${formatDateTime(bin.lastUpdatedAt)}',
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 132.h,
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RecyTechTheme.border),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _errorState() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load assigned bins',
          message: 'Check the connection and try again.',
          action: OutlinedButton(
            onPressed: _refresh,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
