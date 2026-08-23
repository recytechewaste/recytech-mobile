import '../models/public_bin_model.dart';

abstract class PublicBinRepository {
  Future<List<PublicBin>> fetchPublicBins();
}

/// Temporary public-bin source.
///
/// Backend contract still needed:
/// GET /api/public/bins -> [{ id, publicQrCode, name, building?, locationDescription?, address, publicStatus?, latitude?, longitude? }]
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
        publicStatus: 'Temporarily unavailable',
        isActive: false,
      ),
    ];
  }
}
