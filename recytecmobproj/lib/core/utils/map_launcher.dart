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

  Uri? googleMapsUri(MapLaunchTarget target, {bool directions = true}) {
    if (!target.canOpen) return null;

    final query = target.hasCoordinates
        ? '${target.latitude},${target.longitude}'
        : target.address!.trim();

    return Uri.https(
      'www.google.com',
      directions ? '/maps/dir/' : '/maps/search/',
      {
        'api': '1',
        if (directions) 'destination': query else 'query': query,
      },
    );
  }

  Future<bool> open(MapLaunchTarget target, {bool directions = true}) async {
    final uri = googleMapsUri(target, directions: directions);
    if (uri == null) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
