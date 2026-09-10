import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/repositories/drop_off_repository.dart';
import '../../../widgets/empty_state.dart';
import 'drop_off_detail_screen.dart';

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
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiDropOffRepository();
    _historyFuture = _repository.getMyDropOffHistory();
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _repository.getMyDropOffHistory();
    setState(() => _historyFuture = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Drop-Off History'),
          actions: [
            IconButton(
              tooltip: 'Refresh history',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<DropOffRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState(
                  message: 'Loading drop-off history…');
            }

            if (snapshot.hasError) {
              return AppErrorState(
                title:
                    'Unable to load your drop-off history. Please try again.',
                onRetry: _refresh,
              );
            }

            final records = snapshot.data ?? <DropOffRecord>[];
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
                children: [
                  Text(
                    'Designated-Bin Drop-Offs',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Manual and QR submissions recorded at designated RecyTech bins.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (records.isEmpty)
                    const EmptyState(
                      icon: Icons.history,
                      title: 'No drop-offs recorded yet.',
                      message:
                          'Your completed designated-bin drop-offs will appear here.',
                    )
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
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DropOffDetailScreen(
              initialRecord: record,
              repository: _repository,
            ),
          ),
        );
        if (mounted) await _refresh();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: RecyTechTheme.border),
        ),
        child: Column(
          children: [
            _row(Icons.delete_outline, 'Bin', record.binName),
            _divider(),
            _row(Icons.place_outlined, 'Location', record.locationLabel),
            _divider(),
            if ((record.partnerOrganizationName ?? '').trim().isNotEmpty) ...[
              _row(
                Icons.apartment_outlined,
                'Partner',
                record.partnerOrganizationName!,
              ),
              _divider(),
            ],
            if (record.items.isNotEmpty) ...[
              _row(Icons.category_outlined, 'Items', _itemsLabel(record)),
              _divider(),
            ],
            if ((record.submissionMethod ?? '').trim().isNotEmpty) ...[
              _row(
                Icons.input_outlined,
                'Method',
                record.submissionMethod!.toUpperCase(),
              ),
              _divider(),
            ],
            _row(Icons.event_available_outlined, 'Recorded',
                _formatDateTime(record.createdAt)),
            _divider(),
            _row(Icons.info_outline, 'Status', record.statusLabel),
            _divider(),
            if (record.status == DropOffStatuses.approved ||
                record.status == DropOffStatuses.rejected)
              _row(
                Icons.emoji_events_outlined,
                'Points',
                record.pointsAwarded > 0
                    ? record.rewardLabel
                    : record.pointsAwarded.toString(),
              ),
            if (record.transactionId != null) ...[
              _divider(),
              _row(
                Icons.receipt_long_outlined,
                'Transaction',
                record.transactionId!,
              ),
            ],
          ],
        ),
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

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String _itemsLabel(DropOffRecord record) {
    return record.items
        .map((item) =>
            '${item.categoryLabel ?? _displayCategory(item.category)} x ${item.quantity}')
        .join(', ');
  }

  String _displayCategory(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (normalized == 'pcb') return 'PCB';
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
