import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class RequestApi {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchRequests() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.requests);

    return List<dynamic>.from(res.data);
  }

  Future<List<dynamic>> fetchMyRequests() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.myRequests);

    return List<dynamic>.from(res.data);
  }

  Future<List<dynamic>> fetchMyTransactions() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.myTransactions);

    if (res.data is Map && (res.data as Map).containsKey('transactions')) {
      final transactions = (res.data as Map)['transactions'];
      if (transactions is List) return List<dynamic>.from(transactions);
    }

    if (res.data is List) {
      return List<dynamic>.from(res.data as List);
    }

    return <dynamic>[];
  }

  Future<Map<String, dynamic>> createRequest(
    Map<String, dynamic> payload,
  ) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.requests,
      data: payload,
    );

    return Map<String, dynamic>.from(res.data);
  }

  Future<List<dynamic>> fetchActiveWasteCategories() async {
    final Response res = await _apiClient.dio.get(
      ApiEndpoints.activeWasteCategories,
    );

    if (res.data is Map && (res.data as Map).containsKey('categories')) {
      final categories = (res.data as Map)['categories'];
      if (categories is List) return List<dynamic>.from(categories);
    }

    if (res.data is List) {
      return List<dynamic>.from(res.data as List);
    }

    return <dynamic>[];
  }
}
