import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class CollectorApi {
  final ApiClient _apiClient;

  CollectorApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<dynamic>> fetchQueue() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.collectorQueue);

    if (res.data is Map && (res.data as Map).containsKey('queue')) {
      final data = (res.data as Map)['queue'];
      if (data is List) return List<dynamic>.from(data);
    }

    if (res.data is List) {
      return List<dynamic>.from(res.data);
    }

    if (res.data is Map && (res.data as Map).containsKey('data')) {
      final data = (res.data as Map)['data'];
      if (data is List) return List<dynamic>.from(data);
    }

    return <dynamic>[];
  }

  Future<Map<String, dynamic>?> fetchCurrentJob() async {
    final Response res =
        await _apiClient.dio.get(ApiEndpoints.collectorCurrentJob);

    if (res.data is Map) {
      final map = res.data as Map;
      final data = map['currentJob'] ?? map['job'] ?? map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }

    return null;
  }

  Future<Map<String, dynamic>> startCollectionRequest(String requestId) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.startCollectionRequest(requestId),
    );

    if (res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final request = map['request'];
      if (request is Map) return Map<String, dynamic>.from(request);
      return map;
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> startNextCollection() async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.startNextCollection,
    );

    if (res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final request = map['request'];
      if (request is Map) return Map<String, dynamic>.from(request);
      return map;
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateRequest(
    String requestId,
    Map<String, dynamic> payload,
  ) async {
    final Response res = await _apiClient.dio.put(
      ApiEndpoints.requestById(requestId),
      data: payload,
    );

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }

    return <String, dynamic>{};
  }
}
