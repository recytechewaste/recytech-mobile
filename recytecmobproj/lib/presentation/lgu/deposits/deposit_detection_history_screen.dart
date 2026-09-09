// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../bin_monitoring/widgets/bin_monitoring_components.dart';
import 'deposit_detection_details_screen.dart';

class DepositDetectionHistoryScreen extends StatefulWidget {
  const DepositDetectionHistoryScreen({
    super.key,
    required this.binId,
  });

  final String binId;

  @override
  State<DepositDetectionHistoryScreen> createState() =>
      _DepositDetectionHistoryScreenState();
}

class _DepositDetectionHistoryScreenState
    extends State<DepositDetectionHistoryScreen> {
  final BinMonitoringService _service = MockBinMonitoringService();
  late Future<List<DepositEvent>> _eventsFuture;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _service.fetchDepositEvents(widget.binId);
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _service.fetchDepositEvents(widget.binId);
    setState(() => _eventsFuture = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  Future<void> _openEvent(DepositEvent event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositDetectionDetailsScreen(eventId: event.id),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          IconButton(
            tooltip: 'Refresh detection history',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<DepositEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? <DepositEvent>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              children: [
                Text(
                  '${events.length} recorded deposit event${events.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: RecyTechTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                DetectionHistoryTimeline(
                  events: events,
                  onOpenEvent: _openEvent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
