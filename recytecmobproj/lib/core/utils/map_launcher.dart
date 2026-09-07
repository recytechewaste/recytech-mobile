import 'package:url_launcher/url_launcher.dart';

class MapLaunchTarget {
  const MapLaunchTarget({
    this.label,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String? label;
  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  bool get hasAddress => (address ?? '').trim().isNotEmpty;
  bool get canOpen => hasCoordinates || hasAddress;
}

class MapLauncher {
  const MapLauncher();

  Uri? openStreetMapUri(MapLaunchTarget target, {bool directions = true}) {
    if (!target.canOpen) return null;

    if (target.hasCoordinates) {
      final marker = '${target.latitude},${target.longitude}';
      final params = <String, String>{
        'mlat': target.latitude.toString(),
        'mlon': target.longitude.toString(),
        'zoom': '17',
      };

      if (directions) {
        params['to'] = marker;
      }

      return Uri.https('www.openstreetmap.org', '/directions', params);
    }

    return Uri.https('www.openstreetmap.org', '/search', {
      'query': target.address!.trim(),
    });
  }

  Uri? googleMapsUri(MapLaunchTarget target, {bool directions = true}) {
    return openStreetMapUri(target, directions: directions);
  }

  Future<bool> open(MapLaunchTarget target, {bool directions = true}) async {
    final uri = openStreetMapUri(target, directions: directions);
    if (uri == null) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
