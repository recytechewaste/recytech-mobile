import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exceptions.dart';
import '../models/sensor_incident_model.dart';

abstract class SensorIncidentRepository {
  Future<SensorIncidentSubmissionResult> createIncident({
    required String binId,
    required String issueDescription,
    String severity = SensorIncidentSeverities.medium,
  });

  Future<List<SensorIncident>> fetchMyIncidents();
}

class SensorIncidentRepositoryException implements Exception {
  const SensorIncidentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiSensorIncidentRepository implements SensorIncidentRepository {
  ApiSensorIncidentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const sensorType = 'Time-of-Flight (ToF) Fullness Sensor';

  final ApiClient _apiClient;

  @override
  Future<SensorIncidentSubmissionResult> createIncident({
    required String binId,
    required String issueDescription,
    String severity = SensorIncidentSeverities.medium,
  }) async {
    final id = binId.trim();
    final description = issueDescription.trim();
    if (id.isEmpty) {
      throw const SensorIncidentRepositoryException(
        'The selected bin is unavailable.',
      );
    }
    if (description.isEmpty) {
      throw const SensorIncidentRepositoryException(
        'Issue description is required.',
      );
    }
    if (!SensorIncidentSeverities.isValid(severity)) {
      throw ArgumentError.value(severity, 'severity', 'Unsupported severity');
    }

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sensorReports,
        data: {
          'binId': id,
          'issueDescription': description,
          'severity': severity,
          'sensorType': sensorType,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      final envelope = _map(response.data);
      final data = _map(envelope['data']);
      if (data.isEmpty) {
        throw const SensorIncidentRepositoryException(
          'The incident response was incomplete.',
        );
      }
      return SensorIncidentSubmissionResult(
        success: envelope['success'] == true,
        message: _safeMessage(envelope['message']) ??
            'Sensor issue reported successfully.',
        incident: SensorIncident.fromJson(data),
      );
    } catch (error) {
      throw _mapError(error, 'Unable to report this sensor issue.');
    }
  }

  @override
  Future<List<SensorIncident>> fetchMyIncidents() async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.sensorReportsMyReports);
      final payload = response.data;
      final items = payload is List
          ? payload
          : payload is Map && payload['data'] is List
              ? payload['data'] as List
              : const <dynamic>[];
      return items
          .whereType<Map>()
          .map((item) => SensorIncident.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, 'Unable to load sensor incident history.');
    }
  }

  SensorIncidentRepositoryException _mapError(
    Object error,
    String fallback,
  ) {
    if (error is SensorIncidentRepositoryException) return error;
    if (error is DioException) {
      final message = error.response?.data is Map
          ? _safeMessage((error.response?.data as Map)['message'])
          : null;
      if (message != null) return SensorIncidentRepositoryException(message);
      final apiError = error.error;
      if (apiError is ApiException) {
        return SensorIncidentRepositoryException(apiError.message);
      }
      return SensorIncidentRepositoryException(
          switch (error.response?.statusCode) {
        400 => 'Please check the incident information and try again.',
        401 => 'Your session has expired. Please sign in again.',
        403 => 'Your account is not permitted to report this incident.',
        404 => 'The selected bin could not be found.',
        _ => fallback,
      });
    }
    if (error is FormatException) {
      return SensorIncidentRepositoryException(fallback);
    }
    return SensorIncidentRepositoryException(fallback);
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  String? _safeMessage(dynamic value) {
    final message = (value ?? '').toString().trim();
    final lowered = message.toLowerCase();
    if (message.isEmpty ||
        message.length > 180 ||
        lowered.contains('<html') ||
        lowered.contains('mongodb') ||
        lowered.contains('dioexception') ||
        lowered.contains('/sensor-reports') ||
        lowered.contains('jwt')) {
      return null;
    }
    return message;
  }
}
