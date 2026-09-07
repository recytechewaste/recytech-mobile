import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/points_rewards_models.dart';
import '../../../data/repositories/points_rewards_repository.dart';
import '../../../widgets/empty_state.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({
    super.key,
    this.repository,
  });

  final PointsRewardsRepository? repository;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final PointsRewardsRepository _repository;
  late Future<_RewardsData> _future;
  String? _redeemingId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PointsRewardsRepository();
    _future = _load();
  }

  Future<_RewardsData> _load() async {
    final summary = await _repository.fetchPointsSummary();
    final rewards = await _repository.fetchHouseholdRewards();
    final redemptions = await _repository.fetchHouseholdRedemptions();
    return _RewardsData(
      summary: summary,
      rewards: rewards,
      redemptions: redemptions,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _redeem(PartnerRewardOffer reward) async {
    setState(() => _redeemingId = reward.id);
    try {
      await _repository.redeemReward(reward.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${reward.title} redemption requested.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to redeem this reward. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _redeemingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Points & Rewards'),
          actions: [
            IconButton(
              tooltip: 'Refresh rewards',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<_RewardsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState(
                  message: 'Loading points and rewards…');
            }
            if (snapshot.hasError) {
              return AppErrorState(
                title: 'Unable to load rewards. Please try again.',
                onRetry: _refresh,
              );
            }

            final data = snapshot.data ?? _RewardsData.empty();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                children: [
                  _balanceCard(data.summary),
                  SizedBox(height: 18.h),
                  _sectionTitle('Available Rewards'),
                  SizedBox(height: 10.h),
                  if (data.rewards.isEmpty)
                    _emptyCard(
                      'No rewards are available yet.',
                      supportingText:
                          'Available rewards from partner organizations will appear here.',
                    )
                  else
                    ...data.rewards.map(
                      (reward) => _rewardCard(reward, data.summary.balance),
                    ),
                  SizedBox(height: 18.h),
                  _sectionTitle('Redemption Requests'),
                  SizedBox(height: 10.h),
                  if (data.redemptions.isEmpty)
                    _emptyCard('Redeemed rewards will appear here.')
                  else
                    ...data.redemptions.map(_redemptionCard),
                  SizedBox(height: 18.h),
                  _sectionTitle('Recent Point Activity'),
                  SizedBox(height: 10.h),
                  if (data.summary.transactions.isEmpty)
                    _emptyCard('You have no reward activity yet.')
                  else
                    ...data.summary.transactions.take(6).map(_ledgerRow),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _balanceCard(PointsSummary summary) {
    final earned = summary.transactions
        .where((entry) => entry.signedAmount > 0)
        .fold<int>(0, (sum, entry) => sum + entry.signedAmount);
    final spent = summary.transactions
        .where((entry) => entry.signedAmount < 0)
        .fold<int>(0, (sum, entry) => sum + entry.signedAmount.abs());

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: RecyTechTheme.pill,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: RecyTechTheme.primary,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${summary.balance} pts',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Earned $earned pts - Redeemed $spent pts',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard(PartnerRewardOffer reward, int balance) {
    final canRedeem = reward.canRedeem ?? balance >= reward.pointsCost;
    final isBusy = _redeemingId == reward.id;
    final deficit = reward.pointsCost - balance;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reward.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              Text(
                '${reward.pointsCost} pts',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: RecyTechTheme.primary,
                ),
              ),
            ],
          ),
          if ((reward.partnerOrganizationName ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              reward.partnerOrganizationName!,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ],
          if ((reward.description ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              reward.description!,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canRedeem && !isBusy ? () => _redeem(reward) : null,
              icon: isBusy
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.redeem_outlined),
              label: Text(canRedeem ? 'Redeem' : 'Need $deficit more pts'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _redemptionCard(RewardRedemptionRecord redemption) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
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
                  redemption.rewardTitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${redemption.pointsCost} pts - ${_formatDate(redemption.redeemedAt)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(redemption.status),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow(PointsLedgerEntry entry) {
    final positive = entry.signedAmount >= 0;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: positive ? RecyTechTheme.primary : RecyTechTheme.danger,
            size: 18.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              entry.description.trim().isEmpty ? entry.type : entry.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: RecyTechTheme.textDark,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${positive ? '+' : ''}${entry.signedAmount}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: positive ? RecyTechTheme.primary : RecyTechTheme.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w900,
        color: RecyTechTheme.textDark,
      ),
    );
  }

  Widget _emptyCard(String message, {String? supportingText}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: RecyTechTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((supportingText ?? '').isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              supportingText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ],
        ],
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

class _RewardsData {
  const _RewardsData({
    required this.summary,
    required this.rewards,
    required this.redemptions,
  });

  factory _RewardsData.empty() {
    return const _RewardsData(
      summary: PointsSummary(balance: 0),
      rewards: [],
      redemptions: [],
    );
  }

  final PointsSummary summary;
  final List<PartnerRewardOffer> rewards;
  final List<RewardRedemptionRecord> redemptions;
}
