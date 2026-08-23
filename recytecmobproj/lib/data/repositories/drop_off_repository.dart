import '../models/bin_qr_payload_model.dart';
import '../models/drop_off_record_model.dart';
import '../models/public_bin_model.dart';
import '../models/reward_transaction_model.dart';
import 'public_bin_repository.dart';

abstract class DropOffRepository {
  Future<PublicBin> validateBinQr(BinQrPayload payload);

  Future<DropOffRecord> registerDropOff({
    required BinQrPayload payload,
  });

  Future<List<DropOffRecord>> getMyDropOffHistory();

  Future<List<RewardTransaction>> getMyRewards();
}

class DropOffRepositoryException implements Exception {
  const DropOffRepositoryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Mock/dev implementation for the Phase 5 household QR flow.
///
/// Backend contract still needed. Mobile must not be the source of truth for
/// eligibility, duplicate prevention, timestamps, or reward amounts.
class MockDropOffRepository implements DropOffRepository {
  MockDropOffRepository({
    PublicBinRepository? publicBinRepository,
  }) : _publicBinRepository =
            publicBinRepository ?? MockPublicBinRepository();

  final PublicBinRepository _publicBinRepository;

  static final List<DropOffRecord> _records = [
    DropOffRecord(
      id: 'DROP-DEMO-001',
      binId: 'PUB-BIN-001',
      binName: 'RecyTech Bin A',
      building: 'ABC Residences',
      locationDescription: '3rd Floor recycling area',
      createdAt: DateTime(2026, 8, 12, 9, 30),
      status: 'Recorded',
      rewardEligible: true,
      rewardPoints: 10,
      rewardStatus: 'Credited',
    ),
    DropOffRecord(
      id: 'DROP-DEMO-002',
      binId: 'PUB-BIN-002',
      binName: 'Public Market E-Waste Bin',
      building: 'Public Market',
      locationDescription: 'Gate 2 entrance',
      createdAt: DateTime(2026, 8, 13, 16, 10),
      status: 'Recorded',
      rewardEligible: false,
      rewardStatus: 'Not eligible',
    ),
  ];

  @override
  Future<PublicBin> validateBinQr(BinQrPayload payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final bin = await _findBin(payload.publicBinCode);
    if (bin == null) {
      throw const DropOffRepositoryException(
        'unknown_bin',
        'Bin Unavailable. This QR is not linked to an active RecyTech bin.',
      );
    }

    if (!bin.isActive) {
      throw const DropOffRepositoryException(
        'inactive_bin',
        'Bin Unavailable. This designated bin is temporarily unavailable.',
      );
    }

    return bin;
  }

  @override
  Future<DropOffRecord> registerDropOff({
    required BinQrPayload payload,
  }) async {
    final bin = await validateBinQr(payload);
    await Future<void>.delayed(const Duration(milliseconds: 320));

    if (payload.publicBinCode == 'MARKET-GATE2') {
      throw const DropOffRepositoryException(
        'duplicate_drop_off',
        'Drop-off already recorded. Reward is not available for this check-in.',
      );
    }

    final record = DropOffRecord(
      id: 'DROP-${DateTime.now().millisecondsSinceEpoch}',
      binId: bin.id,
      binName: bin.name,
      building: bin.building,
      locationDescription: bin.locationDescription,
      createdAt: DateTime.now(),
      status: 'Recorded',
      rewardEligible: true,
      rewardPoints: 10,
      rewardStatus: 'Credited',
    );
    _records.insert(0, record);
    return record;
  }

  @override
  Future<List<DropOffRecord>> getMyDropOffHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final records = List<DropOffRecord>.of(_records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<DropOffRecord>.unmodifiable(records);
  }

  @override
  Future<List<RewardTransaction>> getMyRewards() async {
    final records = await getMyDropOffHistory();
    return records
        .where((record) => record.rewardEligible)
        .map(
          (record) => RewardTransaction(
            id: 'REWARD-${record.id}',
            dropOffId: record.id,
            createdAt: record.createdAt,
            status: record.rewardStatus ?? 'Credited',
            rewardValue: record.rewardValue,
            rewardPoints: record.rewardPoints,
            binName: record.binName,
            locationDescription: record.locationLabel,
          ),
        )
        .toList();
  }

  Future<PublicBin?> _findBin(String publicBinCode) async {
    final bins = await _publicBinRepository.fetchPublicBins();
    for (final bin in bins) {
      if (bin.publicQrCode == publicBinCode) return bin;
    }
    return null;
  }
}
