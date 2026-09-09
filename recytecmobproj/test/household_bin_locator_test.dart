import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/data/models/public_bin_model.dart';
import 'package:recytecmobproj/data/repositories/public_bin_repository.dart';
import 'package:recytecmobproj/presentation/user/bins/bin_locator_screen.dart';
import 'package:recytecmobproj/services/location_service.dart';

void main() {
  test('geographic distance uses real coordinates and formats units', () {
    final meters = geographicDistanceMeters(0, 0, 0, 0.001);

    expect(meters, closeTo(111.2, 0.5));
    expect(formatDistance(meters), '111 m away');
    expect(formatDistance(1800), '1.8 km away');
  });

  test('orders bins nearest-first and puts missing coordinates last', () {
    final bins = [
      _bin(id: 'far', code: 'FAR', name: 'Far Bin', longitude: 0.02),
      _bin(id: 'missing', code: 'NONE', name: 'Missing Coordinates'),
      _bin(id: 'near', code: 'NEAR', name: 'Near Bin', longitude: 0.001),
    ];
    final data = BinLocatorData.from(
      bins: bins,
      location: const DeviceLocationResult.available(
        DeviceCoordinates(latitude: 0, longitude: 0),
      ),
    );

    expect(
        data.entries.map((entry) => entry.bin.id), ['near', 'far', 'missing']);
    expect(data.entries.first.distanceMeters, closeTo(111.2, 0.5));
    expect(data.entries.last.distanceMeters, isNull);
  });

  testWidgets('manual refresh reloads bins and recalculates distance order',
      (tester) async {
    final repository = _FakePublicBinRepository([
      _bin(id: 'west', code: 'WEST', name: 'West Bin', longitude: 0),
      _bin(id: 'east', code: 'EAST', name: 'East Bin', longitude: 0.02),
    ]);
    final locationService = _FakeLocationService([
      const DeviceLocationResult.available(
        DeviceCoordinates(latitude: 0, longitude: 0),
      ),
      const DeviceLocationResult.available(
        DeviceCoordinates(latitude: 0, longitude: 0.02),
      ),
    ]);

    await _pumpLocator(tester, repository, locationService);
    expect(find.text('Code: WEST'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh locations'));
    await tester.pump();
    await tester.pump();

    expect(repository.fetchCount, 2);
    expect(locationService.requestCount, 2);
    expect(find.text('Code: EAST'), findsOneWidget);
  });

  testWidgets('shows a safe state when location permission is denied',
      (tester) async {
    final repository = _FakePublicBinRepository([
      _bin(id: 'one', code: 'ONE', name: 'Public Bin', longitude: 0.001),
    ]);
    final locationService = _FakeLocationService([
      const DeviceLocationResult.unavailable(
        LocationAvailability.permissionDenied,
      ),
    ]);

    await _pumpLocator(tester, repository, locationService);

    expect(find.text('Location permission denied'), findsOneWidget);
    expect(find.text('Public bins'), findsOneWidget);
    expect(find.textContaining('away'), findsNothing);
  });

  test('public bin parses optional fullness values from the API response', () {
    final bin = PublicBin.fromJson({
      'id': 'BIN-1',
      'publicQrCode': 'BIN-1',
      'name': 'Sensor Bin',
      'address': 'Main Lobby',
      'status': 'active',
      'fillPercentage': 82,
      'fullnessStatus': 'nearly_full',
    });

    expect(bin.fillPercentage, 82);
    expect(bin.fullnessStatus, 'nearly_full');
  });

  test('confirmed public sample remains available without Partner assignment',
      () {
    final bin = PublicBin.fromJson({
      '_id': '68c0-public-bin',
      'binId': 'NU-TRASH-ORG',
      'name': 'NU Trash Org',
      'address': 'National University',
      'latitude': '14.604666894622119',
      'longitude': '120.99423448609102',
      'status': 'Empty',
      'isAvailableForDropoff': true,
      'capacityKg': 100,
      'currentFillKg': 0,
      'qrCode': 'NU-TRASH-QR',
    });

    expect(bin.name, 'NU Trash Org');
    expect(bin.partnerOrganizationName, isNull);
    expect(bin.displayCode, 'NU-TRASH-ORG');
    expect(bin.latitude, 14.604666894622119);
    expect(bin.longitude, 120.99423448609102);
    expect(bin.publicStatus, 'Empty');
    expect(bin.isAvailableForDropoff, isTrue);
    expect(bin.isActive, isTrue);
    expect(bin.availabilityLabel, 'Available for drop-off');
    expect(bin.fillPercentage, 0);
  });

  test('internal notes and incident descriptions never become location text',
      () {
    final bin = PublicBin.fromJson({
      '_id': '68c0-public-bin',
      'binId': 'NU-TRASH-ORG',
      'name': 'NU Trash Org',
      'address': 'Pinned at 14.6047, 120.9942',
      'description': 'naapaw na',
      'notes': 'internal maintenance note',
      'issueDescription': 'naapaw na',
      'location': {
        'coordinates': [120.99423448609102, 14.604666894622119],
        'description': 'private location note',
      },
      'status': 'Empty',
      'isAvailableForDropoff': true,
    });

    expect(bin.locationDescription, isNull);
    expect(bin.locationLabel, 'Pinned at 14.6047, 120.9942');
    expect(bin.locationLabel, isNot(contains('naapaw na')));
    expect(bin.locationLabel, isNot(contains('internal maintenance note')));
    expect(bin.locationLabel, isNot(contains('private location note')));
  });

  testWidgets('Household card never renders generic internal bin text',
      (tester) async {
    final contaminated = PublicBin.fromJson({
      '_id': '68c0-public-bin',
      'binId': 'NU-TRASH-ORG',
      'name': 'NU Trash Org',
      'address': 'Pinned at 14.6047, 120.9942',
      'description': 'naapaw na',
      'notes': 'internal maintenance note',
      'latitude': 14.604666894622119,
      'longitude': 120.99423448609102,
      'status': 'Empty',
      'isAvailableForDropoff': true,
    });
    final repository = _FakePublicBinRepository([contaminated]);
    final locationService = _FakeLocationService([
      const DeviceLocationResult.available(
        DeviceCoordinates(
          latitude: 14.604666894622119,
          longitude: 120.99423448609102,
        ),
      ),
    ]);

    await _pumpLocator(tester, repository, locationService);

    expect(find.text('NU Trash Org'), findsWidgets);
    expect(find.text('Pinned at 14.6047, 120.9942'), findsWidgets);
    expect(find.textContaining('naapaw na'), findsNothing);
    expect(find.textContaining('internal maintenance note'), findsNothing);
  });

  testWidgets('bin detail scrolls without overflow at emulator and short sizes',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bin = PublicBin.fromJson({
      '_id': '68c0-public-bin',
      'binId': 'NU-TRASH-ORG',
      'name': 'NU Trash Org',
      'address': 'Pinned at 14.6047, 120.9942',
      'description': 'naapaw na',
      'notes': 'internal maintenance note',
      'latitude': 14.604666894622119,
      'longitude': 120.99423448609102,
      'status': 'Empty',
      'isAvailableForDropoff': true,
      'capacityKg': 500,
      'currentFillKg': 125,
      'fullnessStatus': 'partially_filled',
      'assignedLgu': {'name': 'NU Partner Organization'},
      'building': 'Main Campus Building',
      'locationDescription': 'Ground-floor public drop-off point',
      'accessInfo': 'Open during campus operating hours.',
      'acceptedCategories': ['mobile_phones', 'laptops', 'batteries'],
      'rewards': [
        {
          '_id': 'reward-1',
          'title': 'Recycling Reward',
          'pointsCost': 100,
        },
      ],
    });
    final repository = _FakePublicBinRepository([bin]);
    final locationService = _FakeLocationService([
      const DeviceLocationResult.available(
        DeviceCoordinates(
          latitude: 14.604666894622119,
          longitude: 120.99423448609102,
        ),
      ),
    ]);

    await _pumpLocator(tester, repository, locationService);
    await tester.tap(find.text('Code: NU-TRASH-ORG'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    final scrollView = find.descendant(
      of: sheet,
      matching: find.byType(SingleChildScrollView),
    );
    expect(sheet, findsOneWidget);
    expect(scrollView, findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('naapaw na'), findsNothing);
    expect(find.textContaining('internal maintenance note'), findsNothing);
    expect(find.text('Pinned at 14.6047, 120.9942'), findsWidgets);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(375, 520);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Submit Drop-Off'));
    await tester.pumpAndSettle();
    expect(find.text('Submit Drop-Off').hitTestable(), findsOneWidget);

    await tester.ensureVisible(find.text('Scan Bin QR'));
    await tester.pumpAndSettle();
    expect(find.text('Scan Bin QR').hitTestable(), findsOneWidget);
    expect(find.text('View location on map').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('coordinate parsing follows direct, short, then GeoJSON priority', () {
    final direct = PublicBin.fromJson({
      'binId': 'DIRECT',
      'latitude': 14.6,
      'longitude': 121.0,
      'lat': 1,
      'lng': 2,
      'location': {
        'coordinates': [3, 4],
      },
    });
    final short = PublicBin.fromJson({
      'binId': 'SHORT',
      'lat': 14.7,
      'lng': 121.1,
      'location': {
        'coordinates': [3, 4],
      },
    });
    final geoJson = PublicBin.fromJson({
      'binId': 'GEO',
      'location': {
        'coordinates': [120.99423448609102, 14.604666894622119],
      },
    });

    expect((direct.latitude, direct.longitude), (14.6, 121.0));
    expect((short.latitude, short.longitude), (14.7, 121.1));
    expect(
      (geoJson.latitude, geoJson.longitude),
      (14.604666894622119, 120.99423448609102),
    );
  });

  test('drop-off availability overrides status and Empty is otherwise valid',
      () {
    final empty = PublicBin.fromJson({
      'binId': 'EMPTY',
      'status': 'Empty',
    });
    final explicitlyUnavailable = PublicBin.fromJson({
      'binId': 'UNAVAILABLE',
      'status': 'Operational',
      'isAvailableForDropoff': false,
    });

    expect(empty.isActive, isTrue);
    expect(empty.availabilityLabel, 'Available for drop-off');
    expect(explicitlyUnavailable.isActive, isFalse);
    expect(
      explicitlyUnavailable.availabilityLabel,
      'Unavailable for drop-off',
    );
  });
}

Future<void> _pumpLocator(
  WidgetTester tester,
  PublicBinRepository repository,
  LocationService locationService,
) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: BinLocatorScreen(
          repository: repository,
          locationService: locationService,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

PublicBin _bin({
  required String id,
  required String code,
  required String name,
  double? longitude,
}) {
  return PublicBin(
    id: id,
    name: name,
    address: '$name address',
    publicQrCode: code,
    latitude: longitude == null ? null : 0,
    longitude: longitude,
    publicStatus: 'Open',
  );
}

class _FakePublicBinRepository implements PublicBinRepository {
  _FakePublicBinRepository(this.bins);

  final List<PublicBin> bins;
  int fetchCount = 0;

  @override
  Future<List<PublicBin>> fetchPublicBins() async {
    fetchCount++;
    return bins;
  }
}

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.results);

  final List<DeviceLocationResult> results;
  int requestCount = 0;

  @override
  Future<DeviceLocationResult> getCurrentLocation() async {
    final index = requestCount.clamp(0, results.length - 1);
    requestCount++;
    return results[index];
  }
}
