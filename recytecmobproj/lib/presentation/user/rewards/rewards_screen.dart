import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/points_rewards_models.dart';
import '../../../data/repositories/points_rewards_repository.dart';
import '../../../data/repositories/unified_profile_repository.dart';
import '../../../widgets/empty_state.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({
    super.key,
    this.repository,
    this.profileRepository,
  }) : showHouseholdBalance = true;

  const RewardsScreen.informational({super.key, this.repository})
      : profileRepository = null,
        showHouseholdBalance = false;

  final PointsRewardsRepository? repository;
  final UnifiedProfileRepository? profileRepository;
  final bool showHouseholdBalance;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final PointsRewardsRepository _repository;
  UnifiedProfileRepository? _profileRepository;
  late Future<List<RewardPointRule>> _catalogFuture;
  Future<int>? _balanceFuture;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PointsRewardsRepository();
    _catalogFuture = _repository.fetchCatalog();
    if (widget.showHouseholdBalance) {
      _profileRepository =
          widget.profileRepository ?? UnifiedProfileRepository();
      _balanceFuture = _fetchHouseholdBalance();
    }
  }

  Future<int> _fetchHouseholdBalance() async {
    final profile = await _profileRepository!.fetchProfile();
    if (profile.role != AppRoles.household) {
      throw const UnifiedProfileException(
        'Reward balance is only available to Household accounts.',
      );
    }
    if (profile.pointsBalance == null) {
      throw const UnifiedProfileException(
        'Your points balance is temporarily unavailable.',
      );
    }
    return profile.pointsBalance!;
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;
    final catalog = _repository.fetchCatalog();
    final balance =
        widget.showHouseholdBalance ? _fetchHouseholdBalance() : null;
    setState(() {
      _catalogFuture = catalog;
      _balanceFuture = balance;
    });
    final refresh = Future.wait<void>([
      _settle(catalog),
      if (balance != null) _settle(balance),
    ]).whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  Future<void> _settle<T>(Future<T> future) async {
    try {
      await future;
    } catch (_) {
      // Each independent section presents its own partial error state.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showHouseholdBalance) ...[
                    _balanceSection(),
                    SizedBox(height: 22.h),
                  ],
                  _catalogHeader(),
                  SizedBox(height: 12.h),
                  _catalogSection(),
                  SizedBox(height: 8.h),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _balanceSection() => FutureBuilder<int>(
        future: _balanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _balanceLoadingCard();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _balanceErrorCard();
          }
          return _balanceCard(snapshot.data!);
        },
      );

  Widget _balanceCard(int balance) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('reward-balance-card'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(RecyTechTheme.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: scheme.onPrimary,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Rewards Balance',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Semantics(
              label: '$balance available reward points',
              child: Text.rich(
                key: const Key('reward-balance-value'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$balance',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 34.sp,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' pts',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'Available Points',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Keep recycling—points are added after an eligible drop-off is validated.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceLoadingCard() => Card(
        key: const Key('reward-balance-loading'),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 14.w),
              const Expanded(child: Text('Loading your rewards balance…')),
            ],
          ),
        ),
      );

  Widget _balanceErrorCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('reward-balance-error'),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rewards balance unavailable',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Your balance could not be loaded. The points guide may still be available below.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.showHouseholdBalance ? 'Earn Points' : 'E-Waste Reward Rates',
          key: const Key('reward-catalog-heading'),
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4.h),
        Text(
          widget.showHouseholdBalance
              ? 'See how many points eligible e-waste items can earn after validation.'
              : 'Current points awarded for validated e-waste items.',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 11.sp,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _catalogSection() => FutureBuilder<List<RewardPointRule>>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) return _catalogErrorCard();
          final rules = snapshot.data ?? const <RewardPointRule>[];
          if (rules.isEmpty) {
            return const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No reward rates are available.',
              message: 'Active e-waste reward rates will appear here.',
            );
          }
          return Column(
            children: [
              for (var index = 0; index < rules.length; index++) ...[
                _ruleCard(rules[index]),
                if (index != rules.length - 1) SizedBox(height: 10.h),
              ],
            ],
          );
        },
      );

  Widget _catalogErrorCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('reward-catalog-error'),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            SizedBox(height: 8.h),
            const Text(
              'Unable to load reward rates.',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleCard(RewardPointRule rule) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('reward-rule-${rule.id}'),
      child: InkWell(
        borderRadius: BorderRadius.circular(RecyTechTheme.cardRadius),
        onTap: () => _openRule(rule),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              _categoryIcon(rule),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (rule.description != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        rule.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10.5.sp,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _rateValue(rule),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    rule.pointsValue == null ? 'rate' : 'pts',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRule(RewardPointRule listedRule) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => FutureBuilder<RewardPointRule>(
        future: _repository.fetchRule(listedRule.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Unable to load reward details.'));
          }
          return _ruleDetails(snapshot.data!);
        },
      ),
    );
  }

  Widget _ruleDetails(RewardPointRule rule) {
    final scheme = Theme.of(context).colorScheme;
    final details = _userFacingDetails(rule);
    return SafeArea(
      child: ListView(
        key: const Key('reward-rule-details'),
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 24.h),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _categoryIcon(rule, size: 42.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  rule.title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _ratePanel(rule),
          if (rule.description != null) ...[
            SizedBox(height: 14.h),
            Text(
              rule.description!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            SizedBox(height: 18.h),
            Text(
              'Details',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 10.h),
            ...details.map(
              (entry) => _field(_label(entry.key), entry.value.toString()),
            ),
          ],
          SizedBox(height: 16.h),
          Text(
            'Points are added after an eligible drop-off is validated.',
            style: TextStyle(
              fontSize: 11.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryIcon(RewardPointRule rule, {double? size}) {
    final scheme = Theme.of(context).colorScheme;
    final dimension = size ?? 44.w;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        _iconFor(rule.title),
        color: scheme.primary,
        size: 22.sp,
      ),
    );
  }

  Widget _ratePanel(RewardPointRule rule) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_outlined, color: scheme.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              rule.pointsValue == null
                  ? 'Rate unavailable'
                  : '${_rateValue(rule)} points per item',
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, dynamic>> _userFacingDetails(RewardPointRule rule) {
    const hidden = {
      '_id',
      'id',
      'title',
      'name',
      'wasteType',
      'category',
      'description',
      'points',
      'pointsPerItem',
      'pointsPerKg',
      'isActive',
      'active',
      'createdAt',
      'updatedAt',
      '__v',
    };
    return rule.fields.entries
        .where((entry) => !hidden.contains(entry.key))
        .where((entry) =>
            entry.value is String || entry.value is num || entry.value is bool)
        .toList(growable: false);
  }

  Widget _field(String label, String value) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120.w, child: Text(label)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  String _rateValue(RewardPointRule rule) {
    final value = rule.pointsValue;
    if (value == null) return 'Unavailable';
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  String _label(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');

  IconData _iconFor(String title) {
    final value = title.toLowerCase();
    if (value.contains('phone') || value.contains('mobile')) {
      return Icons.smartphone_outlined;
    }
    if (value.contains('laptop') || value.contains('computer')) {
      return Icons.laptop_outlined;
    }
    if (value.contains('tv') || value.contains('monitor')) {
      return Icons.tv_outlined;
    }
    if (value.contains('battery')) return Icons.battery_std_outlined;
    return Icons.recycling_outlined;
  }
}
