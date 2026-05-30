import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class ContributionApi {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchContributions() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.contributions);

    return List<dynamic>.from(res.data);
  }
}
