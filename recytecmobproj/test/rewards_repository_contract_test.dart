import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/data/models/points_rewards_models.dart';
import 'package:recytecmobproj/data/repositories/points_rewards_repository.dart';
import 'package:recytecmobproj/presentation/user/rewards/rewards_screen.dart';

void main() {
  test('zero reward responses load as a valid empty state', () async {
    final repository = _repository({
      '/household/points': '{"balance":null,"transactions":null}',
      '/household/rewards': '{"balance":0,"rewards":null}',
      '/household/reward-redemptions': '{"redemptions":null}',
    });

    final summary = await repository.fetchPointsSummary();
    final rewards = await repository.fetchHouseholdRewards();
    final redemptions = await repository.fetchHouseholdRedemptions();

    expect(summary.balance, 0);
    expect(summary.transactions, isEmpty);
    expect(rewards, isEmpty);
    expect(redemptions, isEmpty);
  });

  test('malformed reward JSON remains a real load error', () async {
    final repository = _repository({
      '/household/rewards': '{"message":"not a rewards response"}',
    });

    await expectLater(
      repository.fetchHouseholdRewards(),
      throwsA(isA<PointsRewardsRepositoryException>()),
    );
  });

  testWidgets(
      'Rewards screen renders zero rewards as an intentional empty state',
      (tester) async {
    await tester.pumpWidget(_app(_FakeRewardsRepository.empty()));
    await tester.pumpAndSettle();

    expect(find.text('0 pts'), findsOneWidget);
    expect(find.text('No rewards are available yet.'), findsOneWidget);
    expect(
      find.text(
        'Available rewards from partner organizations will appear here.',
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('You have no reward activity yet.'), findsOneWidget);
    expect(
      find.text('Unable to load rewards. Please try again.'),
      findsNothing,
    );
  });

  testWidgets('Rewards screen keeps real failures in the error state',
      (tester) async {
    await tester.pumpWidget(_app(_FakeRewardsRepository.failure()));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load rewards. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No rewards are available yet.'), findsNothing);
  });

  testWidgets('Rewards screen still renders configured offers', (tester) async {
    await tester.pumpWidget(_app(_FakeRewardsRepository.withOffer()));
    await tester.pumpAndSettle();

    expect(find.text('Configured Test Reward'), findsOneWidget);
    expect(find.text('No rewards are available yet.'), findsNothing);
  });
}

Widget _app(PointsRewardsRepository repository) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      home: RewardsScreen(repository: repository),
    ),
  );
}

PointsRewardsRepository _repository(Map<String, String> responses) {
  final client = ApiClient();
  client.dio.httpClientAdapter = _RewardsAdapter(responses);
  return PointsRewardsRepository(apiClient: client);
}

class _RewardsAdapter implements HttpClientAdapter {
  _RewardsAdapter(this.responses);

  final Map<String, String> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = responses[options.path];
    return ResponseBody.fromString(
      body ?? '{"message":"missing test response"}',
      body == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRewardsRepository extends PointsRewardsRepository {
  _FakeRewardsRepository._({
    required this.shouldFail,
    this.offers = const [],
  });

  factory _FakeRewardsRepository.empty() {
    return _FakeRewardsRepository._(shouldFail: false);
  }

  factory _FakeRewardsRepository.failure() {
    return _FakeRewardsRepository._(shouldFail: true);
  }

  factory _FakeRewardsRepository.withOffer() {
    return _FakeRewardsRepository._(
      shouldFail: false,
      offers: const [
        PartnerRewardOffer(
          id: 'reward-test',
          title: 'Configured Test Reward',
          pointsCost: 10,
          active: true,
        ),
      ],
    );
  }

  final bool shouldFail;
  final List<PartnerRewardOffer> offers;

  @override
  Future<PointsSummary> fetchPointsSummary() async {
    if (shouldFail) {
      throw const PointsRewardsRepositoryException('Network failure.');
    }
    return const PointsSummary(balance: 0);
  }

  @override
  Future<List<PartnerRewardOffer>> fetchHouseholdRewards() async {
    return offers;
  }

  @override
  Future<List<RewardRedemptionRecord>> fetchHouseholdRedemptions() async {
    return const [];
  }
}
