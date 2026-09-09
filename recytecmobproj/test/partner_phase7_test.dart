import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/partner_organization_model.dart';
import 'package:recytecmobproj/data/repositories/bin_monitoring_repository.dart';
import 'package:recytecmobproj/data/repositories/partner_organization_repository.dart';

void main() {
  group('Phase 7 Partner endpoints', () {
    test('uses authoritative profile, bins, status, and stats paths', () {
      expect(ApiEndpoints.partnerOrganizationMe, '/partner-organizations/me');
      expect(ApiEndpoints.partnerOrganizationBins,
          '/partner-organizations/my-bins');
      expect(ApiEndpoints.partnerOrganizationBinStatus('mongo-bin-1'),
          '/partner-organizations/bins/mongo-bin-1/status');
      expect(ApiEndpoints.partnerOrganizationStats,
          '/partner-organizations/stats');
      expect(ApiEndpoints.requests, '/requests');
    });

    test('profile and stats use backend responses and preserve identities',
        () async {
      final requests = <RequestOptions>[];
      final client = ApiClient(dio: _recordingDio(requests));
      final repository = PartnerOrganizationRepository(apiClient: client);

      final profile = await repository.fetchProfile();
      final stats = await repository.fetchStats();

      expect(requests.map((request) => request.path), [
        '/partner-organizations/me',
        '/partner-organizations/stats',
      ]);
      expect(profile.profileId, 'partner-profile-1');
      expect(profile.userId, 'user-1');
      expect(profile.organizationName, 'Green Municipality');
      expect(profile.contactPerson, 'Ana Reyes');
      expect(profile.contactNumber, '09170000000');
      expect(profile.email, 'partner@recytech.com');
      expect(profile.overview['assignedBins'], 2);
      expect(stats.values['validatedDropOffs'], 12);
      expect(stats.values['pointsAwarded'], 420);
    });

    test('partner organization name accepts the production name field', () {
      final profile = PartnerOrganizationProfile.fromJson({
        'profile': {
          '_id': 'partner-profile-1',
          'name': 'Actual Organization Name',
        },
        'user': {
          '_id': 'user-1',
          'email': 'partner@recytech.com',
        },
      });

      expect(profile.organizationName, 'Actual Organization Name');
    });

    test('partner role label does not outrank a real account name', () {
      final profile = PartnerOrganizationProfile.fromJson({
        'profile': {
          '_id': 'partner-profile-1',
          'organizationName': 'Partner Organization',
        },
        'user': {
          '_id': 'user-1',
          'accountName': 'Actual Organization Name',
          'email': 'partner@recytech.com',
        },
      });

      expect(profile.organizationName, 'Actual Organization Name');
    });

    test('my-bins response is already scoped and is not identity-filtered',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiPartnerBinRepository(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      final bins = await repository.fetchAssignedBins();

      expect(bins, hasLength(1));
      expect(requests.single.path, '/partner-organizations/my-bins');
      expect(requests.single.queryParameters, isEmpty);
      expect(requests.single.data, isNull);
    });
  });

  group('Phase 7 bin contract', () {
    test('parses shared bin fields and GeoJSON longitude then latitude', () {
      final bin = RecyTechBin.fromJson(_binJson());
      expect(bin.binId, 'mongo-bin-1');
      expect(bin.displayName, 'Plaza E-Waste Bin');
      expect(bin.location, 'Town Plaza');
      expect(bin.publicQrCode, 'QR-001');
      expect(bin.databaseId, 'mongo-bin-1');
      expect(bin.requestBinId, 'mongo-bin-1');
      expect(bin.apiStatus, 'Operational');
      expect(bin.fillPercentage, 75);
      expect(bin.fillLevelKg, 360);
      expect(bin.notes, 'Weekly inspection complete.');
      expect(bin.longitude, 121.0244);
      expect(bin.latitude, 14.5547);
      expect(bin.assignedLguId, 'partner-profile-1');
      expect(bin.partnerOrganizationName, 'Green Municipality');
      expect(bin.lastUpdatedAt, DateTime.parse('2026-09-08T08:00:00Z'));
    });

    test('submits all five exact statuses using PATCH and Mongo _id', () async {
      final requests = <RequestOptions>[];
      final repository = ApiPartnerBinRepository(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      for (final status in PartnerBinStatuses.values) {
        await repository.updateBinStatus(
          binId: 'mongo-bin-1',
          status: status,
          fillLevelKg: 480,
          notes: 'Needs collection.',
        );
      }

      expect(PartnerBinStatuses.values,
          ['Empty', 'Operational', 'Full', 'Maintenance', 'Active']);
      expect(requests, hasLength(5));
      for (var index = 0; index < requests.length; index++) {
        final request = requests[index];
        expect(request.method, 'PATCH');
        expect(request.path, '/partner-organizations/bins/mongo-bin-1/status');
        expect(request.data, {
          'status': PartnerBinStatuses.values[index],
          'fillLevelKg': 480.0,
          'notes': 'Needs collection.',
        });
        expect(request.data, isNot(contains('partnerOrganizationId')));
        expect(request.data, isNot(contains('userId')));
        expect(request.data, isNot(contains('profileId')));
      }
    });

    test('rejects noncanonical status and invalid fill before networking',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiPartnerBinRepository(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      await expectLater(
        repository.updateBinStatus(binId: 'mongo-bin-1', status: 'full'),
        throwsArgumentError,
      );
      await expectLater(
        repository.updateBinStatus(
          binId: 'mongo-bin-1',
          status: 'Full',
          fillLevelKg: -1,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.updateBinStatus(
          binId: 'mongo-bin-1',
          status: 'Full',
          fillLevelKg: double.infinity,
        ),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    });

    test('bin detail refetch stays on backend-scoped my-bins route', () async {
      final requests = <RequestOptions>[];
      final repository = ApiPartnerBinRepository(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      expect((await repository.fetchBin('mongo-bin-1')).binId, 'mongo-bin-1');
      expect(requests.single.path, '/partner-organizations/my-bins');
      expect(
          requests.any((request) => request.path == '/partner/bins'), isFalse);
    });
  });
}

Map<String, dynamic> _profileJson() => {
      'profile': {
        '_id': 'partner-profile-1',
        'organizationName': 'Green Municipality',
        'contactPerson': 'Ana Reyes',
        'contactNumber': '09170000000',
      },
      'user': {'_id': 'user-1', 'email': 'partner@recytech.com'},
      'overview': {'assignedBins': 2},
    };

Map<String, dynamic> _binJson() => {
      '_id': 'mongo-bin-1',
      'name': 'Plaza E-Waste Bin',
      'address': 'Town Plaza',
      'qrCode': 'QR-001',
      'status': 'Operational',
      'fillLevel': 75,
      'fillLevelKg': 360,
      'notes': 'Weekly inspection complete.',
      'location': {
        'address': 'Town Plaza',
        'coordinates': [121.0244, 14.5547],
      },
      'assignedLgu': {
        '_id': 'partner-profile-1',
        'organizationName': 'Green Municipality',
      },
      'updatedAt': '2026-09-08T08:00:00Z',
    };

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(headers: const {'Authorization': 'Bearer test'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    dynamic data = <String, dynamic>{};
    if (options.path == '/partner-organizations/me') data = _profileJson();
    if (options.path == '/partner-organizations/stats') {
      data = {'validatedDropOffs': 12, 'pointsAwarded': 420};
    }
    if (options.path == '/partner-organizations/my-bins') {
      data = {
        'bins': [_binJson()]
      };
    }
    if (options.path.endsWith('/status')) {
      data = {
        'bin': {..._binJson(), ...options.data as Map}
      };
    }
    handler.resolve(Response(requestOptions: options, data: data));
  }));
  return dio;
}
