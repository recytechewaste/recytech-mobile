import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exceptions.dart';
import '../models/points_rewards_models.dart';

class PointsRewardsRepositoryException implements Exception {
  const PointsRewardsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PointsRewardsRepository {
  PointsRewardsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<RewardPointRule>> fetchCatalog() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.rewardPoints,
      );

      return _items(response.data)
          .map(RewardPointRule.fromJson)
          .where((rule) => rule.id.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load reward rules.',
      );
    }
  }

  Future<RewardPointRule> fetchRule(String id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.rewardPointById(id),
      );

      final root = _map(response.data);
      final nested =
          root['rewardPoint'] ?? root['rule'] ?? root['data'] ?? root['point'];

      return RewardPointRule.fromJson(
        nested is Map
            ? nested.cast<String, dynamic>()
            : root,
      );
    } catch (error) {
      throw _mapError(
        error,
        'Unable to load this reward rule.',
      );
    }
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    dynamic items = value;

    if (value is Map) {
      items = value['points'] ??
          value['rewardPoints'] ??
          value['rules'] ??
          value['data'];
    }

    if (items is! List) {
      throw const FormatException(
        'Reward catalog response is incomplete.',
      );
    }

    return items
        .whereType<Map>()
        .map(
          (item) => item.cast<String, dynamic>(),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _map(dynamic value) {
    return value is Map
        ? value.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  PointsRewardsRepositoryException _mapError(
    Object error,
    String fallback,
  ) {
    if (error is DioException) {
      final server = error.response?.data;

      if (server is Map) {
        final message =
            (server['message'] ?? '').toString().trim();

        if (message.isNotEmpty) {
          return PointsRewardsRepositoryException(
            message,
          );
        }
      }

      if (error.error is ApiException) {
        return PointsRewardsRepositoryException(
          (error.error as ApiException).message,
        );
      }
    }

    return PointsRewardsRepositoryException(
      fallback,
    );
  }
}