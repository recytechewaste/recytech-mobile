import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class CollectorApi {
  final ApiClient _apiClient;

  CollectorApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<dynamic>> fetchJobs() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.requests);

    if (res.data is List) {
      return List<dynamic>.from(res.data);
    }

    if (res.data is Map && (res.data as Map).containsKey('data')) {
      final data = (res.data as Map)['data'];
      if (data is List) return List<dynamic>.from(data);
    }

    return <dynamic>[];
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
