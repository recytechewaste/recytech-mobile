import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../datasources/request_api.dart';
import '../models/bin_monitoring_models.dart';

abstract class CollectionRequestRepository {
  Future<List<CollectionRequestSummary>> fetchCollectionRequests();

  Future<CollectionRequestSummary> createCollectionRequest({
    required String lguId,
    required String binId,
    required String binLocation,
    required double? fillPercentage,
    required String fullnessStatus,
    required DateTime requestedAt,
    String? remarks,
  });
}

class DuplicateCollectionRequestException implements Exception {
  const DuplicateCollectionRequestException(this.message, {this.request});

  final String message;
  final CollectionRequestSummary? request;

  @override
  String toString() => message;
}

class CollectionRequestException implements Exception {
  const CollectionRequestException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiCollectionRequestRepository implements CollectionRequestRepository {
  ApiCollectionRequestRepository({
    ApiClient? apiClient,
    RequestApi? requestApi,
  }) : _requestApi = requestApi ?? RequestApi(apiClient: apiClient);

  final RequestApi _requestApi;

  @override
  Future<List<CollectionRequestSummary>> fetchCollectionRequests() async {
    final response = await _requestApi.fetchRequests();
    return response.requests
        .map(CollectionRequestSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CollectionRequestSummary> createCollectionRequest({
    required String lguId,
    required String binId,
    required String binLocation,
    required double? fillPercentage,
    required String fullnessStatus,
    required DateTime requestedAt,
    String? remarks,
  }) async {
    try {
      final response = await _requestApi.createRequest({
        'binId': binId,
        if ((remarks ?? '').trim().isNotEmpty) 'notes': remarks!.trim(),
      });

      return CollectionRequestSummary.fromJson(_extractObject(response));
    } on DioException catch (e) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      if (statusCode == 409 && data is Map) {
        final map = data.cast<String, dynamic>();
        final request = map['request'] is Map
            ? CollectionRequestSummary.fromJson(
                (map['request'] as Map).cast<String, dynamic>(),
              )
            : null;
        throw DuplicateCollectionRequestException(
          (map['message'] ??
                  'A collection request for this bin is already active.')
              .toString(),
          request: request,
        );
      }
      throw CollectionRequestException(
        _safeBackendMessage(e) ?? 'Unable to create request. Please try again.',
        statusCode: statusCode,
      );
    }
  }

  String? _safeBackendMessage(DioException error) {
    final responseMessage =
        ApiClient.responseErrorMessage(error.response?.data);
    final apiMessage = error.error is ApiException
        ? (error.error as ApiException).message
        : null;
    final message = (responseMessage ?? apiMessage ?? '').trim();
    final lowered = message.toLowerCase();
    if (message.isEmpty ||
        message.length > 180 ||
        lowered.contains('<html') ||
        lowered.contains('dioexception') ||
        lowered.contains('mongodb') ||
        lowered.contains('/requests') ||
        lowered.contains('bearer ') ||
        lowered.contains('jwt')) {
      return null;
    }
    return message;
  }

  Map<String, dynamic> _extractObject(dynamic payload) {
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final nested = map['request'] ?? map['data'];
      if (nested is Map) return nested.cast<String, dynamic>();
      return map;
    }
    return <String, dynamic>{};
  }
}

/// Temporary mock repository.
///
/// This mock follows the same shared request model as POST /requests.
class MockCollectionRequestRepository implements CollectionRequestRepository {
  static final List<CollectionRequestSummary> _requests = [
    CollectionRequestSummary(
      id: 'CR-1007',
      lguId: 'LGU-DEMO-001',
      binId: 'BIN-LGU-001',
      location: 'Municipal Hall East Entrance',
      fillPercentage: 92,
      fullnessStatus: FullnessStatuses.full,
      status: CollectionRequestStatuses.collectorAssigned,
      requestedAt: DateTime(2026, 8, 3, 10, 20),
      reason: 'Full bin',
      remarks: 'Prioritize before market day.',
      assignedCollectorName: 'Juan Collector',
    ),
    CollectionRequestSummary(
      id: 'CR-1006',
      lguId: 'LGU-DEMO-001',
      binId: 'BIN-LGU-003',
      location: 'Barangay San Isidro Covered Court',
      fillPercentage: null,
      fullnessStatus: FullnessStatuses.requiresInspection,
      status: CollectionRequestStatuses.pending,
      requestedAt: DateTime(2026, 8, 2, 15, 45),
      reason: 'Inspection requested',
      remarks: 'Sensor reading unavailable.',
    ),
    CollectionRequestSummary(
      id: 'CR-1005',
      lguId: 'LGU-DEMO-001',
      binId: 'BIN-LGU-004',
      location: 'City Library South Wing',
      fillPercentage: 74,
      fullnessStatus: FullnessStatuses.nearlyFull,
      status: CollectionRequestStatuses.completed,
      requestedAt: DateTime(2026, 7, 29, 9, 5),
      reason: 'Nearly full',
      assignedCollectorName: 'Ana Collector',
    ),
  ];

  @override
  Future<List<CollectionRequestSummary>> fetchCollectionRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final copy = List<CollectionRequestSummary>.from(_requests);
    copy.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return copy;
  }

  @override
  Future<CollectionRequestSummary> createCollectionRequest({
    required String lguId,
    required String binId,
    required String binLocation,
    required double? fillPercentage,
    required String fullnessStatus,
    required DateTime requestedAt,
    String? remarks,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final request = CollectionRequestSummary(
      id: 'CR-${1008 + _requests.length}',
      lguId: lguId,
      binId: binId,
      location: binLocation,
      fillPercentage: fillPercentage,
      fullnessStatus: fullnessStatus,
      status: CollectionRequestStatuses.pending,
      requestedAt: requestedAt,
      reason: FullnessStatuses.label(fullnessStatus),
      remarks: remarks,
    );
    _requests.insert(0, request);
    return request;
  }

  static CollectionRequestSummary? activeRequestForBin(String binId) {
    for (final request in _requests) {
      if (request.binId == binId &&
          CollectionRequestStatuses.isActive(request.status)) {
        return request;
      }
    }
    return null;
  }
}
