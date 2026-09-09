import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/core/utils/helpers.dart';
import 'package:recytecmobproj/data/datasources/collector_api.dart';
import 'package:recytecmobproj/data/models/collected_item_model.dart';
import 'package:recytecmobproj/data/repositories/collection_completion_repository.dart';

void main() {
  group('Collector completion continuation contract', () {
    test('uses PATCH JSON and permits an empty body', () async {
      final requests = <RequestOptions>[];
      final api = CollectorApi(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      await api.completeRequest('request-1');

      expect(ApiEndpoints.completeRequest('request-1'),
          '/requests/request-1/complete');
      expect(requests, hasLength(1));
      expect(requests.single.method, 'PATCH');
      expect(requests.single.contentType, Headers.jsonContentType);
      expect(requests.single.data, <String, dynamic>{});
    });

    test('serializes only confirmed completion fields and parses response',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiCollectionCompletionRepository(
        api: CollectorApi(
          apiClient: ApiClient(dio: _recordingDio(requests)),
        ),
      );
      final draft = CollectionReportDraft(
        assignmentId: 'request-1',
        requestReference: 'CR-1',
        collectorName: 'Collector One',
        collectorId: 'collector-secret',
        lguId: 'partner-secret',
        beforeImagePath: 'before.jpg',
        beforeCondition: 'Full',
        initialRemarks: 'Items sorted',
        afterImagePath: 'after.jpg',
        finalBinStatus: 'Empty',
        finalRemarks: 'Bin cleared',
        totalWeightKg: 45.5,
        items: [
          CollectedEWasteItem(
            id: 'scan-1',
            imagePath: 'battery.jpg',
            aiPredictedClass: 'smartphone',
            confirmedClass: 'battery',
            quantity: 12,
          ),
          CollectedEWasteItem(
            id: 'scan-2',
            imagePath: 'phone.jpg',
            aiPredictedClass: 'battery',
            confirmedClass: 'smartphone',
            quantity: 3,
          ),
        ],
      );

      final completed = await repository.submitCollectionReport(draft);

      expect(requests, hasLength(1));
      final body = (requests.single.data as Map).cast<String, dynamic>();
      expect(body.keys, unorderedEquals(['collectedWaste', 'notes']));
      expect(body['notes'],
          'Before: Full. Items sorted. After: Empty. Bin cleared');
      expect(body['collectedWaste'], [
        {'category': 'Battery', 'quantity': 12, 'unit': 'pcs'},
        {'category': 'Mobile Devices', 'quantity': 3, 'unit': 'pcs'},
      ]);
      for (final item in body['collectedWaste'] as List) {
        expect((item as Map).keys,
            unorderedEquals(['category', 'quantity', 'unit']));
      }
      for (final unsupported in const [
        'collectorId',
        'profileId',
        'userId',
        'beforeImage',
        'beforeImagePath',
        'afterImage',
        'afterImagePath',
        'images',
        'weight',
        'totalWeightKg',
        'status',
        'finalStatus',
      ]) {
        expect(body, isNot(contains(unsupported)));
      }
      expect(
          requests.where((request) => request.path.contains('/bin')), isEmpty);

      expect(completed.isCompleted, isTrue);
      expect(completed.collectedWaste, hasLength(2));
      expect(completed.collectedWaste.first.category, 'Battery');
      expect(completed.collectedWaste.first.quantity, 12);
      expect(completed.collectedWaste.first.unit, 'pcs');
      expect(
          completed.completionDate, DateTime.parse('2026-09-08T04:05:06.000Z'));
    });

    test('supports canonical strings and integer, decimal, and zero quantity',
        () {
      const items = [
        CollectedWastePayloadItem(
          category: 'Battery',
          quantity: 10,
          unit: 'pcs',
        ),
        CollectedWastePayloadItem(
          category: 'Mobile Devices',
          quantity: 2.5,
          unit: 'units',
        ),
        CollectedWastePayloadItem(
          category: 'Other',
          quantity: 0,
          unit: 'pcs',
        ),
      ];

      expect(items.map((item) => item.toJson()).toList(), [
        {'category': 'Battery', 'quantity': 10, 'unit': 'pcs'},
        {'category': 'Mobile Devices', 'quantity': 2.5, 'unit': 'units'},
        {'category': 'Other', 'quantity': 0, 'unit': 'pcs'},
      ]);
      expect(items.every((item) => item.isValid), isTrue);
    });

    test('rejects only schema-invalid collected waste items', () {
      const invalid = [
        CollectedWastePayloadItem(category: '', quantity: 1, unit: 'pcs'),
        CollectedWastePayloadItem(
            category: 'Battery', quantity: -1, unit: 'pcs'),
        CollectedWastePayloadItem(
            category: 'Battery', quantity: double.nan, unit: 'pcs'),
        CollectedWastePayloadItem(category: 'Battery', quantity: 1, unit: ''),
      ];

      expect(invalid.every((item) => !item.isValid), isTrue);
      for (final item in invalid) {
        expect(item.toJson, throwsFormatException);
      }
    });

    for (final scenario in const [
      (
        status: 400,
        message: 'This collection request has already been completed.'
      ),
      (
        status: 403,
        message: 'Forbidden: You can only complete requests assigned to you.'
      ),
      (status: 404, message: 'Request not found'),
    ]) {
      test('surfaces safe ${scenario.status} completion message', () async {
        final client = ApiClient();
        client.dio.httpClientAdapter = _ResponseAdapter(
          statusCode: scenario.status,
          body: jsonEncode({'message': scenario.message}),
        );
        final repository = ApiCollectionCompletionRepository(
          api: CollectorApi(apiClient: client),
        );

        try {
          await repository.submitCollectionReport(_emptyDraft());
          fail('Expected completion request to fail.');
        } catch (error) {
          expect(
            userFacingError(error, fallback: 'Unable to complete collection.'),
            scenario.message,
          );
        }
      });
    }
  });
}

CollectionReportDraft _emptyDraft() => CollectionReportDraft(
      assignmentId: 'request-1',
      requestReference: 'CR-1',
      collectorName: 'Collector One',
    );

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(
    contentType: Headers.jsonContentType,
    headers: const {'Authorization': 'Bearer test'},
  ));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    final submitted = options.data is Map
        ? (options.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        'message': 'Collection request completed successfully.',
        'request': {
          '_id': 'request-1',
          'status': 'completed',
          'notes': submitted['notes'],
          'collectedWaste': submitted['collectedWaste'] ?? const [],
          'completionDate': '2026-09-08T04:05:06.000Z',
        },
      },
    ));
  }));
  return dio;
}

class _ResponseAdapter implements HttpClientAdapter {
  const _ResponseAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

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
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
