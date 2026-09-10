import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/repositories/partner_validation_repository.dart';
import '../../../widgets/empty_state.dart';
import 'partner_dropoff_widgets.dart';
import 'pending_dropoff_validation_detail_screen.dart';

class PendingDropOffValidationsScreen extends StatefulWidget {
  const PendingDropOffValidationsScreen({
    super.key,
    this.repository,
  });

  final PartnerValidationRepository? repository;

  @override
  State<PendingDropOffValidationsScreen> createState() =>
      _PendingDropOffValidationsScreenState();
}

class _PendingDropOffValidationsScreenState
    extends State<PendingDropOffValidationsScreen> {
  late final PartnerValidationRepository _repository;
  late Future<List<DropOffRecord>> _pendingFuture;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiPartnerValidationRepository();
    _pendingFuture = _repository.fetchPendingDropOffs();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchPendingDropOffs();
    setState(() {
      _pendingFuture = future;
    });
    await future;
  }

  Future<void> _open(DropOffRecord record) async {
    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PendingDropOffValidationDetailScreen(
          record: record,
          repository: _repository,
        ),
      ),
    );
    if (!mounted || action == null) return;
    _didChange = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'approve'
              ? 'Drop-off approved successfully.'
              : 'Drop-off rejected successfully.',
        ),
      ),
    );
    await _refresh();
  }

  void _close() => Navigator.pop(context, _didChange);

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _close,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Pending Validations'),
          actions: [
            IconButton(
              tooltip: 'Refresh pending validations',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<DropOffRecord>>(
          future: _pendingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState(
                message: 'Loading pending validations…',
              );
            }
            if (snapshot.hasError) {
              return AppErrorState(
                title: 'We could not load pending validations.',
                onRetry: _refresh,
              );
            }

            final records = (snapshot.data ?? const <DropOffRecord>[])
                .where((item) => item.status == DropOffStatuses.pending)
                .toList(growable: false);
            if (records.isEmpty) return _emptyState();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                key: const Key('pending-validations-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                itemCount: records.length,
                separatorBuilder: (_, __) => SizedBox(height: 14.h),
                itemBuilder: (context, index) =>
                    _PendingDropOffCard(record: records[index], onTap: _open),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 90.h),
          Icon(
            Icons.fact_check_outlined,
            size: 58.sp,
            color: RecyTechTheme.primary,
          ),
          SizedBox(height: 18.h),
          Text(
            'No pending validations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: RecyTechTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'New household drop-offs assigned to your bins will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.45,
              color: RecyTechTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDropOffCard extends StatelessWidget {
  const _PendingDropOffCard({required this.record, required this.onTap});

  final DropOffRecord record;
  final ValueChanged<DropOffRecord> onTap;

  @override
  Widget build(BuildContext context) {
    final notes = record.notes?.trim() ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('pending-dropoff-${record.id}'),
        onTap: () => onTap(record),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PartnerDropOffImage(
                source: record.imageUrls.firstOrNull,
                width: 86.w,
                height: 96.h,
                borderRadius: 12,
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            dropOffCategory(record),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                              color: RecyTechTheme.textDark,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _pendingBadge(),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _meta(Icons.inventory_2_outlined, dropOffQuantity(record)),
                    SizedBox(height: 6.h),
                    _meta(Icons.delete_outline, record.binName),
                    SizedBox(height: 6.h),
                    _meta(Icons.schedule, dropOffDate(record.createdAt)),
                    if (notes.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          height: 1.3,
                          color: RecyTechTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4.w, top: 38.h),
                child: Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingBadge() => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: RecyTechTheme.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Pending',
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w900,
            color: RecyTechTheme.warning,
          ),
        ),
      );

  Widget _meta(IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 13.sp, color: RecyTechTheme.textMuted),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 10.5.sp, color: RecyTechTheme.textMuted),
            ),
          ),
        ],
      );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
