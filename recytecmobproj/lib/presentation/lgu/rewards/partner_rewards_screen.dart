import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/points_rewards_models.dart';
import '../../../data/repositories/points_rewards_repository.dart';
import '../../../widgets/empty_state.dart';

class PartnerRewardsScreen extends StatefulWidget {
  const PartnerRewardsScreen({
    super.key,
    this.repository,
  });

  final PointsRewardsRepository? repository;

  @override
  State<PartnerRewardsScreen> createState() => _PartnerRewardsScreenState();
}

class _PartnerRewardsScreenState extends State<PartnerRewardsScreen> {
  late final PointsRewardsRepository _repository;
  late Future<_PartnerRewardsData> _future;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PointsRewardsRepository();
    _future = _load();
  }

  Future<_PartnerRewardsData> _load() async {
    final rewards = await _repository.fetchPartnerRewards();
    final redemptions = await _repository.fetchPartnerRedemptions();
    return _PartnerRewardsData(rewards: rewards, redemptions: redemptions);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _toggleReward(PartnerRewardOffer reward) async {
    await _repository.savePartnerReward(
      id: reward.id,
      title: reward.title,
      description: reward.description ?? '',
      pointsCost: reward.pointsCost,
      active: !reward.active,
      applicableBinIds: reward.applicableBinIds,
    );
    await _refresh();
  }

  Future<void> _updateRedemption(
    RewardRedemptionRecord redemption,
    bool fulfill,
  ) async {
    try {
      if (fulfill) {
        await _repository.fulfillRedemption(redemption.id);
      } else {
        await _repository.cancelRedemption(redemption.id);
      }
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(
              error,
              fallback: 'Unable to update this redemption. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openRewardSheet([PartnerRewardOffer? reward]) async {
    final titleController = TextEditingController(text: reward?.title ?? '');
    final descriptionController =
        TextEditingController(text: reward?.description ?? '');
    final pointsController =
        TextEditingController(text: reward?.pointsCost.toString() ?? '');
    var active = reward?.active ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18.w,
                  8.h,
                  18.w,
                  MediaQuery.of(context).viewInsets.bottom + 18.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward == null ? 'New Reward' : 'Edit Reward',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: RecyTechTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Points Cost'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: active,
                      onChanged: (value) => setSheetState(() => active = value),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final points = int.tryParse(pointsController.text);
                          if (points == null || points <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid points cost.'),
                              ),
                            );
                            return;
                          }
                          await _repository.savePartnerReward(
                            id: reward?.id,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            pointsCost: points,
                            active: active,
                            applicableBinIds:
                                reward?.applicableBinIds ?? const [],
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          await _refresh();
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Reward'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: [
          IconButton(
            tooltip: 'Refresh rewards',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRewardSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Reward'),
      ),
      body: FutureBuilder<_PartnerRewardsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading partner rewards…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load rewards. Please try again.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data ?? _PartnerRewardsData.empty();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _sectionTitle('Reward Offers'),
                SizedBox(height: 10.h),
                if (data.rewards.isEmpty)
                  const EmptyState(
                    icon: Icons.redeem_outlined,
                    title: 'No rewards have been created yet.',
                    message:
                        'Use Add Reward to create your first reward offer.',
                  )
                else
                  ...data.rewards.map(_rewardCard),
                SizedBox(height: 18.h),
                _sectionTitle('Redemption Requests'),
                SizedBox(height: 10.h),
                if (data.redemptions.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No redemption requests yet.',
                    message:
                        'Registered user redemption requests will appear here.',
                  )
                else
                  ...data.redemptions.map(_redemptionCard),
                SizedBox(height: 76.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rewardCard(PartnerRewardOffer reward) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              Switch(
                value: reward.active,
                onChanged: (_) => _toggleReward(reward),
              ),
            ],
          ),
          Text(
            '${reward.pointsCost} pts',
            style: TextStyle(
              fontSize: 12.sp,
              color: RecyTechTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((reward.description ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              reward.description!,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ],
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openRewardSheet(reward),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _redemptionCard(RewardRedemptionRecord redemption) {
    final requested = redemption.status == 'requested';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  redemption.rewardTitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              Chip(
                label: Text(redemption.status),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${redemption.pointsCost} pts - ${_formatDate(redemption.redeemedAt)}',
            style: TextStyle(fontSize: 10.5.sp, color: RecyTechTheme.textMuted),
          ),
          if (requested) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateRedemption(redemption, false),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _updateRedemption(redemption, true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Fulfill'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w900,
        color: RecyTechTheme.textDark,
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

class _PartnerRewardsData {
  const _PartnerRewardsData({
    required this.rewards,
    required this.redemptions,
  });

  factory _PartnerRewardsData.empty() {
    return const _PartnerRewardsData(rewards: [], redemptions: []);
  }

  final List<PartnerRewardOffer> rewards;
  final List<RewardRedemptionRecord> redemptions;
}
