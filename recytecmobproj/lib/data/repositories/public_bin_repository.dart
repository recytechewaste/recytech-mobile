import '../models/public_bin_model.dart';

abstract class PublicBinRepository {
  Future<List<PublicBin>> fetchPublicBins();
}

/// Temporary public-bin source.
///
/// Backend contract still needed:
/// GET /api/public/bins -> [{ id, name, address, publicStatus?, latitude?, longitude? }]
class MockPublicBinRepository implements PublicBinRepository {
  @override
  Future<List<PublicBin>> fetchPublicBins() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [
      PublicBin(
        id: 'PUB-BIN-001',
        name: 'Municipal Hall Drop-Off',
        address: 'Municipal Hall East Entrance',
        publicStatus: 'Open',
        latitude: 14.5995,
        longitude: 120.9842,
      ),
      PublicBin(
        id: 'PUB-BIN-002',
        name: 'Public Market E-Waste Bin',
        address: 'Public Market Gate 2',
        publicStatus: 'Available',
      ),
      PublicBin(
        id: 'PUB-BIN-003',
        name: 'City Library Collection Point',
        address: 'City Library South Wing',
        publicStatus: 'Limited capacity',
      ),
    ];
  }
}
