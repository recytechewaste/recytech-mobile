import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/points_rewards_models.dart';
import '../../../data/repositories/points_rewards_repository.dart';
import '../../../widgets/empty_state.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key, this.repository});

  final PointsRewardsRepository? repository;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final PointsRewardsRepository _repository;
  late Future<List<RewardPointRule>> _future;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PointsRewardsRepository();
    _future = _repository.fetchCatalog();
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _repository.fetchCatalog();
    setState(() => _future = future);
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
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
          final rule = snapshot.data!;
          return ListView(
            padding: EdgeInsets.all(18.w),
            children: [
              Text(rule.title,
                  style:
                      TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
              if (rule.description != null) ...[
                SizedBox(height: 8.h),
                Text(rule.description!),
              ],
              SizedBox(height: 14.h),
              ...rule.displayFields.entries.map(
                (entry) => _field(_label(entry.key), _display(entry.value)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Reward Points Catalog'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<RewardPointRule>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading reward rules…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load reward rules. Please try again.',
              onRetry: _refresh,
            );
          }
          final rules = snapshot.data ?? const <RewardPointRule>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              children: rules.isEmpty
                  ? const [
                      EmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'No reward rules are available.',
                        message: 'Active reward rates will appear here.',
                      ),
                    ]
                  : rules.map(_card).toList(growable: false),
            ),
          );
        },
      ),
    );
  }

  Widget _card(RewardPointRule rule) => Card(
        child: ListTile(
          onTap: () => _openRule(rule),
          leading: const Icon(Icons.emoji_events_outlined),
          title: Text(rule.title),
          subtitle: rule.description == null ? null : Text(rule.description!),
          trailing: const Icon(Icons.chevron_right),
        ),
      );

  Widget _field(String label, String value) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120.w, child: Text(label)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  String _label(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');

  String _display(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }
    if (value is List) return value.join(', ');
    return value.toString();
  }
}
