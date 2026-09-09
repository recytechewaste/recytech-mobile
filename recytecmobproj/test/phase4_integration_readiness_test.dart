import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/config/env.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';

void main() {
  group('API configuration', () {
    test('keeps the API base URL centralized', () {
      expect(Env.baseUrl, isNotEmpty);
      expect(Env.baseUrl, contains('/api'));
    });
  });

  group('map launcher validation', () {
    test('rejects malformed coordinate ranges without an address fallback', () {
      const launcher = MapLauncher();

      expect(
        launcher.googleMapsUri(
          const MapLaunchTarget(latitude: 91, longitude: 121),
        ),
        isNull,
      );
      expect(
        launcher.googleMapsUri(
          const MapLaunchTarget(latitude: 14, longitude: 181),
        ),
        isNull,
      );
    });

    test('uses address fallback when coordinates are unavailable', () {
      const launcher = MapLauncher();
      final uri = launcher.googleMapsUri(
        const MapLaunchTarget(address: 'Municipal Hall'),
      );

      expect(uri, isNotNull);
      expect(uri.toString(), contains('Municipal+Hall'));
    });
  });

  group('ToF reading model readiness', () {
    test('labels stale and unknown readings without creating fake values', () {
      final now = DateTime(2026, 8, 13, 12);

      expect(
        SensorReadingFreshness.status(
          DateTime(2026, 8, 13, 11),
          now: now,
        ),
        'Current',
      );
      expect(
        SensorReadingFreshness.status(
          DateTime(2026, 8, 13, 8),
          now: now,
        ),
        'Stale',
      );
      expect(SensorReadingFreshness.status(null, now: now), 'Unknown');
    });

    test('parses missing sensor fields safely', () {
      final bin = RecyTechBin.fromJson({
        'binId': 'BIN-1',
        'location': 'Municipal Hall',
      });

      expect(bin.binId, 'BIN-1');
      expect(bin.location, 'Municipal Hall');
      expect(bin.distanceCm, isNull);
      expect(bin.fillPercentage, isNull);
      expect(bin.sensorStatus, 'unknown');
    });
  });
}
