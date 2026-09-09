import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/drop_off_record_model.dart';

abstract class PartnerValidationRepository {
  Future<List<DropOffRecord>> fetchPendingDropOffs();

  Future<void> validateDropOff(
    String id, {
    required String action,
    String? validationNotes,
  });
}

class ApiPartnerValidationRepository implements PartnerValidationRepository {
  ApiPartnerValidationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<DropOffRecord>> fetchPendingDropOffs() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.binDropoffs);
      final records = _items(response.data)
          .whereType<Map>()
          .map((item) => DropOffRecord.fromJson(item.cast<String, dynamic>()))
          .where((record) => record.status == DropOffStatuses.pending)
          .toList(growable: false);
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (error) {
      throw PartnerValidationException(_messageFor(
        error,
        fallback: 'Unable to load pending validations.',
      ));
    }
  }

  @override
  Future<void> validateDropOff(
    String id, {
    required String action,
    String? validationNotes,
  }) async {
    final dropOffId = id.trim();
    final normalizedAction = action.trim().toLowerCase();
    if (dropOffId.isEmpty ||
        !const {'approve', 'reject'}.contains(normalizedAction)) {
      throw const PartnerValidationException(
        'This drop-off cannot be validated right now.',
      );
    }

    final notes = validationNotes?.trim();
    try {
      await _apiClient.dio.patch(
        ApiEndpoints.validateBinDropoff(dropOffId),
        data: {
          'action': normalizedAction,
          if (notes != null && notes.isNotEmpty) 'validationNotes': notes,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
    } catch (error) {
      throw PartnerValidationException(_messageFor(
        error,
        fallback: 'Unable to validate this drop-off. Please try again.',
      ));
    }
  }

  List<dynamic> _items(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final value = map['dropoffs'] ??
          map['dropOffs'] ??
          map['data'] ??
          map['items'] ??
          map['results'];
      if (value is List) return value;
    }
    return const [];
  }

  String _messageFor(Object error, {required String fallback}) {
    if (error is PartnerValidationException) return error.message;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) return 'Your session has expired. Sign in again.';
      if (statusCode == 403) {
        return 'You do not have access to validate this drop-off.';
      }
      if (statusCode == 404) {
        return 'This drop-off is no longer available for validation.';
      }
      if (statusCode == 409) {
        return 'This drop-off has already been validated.';
      }
    }
    return fallback;
  }
}

class PartnerValidationException implements Exception {
  const PartnerValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
