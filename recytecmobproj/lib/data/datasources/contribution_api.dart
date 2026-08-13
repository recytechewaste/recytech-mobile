import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class ContributionApi {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchContributions() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.contributions);

    if (res.data is List) return List<dynamic>.from(res.data as List);
    if (res.data is Map) {
      final data = (res.data as Map)['data'] ?? (res.data as Map)['items'];
      if (data is List) return List<dynamic>.from(data);
    }
    return <dynamic>[];
  }
}
