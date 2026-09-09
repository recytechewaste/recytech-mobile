import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/models/reward_transaction_model.dart';
import '../../../data/repositories/drop_off_repository.dart';
import '../../../data/repositories/unified_profile_repository.dart';
import '../../../widgets/empty_state.dart';

class DropOffDetailScreen extends StatefulWidget {
  const DropOffDetailScreen({
    super.key,
    required this.initialRecord,
    required this.repository,
    this.profileRepository,
  });

  final DropOffRecord initialRecord;
  final DropOffRepository repository;
  final UnifiedProfileRepository? profileRepository;

  @override
  State<DropOffDetailScreen> createState() => _DropOffDetailScreenState();
}

class _DropOffDetailScreenState extends State<DropOffDetailScreen> {
  late final UnifiedProfileRepository _profileRepository;
  late Future<_DropOffDetailsData> _detailFuture;

  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? UnifiedProfileRepository();
    _detailFuture = _load();
  }

  Future<_DropOffDetailsData> _load() async {
    final record =
        await widget.repository.getDropOffDetail(widget.initialRecord.id);
    if (record.status != DropOffStatuses.approved) {
      return _DropOffDetailsData(record: record);
    }

    int? pointsBalance;
    List<RewardTransaction> transactions = const [];
    try {
      pointsBalance = (await _profileRepository.fetchProfile()).pointsBalance;
    } catch (_) {
      // Keep approved details usable when profile refresh is unavailable.
    }
    try {
      transactions = await widget.repository.getMyRewards();
    } catch (_) {
      // Keep the drop-off transaction reference visible when supplied.
    }

    RewardTransaction? transaction;
    for (final candidate in transactions) {
      final matchesTransaction = (record.transactionId ?? '').isNotEmpty &&
          candidate.id == record.transactionId;
      if (matchesTransaction || candidate.dropOffId == record.id) {
        transaction = candidate;
        break;
      }
    }
    return _DropOffDetailsData(
      record: record,
      pointsBalance: pointsBalance,
      transaction: transaction,
    );
  }

  Future<void> _retry() async {
    final future = _load();
    setState(() {
      _detailFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Drop-Off Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh reward receipt',
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_DropOffDetailsData>(
        future: _detailFuture,
        initialData: _DropOffDetailsData(record: widget.initialRecord),
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return AppErrorState(
              title: 'Unable to load drop-off details. Please try again.',
              onRetry: _retry,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const AppLoadingState(message: 'Loading drop-off details…');
          }
          final record = data.record;

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              if (snapshot.connectionState == ConnectionState.waiting)
                SizedBox(height: 12.h),
              _panel(data),
              if (record.imageUrls.isNotEmpty) ...[
                SizedBox(height: 14.h),
                Text(
                  'Submitted photos',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                ...record.imageUrls.map(_photo),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _panel(_DropOffDetailsData data) {
    final record = data.record;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        children: [
          if (record.status == DropOffStatuses.approved)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_outlined),
              title: Text(
                'Drop-off Approved',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          _row('Reference', record.id),
          _row('Bin', record.binName),
          _row('Location', record.locationLabel),
          _row('Items', _itemsLabel(record)),
          _row('Submitted', _formatDateTime(record.createdAt)),
          _row('Status', record.statusLabel),
          if (record.status == DropOffStatuses.approved)
            _row('Points Earned', '+${record.pointsAwarded}'),
          if (record.status == DropOffStatuses.approved &&
              data.pointsBalance != null)
            _row('Current Points Balance', data.pointsBalance.toString()),
          if (record.status == DropOffStatuses.rejected &&
              record.pointsAwarded == 0)
            const _DetailRow(label: 'Points awarded', value: '0'),
          if ((record.rejectionNotes ?? '').isNotEmpty)
            _row('Rejection notes', record.rejectionNotes!),
          if ((record.transactionId ?? '').isNotEmpty)
            _row('Transaction', record.transactionId!),
          if ((record.transactionId ?? '').isEmpty && data.transaction != null)
            _row('Transaction', data.transaction!.id),
        ],
      ),
    );
  }

  Widget _photo(String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Image.network(
          url,
          height: 190.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100.h,
            color: RecyTechTheme.card,
            alignment: Alignment.center,
            child: const Text('Photo unavailable'),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return _DetailRow(label: label, value: value);
  }

  String _itemsLabel(DropOffRecord record) {
    if (record.items.isEmpty) return '-';
    return record.items
        .map((item) =>
            '${item.categoryLabel ?? item.category} × ${item.quantity}')
        .join(', ');
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

class _DropOffDetailsData {
  const _DropOffDetailsData({
    required this.record,
    this.pointsBalance,
    this.transaction,
  });

  final DropOffRecord record;
  final int? pointsBalance;
  final RewardTransaction? transaction;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
