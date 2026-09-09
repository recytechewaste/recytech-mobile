import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/public_bin_model.dart';

abstract class PublicBinRepository {
  Future<List<PublicBin>> fetchPublicBins();
}

class ApiPublicBinRepository implements PublicBinRepository {
  ApiPublicBinRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<PublicBin>> fetchPublicBins() async {
    final response = await _apiClient.dio.get(ApiEndpoints.binLocations);
    final items = _extractItems(response.data);
    return items
        .whereType<Map>()
        .map((item) => PublicBin.fromJson(item.cast<String, dynamic>()))
        .where((bin) => bin.isActive)
        .toList(growable: false);
  }

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final items =
          map['bins'] ?? map['data'] ?? map['items'] ?? map['results'];
      if (items is List) return items;
    }
    return const [];
  }
}

/// Development public-bin source used by QR/drop-off tests.
class MockPublicBinRepository implements PublicBinRepository {
  @override
  Future<List<PublicBin>> fetchPublicBins() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [
      PublicBin(
        id: 'PUB-BIN-001',
        publicQrCode: 'CONDO-3F-A',
        name: 'RecyTech Bin A',
        building: 'ABC Residences',
        locationDescription: '3rd Floor recycling area',
        address: 'ABC Residences, Tower 1',
        accessInfo: 'Open to residents daily, 8:00 AM - 8:00 PM',
        partnerOrganizationName: 'Demo Partner Organization A',
        acceptedCategories: [
          'laptop',
          'smartphone',
          'keyboard',
          'mouse',
          'battery',
          'pcb'
        ],
        acceptedCategoryLabels: [
          'Laptop',
          'Smartphone',
          'Keyboard',
          'Mouse',
          'Battery',
          'PCB'
        ],
        publicStatus: 'Open',
        latitude: 14.5995,
        longitude: 120.9842,
      ),
      PublicBin(
        id: 'PUB-BIN-002',
        publicQrCode: 'MARKET-GATE2',
        name: 'Public Market E-Waste Bin',
        building: 'Public Market',
        locationDescription: 'Gate 2 entrance',
        address: 'Public Market Gate 2',
        accessInfo: 'Accessible during market operating hours',
        partnerOrganizationName: 'Demo Partner Organization A',
        acceptedCategories: [
          'smartphone',
          'keyboard',
          'mouse',
          'battery',
          'pcb'
        ],
        acceptedCategoryLabels: [
          'Smartphone',
          'Keyboard',
          'Mouse',
          'Battery',
          'PCB'
        ],
        publicStatus: 'Available',
      ),
      PublicBin(
        id: 'PUB-BIN-003',
        publicQrCode: 'LIB-SOUTH',
        name: 'City Library Collection Point',
        building: 'City Library',
        locationDescription: 'South Wing lobby',
        address: 'City Library South Wing',
        accessInfo: 'Ask front desk for access when lobby is busy',
        partnerOrganizationName: 'Demo Partner Organization B',
        acceptedCategories: [
          'smartphone',
          'keyboard',
          'mouse',
          'battery',
          'pcb',
          'printer'
        ],
        acceptedCategoryLabels: [
          'Smartphone',
          'Keyboard',
          'Mouse',
          'Battery',
          'PCB',
          'Printer'
        ],
        publicStatus: 'Temporarily unavailable',
        isActive: false,
      ),
    ];
  }
}
