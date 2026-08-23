import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/models/reward_transaction_model.dart';
import '../../../data/repositories/drop_off_repository.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({
    super.key,
    this.repository,
  });

  final DropOffRepository? repository;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final DropOffRepository _repository;
  late Future<_RewardHistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockDropOffRepository();
    _historyFuture = _loadRewardHistory();
  }

  Future<_RewardHistoryData> _loadRewardHistory() async {
    final dropOffs = await _repository.getMyDropOffHistory();
    final rewards = await _repository.getMyRewards();
    return _RewardHistoryData(dropOffs: dropOffs, rewards: rewards);
  }

  Future<void> _refresh() async {
    final future = _loadRewardHistory();
    setState(() => _historyFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Rewards'),
        ),
        body: FutureBuilder<_RewardHistoryData>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _messageState(
                'Unable to load rewards. Please try again.',
              );
            }

            final data = snapshot.data ?? const _RewardHistoryData();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                children: [
                  Text(
                    'Drop-Off Rewards',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Reward values are displayed only when returned by the drop-off reward service.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _summaryCard(data),
                  SizedBox(height: 22.h),
                  Text(
                    'Reward History',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (data.rewards.isEmpty)
                    _emptyCard()
                  else
                    ...data.rewards.map(_rewardRow),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(_RewardHistoryData data) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: RecyTechTheme.pill,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: RecyTechTheme.primary,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eligible Drop-Offs',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${data.eligibleDropOffs}',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${data.dropOffs.length} drop-off${data.dropOffs.length == 1 ? '' : 's'} recorded.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: RecyTechTheme.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardRow(RewardTransaction reward) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.binName ?? 'RecyTech Bin',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  reward.locationDescription ?? _formatDate(reward.createdAt),
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${reward.status} - ${_formatDate(reward.createdAt)}',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: RecyTechTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            reward.rewardLabel,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: RecyTechTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

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
        'No reward records yet.',
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

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _RewardHistoryData {
  const _RewardHistoryData({
    this.dropOffs = const <DropOffRecord>[],
    this.rewards = const <RewardTransaction>[],
  });

  final List<DropOffRecord> dropOffs;
  final List<RewardTransaction> rewards;

  int get eligibleDropOffs =>
      dropOffs.where((record) => record.rewardEligible).length;
}
