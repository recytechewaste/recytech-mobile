import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exceptions.dart';

class RequestListResponse {
  const RequestListResponse({
    required this.requests,
    required this.totalRequests,
    required this.totalPages,
    required this.currentPage,
  });

  final List<Map<String, dynamic>> requests;
  final int totalRequests;
  final int totalPages;
  final int currentPage;

  factory RequestListResponse.fromJson(dynamic data) {
    if (data is! Map ||
        data['requests'] is! List ||
        data['totalRequests'] is! num ||
        data['totalPages'] is! num ||
        data['currentPage'] is! num) {
      throw ApiException(
        'Requests could not be loaded because the server response was incomplete.',
      );
    }

    final requests = (data['requests'] as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);

    return RequestListResponse(
      requests: requests,
      totalRequests: (data['totalRequests'] as num).toInt(),
      totalPages: (data['totalPages'] as num).toInt(),
      currentPage: (data['currentPage'] as num).toInt(),
    );
  }
}

class RequestApi {
  RequestApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<RequestListResponse> fetchRequests({
    int? page,
    int? limit,
    String? status,
    String? search,
  }) async {
    final Response res = await _apiClient.dio.get(
      ApiEndpoints.requests,
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    return RequestListResponse.fromJson(res.data);
  }

  Future<Map<String, dynamic>> fetchRequest(String requestId) async {
    final Response res =
        await _apiClient.dio.get(ApiEndpoints.requestById(requestId));

    if (res.data is! Map) {
      throw ApiException(
        'Request details could not be loaded because the server response was incomplete.',
      );
    }

    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> fetchMyRequests() async {
    final Response res = await _apiClient.dio.get(
      ApiEndpoints.myRequests,
    );

    return _readList(res.data);
  }

  Future<List<dynamic>> fetchMyTransactions() async {
    final Response res = await _apiClient.dio.get(
      ApiEndpoints.myTransactions,
    );

    if (res.data is Map && (res.data as Map).containsKey('transactions')) {
      final transactions = (res.data as Map)['transactions'];

      if (transactions is List) {
        return List<dynamic>.from(transactions);
      }
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

    if (res.data is! Map) {
      throw ApiException(
        'Request could not be created because the server response was incomplete.',
      );
    }

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> fetchActiveWasteCategories() async {
    final Response res = await _apiClient.dio.get(
      ApiEndpoints.rewardPoints,
    );

    final data = res.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      for (final key in [
        'categoryList',
        'categories',
        'wasteTypes',
        'points',
        'data',
      ]) {
        final value = map[key];

        if (value is List) {
          return List<dynamic>.from(value);
        }
      }
    }

    if (data is List) {
      return List<dynamic>.from(data);
    }

    return <dynamic>[];
  }

  List<dynamic> _readList(dynamic data) {
    if (data is List) {
      return List<dynamic>.from(data);
    }

    if (data is Map) {
      for (final key in [
        'data',
        'requests',
        'items',
        'results',
      ]) {
        final value = data[key];

        if (value is List) {
          return List<dynamic>.from(value);
        }
      }
    }

    return <dynamic>[];
  }
}
