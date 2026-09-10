import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/points_rewards_models.dart';
import 'package:recytecmobproj/data/models/unified_profile_model.dart';
import 'package:recytecmobproj/data/repositories/points_rewards_repository.dart';
import 'package:recytecmobproj/data/repositories/unified_profile_repository.dart';
import 'package:recytecmobproj/presentation/lgu/rewards/partner_rewards_screen.dart';
import 'package:recytecmobproj/presentation/user/rewards/rewards_screen.dart';

void main() {
  group('Household Rewards', () {
    testWidgets('renames screen and renders backend balance before rates',
        (tester) async {
      final profiles = _FakeProfileRepository(balance: 125);
      final rewards = _FakeRewardsRepository(rules: [_laptopRule]);

      await _pumpRewards(tester, profiles: profiles, rewards: rewards);

      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Reward Points Catalog'), findsNothing);
      expect(_balanceText(tester), '125 pts');
      expect(find.text('Earn Points'), findsOneWidget);
      expect(find.text('Validated Laptop'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('reward-balance-card'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('reward-rule-rule-1')))
              .dy,
        ),
      );
      expect(profiles.fetchCount, 1);
    });

    testWidgets('renders a legitimate zero balance', (tester) async {
      await _pumpRewards(
        tester,
        profiles: _FakeProfileRepository(balance: 0),
        rewards: _FakeRewardsRepository(rules: [_laptopRule]),
      );

      expect(_balanceText(tester), '0 pts');
      expect(find.byKey(const Key('reward-balance-error')), findsNothing);
    });

    testWidgets('failed balance is not presented as zero and catalog remains',
        (tester) async {
      await _pumpRewards(
        tester,
        profiles: _FakeProfileRepository(
          error: const UnifiedProfileException('Profile unavailable'),
        ),
        rewards: _FakeRewardsRepository(rules: [_laptopRule]),
      );

      expect(find.byKey(const Key('reward-balance-error')), findsOneWidget);
      expect(find.byKey(const Key('reward-balance-value')), findsNothing);
      expect(find.text('Validated Laptop'), findsOneWidget);
    });

    testWidgets('refresh updates both balance and catalog', (tester) async {
      final profiles = _FakeProfileRepository(balance: 10);
      final rewards = _FakeRewardsRepository(rules: [_laptopRule]);
      await _pumpRewards(tester, profiles: profiles, rewards: rewards);

      profiles.balance = 40;
      rewards.rules = [_phoneRule];
      await tester.tap(find.byTooltip('Refresh rewards'));
      await tester.pumpAndSettle();

      expect(_balanceText(tester), '40 pts');
      expect(find.text('Mobile Phone'), findsOneWidget);
      expect(find.text('Validated Laptop'), findsNothing);
      expect(profiles.fetchCount, 2);
      expect(rewards.catalogFetchCount, 2);
    });

    testWidgets('reward rule detail remains interactive', (tester) async {
      final rewards = _FakeRewardsRepository(rules: [_laptopRule]);
      await _pumpRewards(
        tester,
        profiles: _FakeProfileRepository(balance: 25),
        rewards: rewards,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reward-rule-rule-1')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('reward-rule-rule-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reward-rule-details')), findsOneWidget);
      expect(find.text('25 points per item'), findsOneWidget);
      expect(
        find.text(
          'Points are added after an eligible drop-off is validated.',
        ),
        findsOneWidget,
      );
      expect(rewards.detailFetchCount, 1);
    });

    testWidgets('has no overflow on representative compact viewports',
        (tester) async {
      for (final size in const [Size(320, 568), Size(375, 667)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await _pumpRewards(
          tester,
          profiles: _FakeProfileRepository(balance: 12345),
          rewards: _FakeRewardsRepository(rules: [_laptopRule, _phoneRule]),
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('role isolation', () {
    testWidgets('Partner gets informational rates without personal balance',
        (tester) async {
      final rewards = _FakeRewardsRepository(rules: [_laptopRule]);
      await tester.pumpWidget(_app(PartnerRewardsScreen(repository: rewards)));
      await tester.pumpAndSettle();

      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('E-Waste Reward Rates'), findsOneWidget);
      expect(find.byKey(const Key('reward-balance-card')), findsNothing);
      expect(find.byKey(const Key('reward-balance-error')), findsNothing);
      expect(find.text('Validated Laptop'), findsOneWidget);
    });

    test('Collector navigation does not include the Rewards screen', () {
      final source = File(
        'lib/presentation/collector/shell/collector_home_shell.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('RewardsScreen')));
      expect(source, isNot(contains('PartnerRewardsScreen')));
    });
  });
}

Future<void> _pumpRewards(
  WidgetTester tester, {
  required _FakeProfileRepository profiles,
  required _FakeRewardsRepository rewards,
}) async {
  await tester.pumpWidget(
    _app(RewardsScreen(repository: rewards, profileRepository: profiles)),
  );
  await tester.pumpAndSettle();
}

Widget _app(Widget home) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        theme: RecyTechTheme.light(),
        home: home,
      ),
    );

String _balanceText(WidgetTester tester) {
  final value = tester.widget<Text>(
    find.byKey(const Key('reward-balance-value')),
  );
  return value.textSpan!.toPlainText();
}

final _laptopRule = RewardPointRule.fromJson(const {
  '_id': 'rule-1',
  'category': 'Laptop',
  'title': 'Validated Laptop',
  'description': 'Eligible laptop drop-offs.',
  'pointsPerItem': 25,
  'createdAt': 'internal metadata',
});

final _phoneRule = RewardPointRule.fromJson(const {
  '_id': 'rule-2',
  'category': 'Mobile Phone',
  'title': 'Mobile Phone',
  'pointsPerItem': 12,
});

class _FakeProfileRepository extends UnifiedProfileRepository {
  _FakeProfileRepository({this.balance, this.error});

  int? balance;
  Object? error;
  int fetchCount = 0;

  @override
  Future<UnifiedProfile> fetchProfile() async {
    fetchCount++;
    if (error != null) throw error!;
    return UnifiedProfile.fromJson({
      'user': {
        '_id': 'user-1',
        'email': 'household@recytech.test',
        'role': AppRoles.household,
      },
      'resident': {
        '_id': 'resident-1',
        if (balance != null) 'pointsBalance': balance,
      },
    });
  }
}

class _FakeRewardsRepository extends PointsRewardsRepository {
  _FakeRewardsRepository({required this.rules});

  List<RewardPointRule> rules;
  int catalogFetchCount = 0;
  int detailFetchCount = 0;

  @override
  Future<List<RewardPointRule>> fetchCatalog() async {
    catalogFetchCount++;
    return List.unmodifiable(rules);
  }

  @override
  Future<RewardPointRule> fetchRule(String id) async {
    detailFetchCount++;
    return rules.firstWhere((rule) => rule.id == id);
  }
}
