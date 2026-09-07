import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/repositories/bin_monitoring_repository.dart';

void main() {
  test('missing sensor values remain unavailable instead of becoming current',
      () {
    final monitoring = BinMonitoringData.fromJson(const {
      'binId': 'BIN-NO-READING',
      'fillPercentage': null,
      'distanceCm': null,
      'lastUpdatedAt': null,
    });

    expect(monitoring.fillPercentage, isNull);
    expect(monitoring.distanceCm, isNull);
    expect(monitoring.lastUpdatedAt, isNull);
    expect(SensorReadingFreshness.status(monitoring.lastUpdatedAt), 'Unknown');
  });

  test('partner bins repository accepts a successful empty bins object',
      () async {
    final repository = _repositoryFor('{"bins":[]}');

    expect(await repository.fetchAssignedBins(), isEmpty);
  });

  test('partner bins repository accepts the compatible root-list shape',
      () async {
    final repository = _repositoryFor(
      '[{"binCode":"BIN-1","name":"Test Bin","address":"Test"}]',
    );

    final bins = await repository.fetchAssignedBins();
    expect(bins.single.binId, 'BIN-1');
  });

  test('partner bins repository rejects malformed successful JSON', () async {
    final repository = _repositoryFor('{"message":"not a bins response"}');

    await expectLater(
      repository.fetchAssignedBins(),
      throwsA(isA<FormatException>()),
    );
  });

  test('partner bins repository does not turn authorization errors into empty',
      () async {
    final repository = _repositoryFor(
      '{"message":"Not authorized."}',
      statusCode: 403,
    );

    await expectLater(
      repository.fetchAssignedBins(),
      throwsA(isA<DioException>()),
    );
  });
}

ApiPartnerBinRepository _repositoryFor(String body, {int statusCode = 200}) {
  final client = ApiClient();
  client.dio.httpClientAdapter = _ResponseAdapter(body, statusCode);
  return ApiPartnerBinRepository(apiClient: client);
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.body, this.statusCode);

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
