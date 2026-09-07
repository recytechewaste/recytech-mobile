import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  Future<PointsSummary> fetchPointsSummary() async {
    try {
      final response = await _getRewards(ApiEndpoints.householdPoints);
      return PointsSummary.fromJson(_requiredMap(response.data));
    } catch (error) {
      throw _mapError(error, 'Unable to load your points.');
    }
  }

  Future<List<PartnerRewardOffer>> fetchHouseholdRewards() async {
    try {
      final response = await _getRewards(ApiEndpoints.householdRewards);
      return _items(response.data, 'rewards')
          .whereType<Map>()
          .map((item) =>
              PartnerRewardOffer.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, 'Unable to load partner rewards.');
    }
  }

  Future<RewardRedemptionRecord> redeemReward(String rewardId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.redeemHouseholdReward(rewardId),
        data: {
          'idempotencyKey':
              'redeem-$rewardId-${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      final data = _requiredMap(response.data);
      return RewardRedemptionRecord.fromJson(
        _requiredMap(data['redemption'] ?? data),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to redeem this reward.');
    }
  }

  Future<List<RewardRedemptionRecord>> fetchHouseholdRedemptions() async {
    try {
      final response =
          await _getRewards(ApiEndpoints.householdRewardRedemptions);
      return _items(response.data, 'redemptions')
          .whereType<Map>()
          .map((item) =>
              RewardRedemptionRecord.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, 'Unable to load reward redemptions.');
    }
  }

  Future<List<PartnerRewardOffer>> fetchPartnerRewards() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.partnerRewards);
      return _items(response.data, 'rewards')
          .whereType<Map>()
          .map((item) =>
              PartnerRewardOffer.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, 'Unable to load partner rewards.');
    }
  }

  Future<PartnerRewardOffer> savePartnerReward({
    String? id,
    required String title,
    required String description,
    required int pointsCost,
    required bool active,
    List<String> applicableBinIds = const [],
  }) async {
    try {
      final data = {
        'title': title,
        'description': description,
        'pointsCost': pointsCost,
        'active': active,
        'applicableBinIds': applicableBinIds,
      };
      final response = id == null
          ? await _apiClient.dio.post(ApiEndpoints.partnerRewards, data: data)
          : await _apiClient.dio
              .put(ApiEndpoints.partnerRewardById(id), data: data);
      return PartnerRewardOffer.fromJson(
        _requiredMap(
          _requiredMap(response.data)['reward'] ?? response.data,
        ),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to save partner reward.');
    }
  }

  Future<List<RewardRedemptionRecord>> fetchPartnerRedemptions() async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.partnerRewardRedemptions);
      return _items(response.data, 'redemptions')
          .whereType<Map>()
          .map((item) =>
              RewardRedemptionRecord.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, 'Unable to load redemption requests.');
    }
  }

  Future<RewardRedemptionRecord> fulfillRedemption(String id) async {
    try {
      final response =
          await _apiClient.dio.patch(ApiEndpoints.fulfillPartnerRedemption(id));
      return RewardRedemptionRecord.fromJson(
        _requiredMap(
          _requiredMap(response.data)['redemption'] ?? response.data,
        ),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to fulfill this redemption.');
    }
  }

  Future<RewardRedemptionRecord> cancelRedemption(String id) async {
    try {
      final response =
          await _apiClient.dio.patch(ApiEndpoints.cancelPartnerRedemption(id));
      return RewardRedemptionRecord.fromJson(
        _requiredMap(
          _requiredMap(response.data)['redemption'] ?? response.data,
        ),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to cancel this redemption.');
    }
  }

  Future<Response<dynamic>> _getRewards(String path) async {
    try {
      final response = await _apiClient.dio.get(path);
      _debugRewardsResponse(response.statusCode, response.data);
      return response;
    } on DioException catch (error) {
      _debugRewardsResponse(
        error.response?.statusCode,
        error.response?.data,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _requiredMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    throw const FormatException('Rewards response must be a JSON object.');
  }

  List<dynamic> _items(dynamic value, String key) {
    if (value is List) return value;
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final hasKnownKey = map.containsKey(key) ||
          map.containsKey('items') ||
          map.containsKey('results');
      if (!hasKnownKey) {
        throw FormatException('Rewards response does not contain $key.');
      }
      final items = map[key] ?? map['items'] ?? map['results'];
      if (items == null) return const [];
      if (items is List) return items;
      throw FormatException('Rewards $key must be a list.');
    }
    throw const FormatException(
      'Rewards response must be a list or an object containing a list.',
    );
  }

  void _debugRewardsResponse(int? statusCode, dynamic body) {
    if (!kDebugMode) return;
    debugPrint('[REWARDS] status=$statusCode');
    debugPrint('[REWARDS] bodyType=${body.runtimeType}');
    debugPrint('[REWARDS] responseShape=${_sanitizedShape(body)}');
  }

  String _sanitizedShape(dynamic value) {
    if (value == null) return 'null';
    if (value is List) return 'List(length=${value.length})';
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      final fields = keys.map((key) {
        final field = value[key];
        if (field is List) return '$key=List(length=${field.length})';
        if (field is Map) return '$key=Map(keys=${field.keys.length})';
        return '$key=${field.runtimeType}';
      }).join(', ');
      return 'Map($fields)';
    }
    return value.runtimeType.toString();
  }

  PointsRewardsRepositoryException _mapError(
    Object error,
    String fallback,
  ) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = (data['message'] ?? '').toString().trim();
        if (message.isNotEmpty) {
          return PointsRewardsRepositoryException(message);
        }
      }
      final exception = error.error;
      if (exception is ApiException) {
        return PointsRewardsRepositoryException(exception.message);
      }
    }
    return PointsRewardsRepositoryException(fallback);
  }
}
