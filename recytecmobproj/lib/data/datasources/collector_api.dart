import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class CollectorApi {
  CollectorApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await _apiClient.dio.get(ApiEndpoints.collectorsMe);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> updateDutyStatus(String status) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.collectorsStatus,
      data: {'status': status},
    );
    return _map(response.data);
  }

  Future<List<Map<String, dynamic>>> fetchJobs({String? status}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.collectorsJobs,
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    return _list(response.data);
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.collectorsStats);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.requestById(requestId),
      data: {'status': status},
    );
    return _unwrapMap(response.data, const ['request', 'job', 'data']);
  }

  Future<Map<String, dynamic>> completeRequest(
    String requestId, {
    List<Map<String, dynamic>>? collectedWaste,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      if (collectedWaste != null && collectedWaste.isNotEmpty)
        'collectedWaste': collectedWaste,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    final response = await _apiClient.dio.patch(
      ApiEndpoints.completeRequest(requestId),
      data: payload,
    );
    return _unwrapMap(response.data, const ['request', 'job', 'data']);
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static Map<String, dynamic> _unwrapMap(
    dynamic value,
    List<String> keys,
  ) {
    final map = _map(value);
    for (final key in keys) {
      final nested = map[key];
      if (nested is Map) return nested.cast<String, dynamic>();
    }
    return map;
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    dynamic source = value;
    if (value is Map) {
      for (final key in const [
        'jobs',
        'requests',
        'data',
        'items',
        'results'
      ]) {
        if (value[key] is List) {
          source = value[key];
          break;
        }
      }
    }
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }
}
