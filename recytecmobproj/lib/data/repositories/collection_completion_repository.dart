import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/collected_item_model.dart';

abstract class CollectionCompletionRepository {
  Future<void> submitCollectionReport(CollectionReportDraft report);
  Future<List<CollectionReportDraft>> fetchCompletedReports();
}

class ApiCollectionCompletionRepository
    implements CollectionCompletionRepository {
  ApiCollectionCompletionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<void> submitCollectionReport(CollectionReportDraft report) async {
    final idempotencyKey = report.idempotencyKey ??
        'complete-${report.assignmentId}-${report.startedAt.microsecondsSinceEpoch}';
    report.idempotencyKey = idempotencyKey;

    await _apiClient.dio.post(
      ApiEndpoints.completeCollectionRequest(report.assignmentId),
      data: {
        ...report.toJson(),
        'beforeImage': await _imageDataUrl(report.beforeImagePath, 'before'),
        'afterImage': await _imageDataUrl(report.afterImagePath, 'after'),
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  @override
  Future<List<CollectionReportDraft>> fetchCompletedReports() async {
    final response = await _apiClient.dio.get(ApiEndpoints.collectorHistory);
    final reports = _extractItems(response.data);
    return reports
        .whereType<Map>()
        .map(
          (item) => CollectionReportDraft.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
  }

  Future<String> _imageDataUrl(String? path, String label) async {
    final value = (path ?? '').trim();
    if (value.isEmpty) {
      throw StateError('$label photo is required.');
    }
    final file = File(value);
    if (!file.existsSync()) {
      throw StateError('$label photo file is unavailable.');
    }

    final bytes = await file.readAsBytes();
    final mime = _mimeForPath(value);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final items =
          map['reports'] ?? map['history'] ?? map['data'] ?? map['items'];
      if (items is List) return items;
    }
    return const [];
  }
}

/// Temporary completion boundary until the backend exposes collection reports.
///
/// Backend contract still needed:
/// POST /api/collector/collection-reports
/// Body: CollectionReportDraft.toJson(), including requestId, collectorId,
/// optional LGU/bin context, before/after evidence, confirmed item list,
/// confirmedCategorySummary, and totalQuantity. Collector-entered weight is
/// intentionally not part of the Phase 3 mobile contract.
/// GET /api/collector/collection-reports?collectorId=:id
class MockCollectionCompletionRepository
    implements CollectionCompletionRepository {
  static final List<CollectionReportDraft> _reports = <CollectionReportDraft>[];

  @override
  Future<void> submitCollectionReport(CollectionReportDraft report) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _reports.removeWhere((item) => item.assignmentId == report.assignmentId);
    _reports.add(report);
  }

  @override
  Future<List<CollectionReportDraft>> fetchCompletedReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<CollectionReportDraft>.from(_reports)
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });
  }
}
