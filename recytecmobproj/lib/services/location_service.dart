import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

enum LocationAvailability {
  available,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class DeviceCoordinates {
  const DeviceCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class DeviceLocationResult {
  const DeviceLocationResult._(this.availability, this.coordinates);

  const DeviceLocationResult.available(DeviceCoordinates coordinates)
      : this._(LocationAvailability.available, coordinates);

  const DeviceLocationResult.unavailable(this.availability)
      : assert(availability != LocationAvailability.available),
        coordinates = null;

  final LocationAvailability availability;
  final DeviceCoordinates? coordinates;
}

class LocationService {
  const LocationService();

  Future<DeviceLocationResult> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const DeviceLocationResult.unavailable(
          LocationAvailability.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const DeviceLocationResult.unavailable(
          LocationAvailability.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocationResult.unavailable(
          LocationAvailability.permissionDeniedForever,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeviceLocationResult.available(
        DeviceCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      return const DeviceLocationResult.unavailable(
        LocationAvailability.unavailable,
      );
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }
}

double geographicDistanceMeters(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const earthRadiusMeters = 6371000.0;
  final latitudeDelta = _toRadians(endLatitude - startLatitude);
  final longitudeDelta = _toRadians(endLongitude - startLongitude);
  final startLatitudeRadians = _toRadians(startLatitude);
  final endLatitudeRadians = _toRadians(endLatitude);

  final haversine = (math.pow(math.sin(latitudeDelta / 2), 2) +
          math.cos(startLatitudeRadians) *
              math.cos(endLatitudeRadians) *
              math.pow(math.sin(longitudeDelta / 2), 2))
      .clamp(0.0, 1.0)
      .toDouble();
  final angularDistance =
      2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  return earthRadiusMeters * angularDistance;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
