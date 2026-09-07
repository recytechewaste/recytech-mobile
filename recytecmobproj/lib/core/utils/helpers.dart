import 'package:dio/dio.dart';

import '../network/api_exceptions.dart';

/// Returns a concise message suitable for UI surfaces without exposing
/// endpoints, transport exceptions, stack traces, or raw response payloads.
String userFacingError(
  Object error, {
  required String fallback,
}) {
  String? candidate;

  if (error is ApiException) {
    candidate = error.message;
  } else if (error is DioException && error.error is ApiException) {
    candidate = (error.error as ApiException).message;
  }

  final message = candidate?.trim();
  if (message == null || message.isEmpty || message.length > 180) {
    return fallback;
  }

  final lower = message.toLowerCase();
  const technicalMarkers = [
    'dioexception',
    'socketexception',
    'exception:',
    'stack trace',
    '/api/',
    'http://',
    'https://',
    '<html',
    'typeerror',
    'formatexception',
  ];
  if (technicalMarkers.any(lower.contains) ||
      RegExp(r'^(get|post|put|patch|delete)\s+/').hasMatch(lower)) {
    return fallback;
  }

  return message;
}
