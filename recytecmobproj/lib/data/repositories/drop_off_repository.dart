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

  Future<DropOffSubmissionResult> registerDropOff({
    BinQrPayload? payload,
    PublicBin? bin,
    required String wasteType,
    required num quantity,
    String? notes,
    String? image,
  });

  Future<List<DropOffRecord>> getMyDropOffHistory();

  Future<DropOffRecord> getDropOffDetail(String dropOffId);

  Future<List<RewardTransaction>> getMyRewards();
}

class DropOffSubmission {
  const DropOffSubmission({
    this.binId,
    this.qrCode,
    required this.wasteType,
    required this.quantity,
    this.notes,
    this.image,
  });

  final String? binId;
  final String? qrCode;
  final String wasteType;
  final num quantity;
  final String? notes;
  final String? image;

  Map<String, dynamic> toJson() => {
        if ((binId ?? '').isNotEmpty) 'binId': binId,
        if ((binId ?? '').isEmpty && (qrCode ?? '').isNotEmpty)
          'qrCode': qrCode,
        'wasteType': wasteType,
        'quantity': quantity,
        if ((notes ?? '').isNotEmpty) 'notes': notes,
        if ((image ?? '').isNotEmpty) 'image': image,
      };
}

class DropOffSubmissionResult {
  const DropOffSubmissionResult({
    required this.message,
    required this.dropOff,
    this.projectedPoints,
  });

  final String message;
  final DropOffRecord dropOff;
  final int? projectedPoints;
}

class DropOffWasteTypes {
  const DropOffWasteTypes._();

  static const values = <String>{
    'Battery',
    'Small Electronics',
    'Cables & Wires',
    'Mobile Devices',
    'Motherboards',
    'Laptops',
    'Peripherals',
    'Monitors',
  };

  static String? canonicalize(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return const {
      'battery': 'Battery',
      'batteries': 'Battery',
      'small_electronics': 'Small Electronics',
      'cables_and_wires': 'Cables & Wires',
      'cables': 'Cables & Wires',
      'wires': 'Cables & Wires',
      'mobile_devices': 'Mobile Devices',
      'mobile_device': 'Mobile Devices',
      'smartphone': 'Mobile Devices',
      'smartphones': 'Mobile Devices',
      'motherboard': 'Motherboards',
      'motherboards': 'Motherboards',
      'pcb': 'Motherboards',
      'laptop': 'Laptops',
      'laptops': 'Laptops',
      'peripheral': 'Peripherals',
      'peripherals': 'Peripherals',
      'monitor': 'Monitors',
      'monitors': 'Monitors',
    }[normalized];
  }
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
      final response = await _apiClient.dio.get(
        ApiEndpoints.publicBinByQrCode(payload.publicBinCode),
      );
      final data = _extractObject(response.data, preferredKey: 'bin');
      final bin = PublicBin.fromJson(data);
      if (!bin.isActive) {
        throw const DropOffRepositoryException(
          'inactive_bin',
          'This bin is not currently operational.',
        );
      }
      return bin;
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to validate this bin QR.');
    }
  }

  @override
  Future<DropOffSubmissionResult> registerDropOff({
    BinQrPayload? payload,
    PublicBin? bin,
    required String wasteType,
    required num quantity,
    String? notes,
    String? image,
  }) async {
    final canonicalWasteType = DropOffWasteTypes.canonicalize(wasteType);
    if (canonicalWasteType == null) {
      throw const DropOffRepositoryException(
        'unsupported_waste_type',
        'Please select a supported e-waste type.',
      );
    }
    if (!quantity.isFinite || quantity < 0) {
      throw const DropOffRepositoryException(
        'invalid_quantity',
        'Quantity must be a number greater than or equal to 0.',
      );
    }

    final binId = bin?.id.trim();
    final qrCode = payload?.publicBinCode.trim() ?? bin?.publicQrCode.trim();
    if ((binId ?? '').isEmpty && (qrCode ?? '').isEmpty) {
      throw const DropOffRepositoryException(
        'missing_bin',
        'Please select a RecyTech bin before submitting.',
      );
    }

    final submission = DropOffSubmission(
      binId: binId,
      qrCode: qrCode,
      wasteType: canonicalWasteType,
      quantity: quantity,
      notes: notes?.trim(),
      image: image,
    );

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.binDropoffs,
        data: submission.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      final envelope = response.data is Map
          ? (response.data as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final dropOffJson = _extractObject(envelope, preferredKey: 'dropoff');
      return DropOffSubmissionResult(
        message:
            _safeMessage(envelope['message']) ?? 'Drop-off logged successfully',
        dropOff: DropOffRecord.fromJson(dropOffJson),
        projectedPoints: _parseInt(envelope['projectedPoints']),
      );
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to submit this drop-off.');
    }
  }

  @override
  Future<List<DropOffRecord>> getMyDropOffHistory() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.binDropoffs);
      final items = _extractItems(response.data, preferredKey: 'dropoffs');

      return items
          .whereType<Map>()
          .map((item) => DropOffRecord.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to load drop-off history.');
    }
  }

  @override
  Future<DropOffRecord> getDropOffDetail(String dropOffId) async {
    final id = dropOffId.trim();
    if (id.isEmpty) {
      throw const DropOffRepositoryException(
        'missing_dropoff',
        'Drop-off details are unavailable.',
      );
    }

    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.binDropoffById(id));
      final data = _extractObject(response.data, preferredKey: 'dropOff');
      return DropOffRecord.fromJson(data);
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to load drop-off details.');
    }
  }

  @override
  Future<List<RewardTransaction>> getMyRewards() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.myTransactions);
      final items = _extractItems(
        response.data,
        preferredKey: 'transactions',
      );
      return items
          .whereType<Map>()
          .map(
            (item) => RewardTransaction.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw _mapError(error, fallback: 'Unable to load reward transactions.');
    }
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
      final items =
          map[preferredKey] ?? map['data'] ?? map['items'] ?? map['results'];
      if (items is List) return items;
    }
    return const [];
  }

  DropOffRepositoryException _mapError(
    Object error, {
    required String fallback,
  }) {
    if (error is DropOffRepositoryException) return error;

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final code = (data['code'] ?? 'request_failed').toString();
        final message = _safeMessage(data['message']);
        if (message != null) {
          return DropOffRepositoryException(code, message);
        }
      }
      switch (error.response?.statusCode) {
        case 400:
          return const DropOffRepositoryException(
            'invalid_data',
            'Please check the submitted information and try again.',
          );
        case 401:
          return const DropOffRepositoryException(
            'unauthorized',
            'Your session has expired. Please sign in again.',
          );
        case 403:
          return const DropOffRepositoryException(
            'forbidden',
            'Your account is not permitted to perform this action.',
          );
        case 404:
          return DropOffRepositoryException('not_found', fallback);
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

  String? _safeMessage(dynamic value) {
    final message = (value ?? '').toString().trim();
    final lowered = message.toLowerCase();
    if (message.isEmpty ||
        message.length > 180 ||
        lowered.contains('<html') ||
        lowered.contains('mongodb') ||
        lowered.contains('dioexception') ||
        lowered.contains('/bin-dropoffs') ||
        lowered.contains('/bin-locations')) {
      return null;
    }
    return message;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }
}

/// Mock/dev implementation for the Phase 5 household QR flow.
///
/// Mobile must not be the source of truth for eligibility, timestamps, or
/// reward amounts.
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
      status: DropOffStatuses.pending,
      rewardStatus: 'not_processed',
      pointsStatus: 'not_processed',
      pointsAwarded: 0,
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
      status: DropOffStatuses.pending,
      rewardStatus: 'not_processed',
      pointsStatus: 'not_processed',
      pointsAwarded: 0,
      submissionMethod: 'manual',
      items: const [
        DropOffRecordItem(category: 'battery', quantity: 2),
      ],
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
  Future<DropOffSubmissionResult> registerDropOff({
    BinQrPayload? payload,
    PublicBin? bin,
    required String wasteType,
    required num quantity,
    String? notes,
    String? image,
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

    final canonicalWasteType = DropOffWasteTypes.canonicalize(wasteType);
    if (canonicalWasteType == null) {
      throw const DropOffRepositoryException(
        'unsupported_waste_type',
        'Please select a supported e-waste type.',
      );
    }
    if (!quantity.isFinite || quantity < 0) {
      throw const DropOffRepositoryException(
        'invalid_quantity',
        'Quantity must be a number greater than or equal to 0.',
      );
    }

    final record = DropOffRecord(
      id: 'DROP-${DateTime.now().millisecondsSinceEpoch}',
      binId: selectedBin.id,
      binName: selectedBin.name,
      building: selectedBin.building,
      locationDescription: selectedBin.locationDescription,
      createdAt: DateTime.now(),
      status: DropOffStatuses.pending,
      rewardStatus: 'not_processed',
      partnerOrganizationName: selectedBin.partnerOrganizationName,
      submissionMethod: payload == null ? 'manual' : 'qr',
      items: [
        DropOffRecordItem(category: canonicalWasteType, quantity: quantity),
      ],
      pointsStatus: 'not_processed',
    );
    _records.insert(0, record);
    return DropOffSubmissionResult(
      message: 'Drop-off logged successfully',
      dropOff: record,
    );
  }

  @override
  Future<List<DropOffRecord>> getMyDropOffHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final records = List<DropOffRecord>.of(_records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<DropOffRecord>.unmodifiable(records);
  }

  @override
  Future<DropOffRecord> getDropOffDetail(String dropOffId) async {
    final records = await getMyDropOffHistory();
    for (final record in records) {
      if (record.id == dropOffId) return record;
    }
    throw const DropOffRepositoryException(
      'not_found',
      'Drop-off details are unavailable.',
    );
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
