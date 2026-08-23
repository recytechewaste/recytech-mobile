import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/repositories/drop_off_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.repository,
  });

  final DropOffRepository? repository;

  @override
  State<HistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<HistoryScreen> {
  late final DropOffRepository _repository;
  late Future<List<DropOffRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockDropOffRepository();
    _historyFuture = _repository.getMyDropOffHistory();
  }

  Future<void> _refresh() async {
    final future = _repository.getMyDropOffHistory();
    setState(() => _historyFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Drop-Off History'),
        ),
        body: FutureBuilder<List<DropOffRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _messageState(
                'Unable to load your drop-off history. Please try again.',
              );
            }

            final records = snapshot.data ?? <DropOffRecord>[];
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                children: [
                  Text(
                    'Designated-Bin Drop-Offs',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Check-ins recorded after scanning a RecyTech bin QR code.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (records.isEmpty)
                    _emptyCard()
                  else
                    ...records.map(_dropOffCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dropOffCard(DropOffRecord record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        children: [
          _row(Icons.delete_outline, 'Bin', record.binName),
          _divider(),
          _row(Icons.place_outlined, 'Location', record.locationLabel),
          _divider(),
          _row(Icons.event_available_outlined, 'Recorded',
              _formatDateTime(record.createdAt)),
          _divider(),
          _row(Icons.info_outline, 'Status', record.status),
          _divider(),
          _row(Icons.emoji_events_outlined, 'Reward', record.rewardLabel),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: RecyTechTheme.primary),
        SizedBox(width: 10.w),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          flex: 5,
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: RecyTechTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: const Divider(height: 1),
      );

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(
        'No drop-offs recorded yet.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
      ),
    );
  }

  Widget _messageState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
