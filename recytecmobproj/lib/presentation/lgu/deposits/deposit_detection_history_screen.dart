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

  @override
  void initState() {
    super.initState();
    _eventsFuture = _service.fetchDepositEvents(widget.binId);
  }

  Future<void> _refresh() async {
    final future = _service.fetchDepositEvents(widget.binId);
    setState(() => _eventsFuture = future);
    await future;
  }

  void _openEvent(DepositEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositDetectionDetailsScreen(eventId: event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Detection History'),
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
