import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/data/repositories/points_rewards_repository.dart';

void main() {
  test('reward catalog and detail use authoritative read endpoints', () async {
    final requests = <RequestOptions>[];
    final repository = PointsRewardsRepository(
      apiClient: ApiClient(dio: _recordingDio(requests)),
    );

    final catalog = await repository.fetchCatalog();
    final detail = await repository.fetchRule('rule-1');

    expect(requests.map((request) => request.method), ['GET', 'GET']);
    expect(requests.map((request) => request.path),
        ['/reward-points', '/reward-points/rule-1']);
    expect(catalog.single.id, 'rule-1');
    expect(catalog.single.title, 'Validated Laptop');
    expect(catalog.single.fields['points'], 25);
    expect(detail.id, 'rule-1');
    expect(detail.description, 'Points awarded for a validated laptop.');
  });

  test('catalog model has no user balance or redemption behavior', () async {
    final requests = <RequestOptions>[];
    final repository = PointsRewardsRepository(
      apiClient: ApiClient(dio: _recordingDio(requests)),
    );

    final rule = (await repository.fetchCatalog()).single;
    expect(rule.fields, isNot(contains('balance')));
    expect(requests.single.method, 'GET');
    expect(requests.single.path.contains('redeem'), isFalse);
  });

  test('empty catalog remains a valid read-only state', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(
          Response(requestOptions: options, data: {'rewardPoints': []}));
    }));
    final repository = PointsRewardsRepository(
      apiClient: ApiClient(dio: dio),
    );
    expect(await repository.fetchCatalog(), isEmpty);
  });
}

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(headers: const {'Authorization': 'Bearer test'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    final rule = {
      '_id': 'rule-1',
      'title': 'Validated Laptop',
      'description': 'Points awarded for a validated laptop.',
      'points': 25,
      'active': true,
    };
    handler.resolve(Response(
      requestOptions: options,
      data: options.path == '/reward-points'
          ? {
              'rewardPoints': [rule]
            }
          : {'rewardPoint': rule},
    ));
  }));
  return dio;
}
