import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exceptions.dart';
import '../models/bin_qr_payload_model.dart';
import '../models/drop_off_record_model.dart';
import '../models/public_bin_model.dart';
import '../models/reward_transaction_model.dart';
import 'public_bin_repository.dart';

abstract class DropOffRepository {
  Future<PublicBin> validateBinQr(BinQrPayload payload);

  Future<DropOffRecord> registerDropOff({
    BinQrPayload? payload,
    PublicBin? bin,
    required List<DropOffSubmissionItem> items,
    required String submissionMethod,
    String? idempotencyKey,
  });

  Future<List<DropOffRecord>> getMyDropOffHistory();

  Future<List<RewardTransaction>> getMyRewards();
}

class DropOffSubmissionItem {
  const DropOffSubmissionItem({
    required this.category,
    required this.quantity,
  });

  final String category;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'category': category,
        'quantity': quantity,
      };
}

class DropOffRepositoryException implements Exception {
  const DropOffRepositoryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class ApiDropOffRepository implements DropOffRepository {
  ApiDropOffRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<PublicBin> validateBinQr(BinQrPayload payload) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.validateBinQr,
        data: {'qrCode': payload.toQrValue()},
      );
      final data = _extractObject(response.data, preferredKey: 'bin');
      return PublicBin.fromJson(data);
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to validate this bin QR.');
    }
  }

  @override
  Future<DropOffRecord> registerDropOff({
    BinQrPayload? payload,
    PublicBin? bin,
    required List<DropOffSubmissionItem> items,
    required String submissionMethod,
    String? idempotencyKey,
  }) async {
    final selectedBin =
        bin ?? (payload == null ? null : await validateBinQr(payload));
    if (selectedBin == null) {
      throw const DropOffRepositoryException(
        'missing_bin',
        'Please select a RecyTech bin before submitting.',
      );
    }

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.householdDropOffs,
        data: {
          'binId': selectedBin.publicQrCode,
          'submissionMethod': submissionMethod,
          'items': items.map((item) => item.toJson()).toList(),
          if ((idempotencyKey ?? '').trim().isNotEmpty)
            'idempotencyKey': idempotencyKey!.trim(),
        },
      );
      final data = _extractObject(response.data, preferredKey: 'dropOff');
      return DropOffRecord.fromJson(data);
    } catch (error) {
      throw _mapError(error, fallback: 'Drop-off could not be submitted.');
    }
  }

  @override
  Future<List<DropOffRecord>> getMyDropOffHistory() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.householdDropOffs);
      final items = _extractItems(response.data, preferredKey: 'dropOffs');
      return items
          .whereType<Map>()
          .map((item) => DropOffRecord.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to load drop-off history.');
    }
  }

  @override
  Future<List<RewardTransaction>> getMyRewards() async {
    return const [];
  }

  Map<String, dynamic> _extractObject(
    dynamic payload, {
    required String preferredKey,
  }) {
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final nested = map[preferredKey] ?? map['data'];
      if (nested is Map) return nested.cast<String, dynamic>();
      return map;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractItems(dynamic payload, {required String preferredKey}) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final items = map[preferredKey] ?? map['items'] ?? map['results'];
      if (items is List) return items;
    }
    return const [];
  }

  DropOffRepositoryException _mapError(
    Object error, {
    required String fallback,
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final code = (data['code'] ?? 'request_failed').toString();
        final message = (data['message'] ?? '').toString().trim();
        if (message.isNotEmpty) {
          return DropOffRepositoryException(code, message);
        }
      }
      final exception = error.error;
      if (exception is ApiException) {
        return DropOffRepositoryException(
          exception.isUnauthorized ? 'unauthorized' : 'request_failed',
          exception.message,
        );
      }
    }
    return DropOffRepositoryException('request_failed', fallback);
  }
}

/// Mock/dev implementation for the Phase 5 household QR flow.
///
/// Backend contract still needed. Mobile must not be the source of truth for
/// eligibility, duplicate prevention, timestamps, or reward amounts.
class MockDropOffRepository implements DropOffRepository {
  MockDropOffRepository({
    PublicBinRepository? publicBinRepository,
  }) : _publicBinRepository = publicBinRepository ?? MockPublicBinRepository();

  final PublicBinRepository _publicBinRepository;

  static final List<DropOffRecord> _records = [
    DropOffRecord(
      id: 'DROP-DEMO-001',
      binId: 'PUB-BIN-001',
      binName: 'RecyTech Bin A',
      building: 'ABC Residences',
      locationDescription: '3rd Floor recycling area',
      createdAt: DateTime(2026, 8, 12, 9, 30),
      status: 'submitted',
      rewardStatus: 'credited',
      pointsStatus: 'credited',
      pointsAwarded: 20,
      submissionMethod: 'qr',
      items: const [
        DropOffRecordItem(category: 'smartphone', quantity: 1),
      ],
    ),
    DropOffRecord(
      id: 'DROP-DEMO-002',
      binId: 'PUB-BIN-002',
      binName: 'Public Market E-Waste Bin',
      building: 'Public Market',
      locationDescription: 'Gate 2 entrance',
      createdAt: DateTime(2026, 8, 13, 16, 10),
      status: 'submitted',
      rewardStatus: 'credited',
      pointsStatus: 'credited',
      pointsAwarded: 10,
      submissionMethod: 'manual',
      items: const [
        DropOffRecordItem(category: 'battery', quantity: 2),
      ],
    ),
  ];

  static final Map<String, DropOffRecord> _idempotentRecords = {};

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
    BinQrPayload? payload,
    PublicBin? bin,
    required List<DropOffSubmissionItem> items,
    required String submissionMethod,
    String? idempotencyKey,
  }) async {
    final selectedBin =
        bin ?? (payload == null ? null : await validateBinQr(payload));
    if (selectedBin == null) {
      throw const DropOffRepositoryException(
        'missing_bin',
        'Please select a RecyTech bin before submitting.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 320));

    if (items.isEmpty) {
      throw const DropOffRepositoryException(
        'missing_items',
        'Please add at least one e-waste item.',
      );
    }
    for (final item in items) {
      if (item.quantity <= 0) {
        throw const DropOffRepositoryException(
          'invalid_quantity',
          'Quantity must be a whole number greater than 0.',
        );
      }
      if (!selectedBin.acceptedCategories.contains(item.category)) {
        throw const DropOffRepositoryException(
          'category_not_accepted',
          'This e-waste category is not accepted by this bin.',
        );
      }
    }

    final key = idempotencyKey?.trim();
    if (key != null && key.isNotEmpty && _idempotentRecords.containsKey(key)) {
      return _idempotentRecords[key]!;
    }

    final record = DropOffRecord(
      id: 'DROP-${DateTime.now().millisecondsSinceEpoch}',
      binId: selectedBin.id,
      binName: selectedBin.name,
      building: selectedBin.building,
      locationDescription: selectedBin.locationDescription,
      createdAt: DateTime.now(),
      status: 'submitted',
      rewardStatus: 'not_processed',
      partnerOrganizationName: selectedBin.partnerOrganizationName,
      submissionMethod: submissionMethod,
      items: items
          .map(
            (item) => DropOffRecordItem(
              category: item.category,
              quantity: item.quantity,
            ),
          )
          .toList(growable: false),
      pointsStatus: 'not_processed',
    );
    _records.insert(0, record);
    if (key != null && key.isNotEmpty) {
      _idempotentRecords[key] = record;
    }
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
    return const [];
  }

  Future<PublicBin?> _findBin(String publicBinCode) async {
    final bins = await _publicBinRepository.fetchPublicBins();
    for (final bin in bins) {
      if (bin.publicQrCode == publicBinCode) return bin;
    }
    return null;
  }
}
