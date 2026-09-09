import '../../core/utils/waste_type_mapper.dart';

class CollectedWastePayloadItem {
  const CollectedWastePayloadItem({
    required this.category,
    required this.quantity,
    required this.unit,
  });

  final String category;
  final num quantity;
  final String unit;

  bool get isValid =>
      category.trim().isNotEmpty &&
      quantity.isFinite &&
      quantity >= 0 &&
      unit.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    if (!isValid) {
      throw const FormatException(
        'Each collected item requires category, non-negative quantity, and unit.',
      );
    }
    return {
      'category': category.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
    };
  }

  factory CollectedWastePayloadItem.fromJson(Map<String, dynamic> json) {
    return CollectedWastePayloadItem(
      category: (json['category'] ?? '').toString(),
      quantity: json['quantity'] is num ? json['quantity'] as num : double.nan,
      unit: (json['unit'] ?? '').toString(),
    );
  }
}

class CollectedEWasteItem {
  CollectedEWasteItem({
    required this.id,
    required this.imagePath,
    this.aiPredictedClass,
    this.aiConfidence,
    required this.confirmedClass,
    String? mappedCategory,
    required this.quantity,
    this.condition,
    this.remarks,
    DateTime? capturedAt,
  })  : mappedCategory = mappedCategory ??
            WasteTypeMapper.toBackendWasteType(confirmedClass),
        capturedAt = capturedAt ?? DateTime.now();

  final String id;
  final String imagePath;
  final String? aiPredictedClass;
  final double? aiConfidence;
  final String confirmedClass;
  final String mappedCategory;
  final num quantity;
  final String? condition;
  final String? remarks;
  final DateTime capturedAt;

  CollectedWastePayloadItem toCompletionItem() {
    return CollectedWastePayloadItem(
      category: _completionCategory(confirmedClass),
      quantity: quantity,
      unit: 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'aiPredictedClass': aiPredictedClass,
      'detectedCategory': aiPredictedClass,
      'aiConfidence': aiConfidence,
      'confidence': aiConfidence,
      'confirmedClass': confirmedClass,
      'confirmedCategory': confirmedClass,
      'wasCorrected': aiPredictedClass != null &&
          aiPredictedClass!.trim().toLowerCase() !=
              confirmedClass.trim().toLowerCase(),
      'mappedCategory': mappedCategory,
      'quantity': quantity,
      'condition': condition,
      'remarks': remarks,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory CollectedEWasteItem.fromJson(Map<String, dynamic> json) {
    return CollectedEWasteItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
      aiPredictedClass:
          _nullableString(json['aiPredictedClass'] ?? json['detectedCategory']),
      aiConfidence: _readDouble(json['aiConfidence'] ?? json['confidence']),
      confirmedClass:
          (json['confirmedClass'] ?? json['confirmedCategory'] ?? '')
              .toString(),
      quantity: _readNum(json['quantity']),
      condition: _nullableString(json['condition']),
      remarks: _nullableString(json['remarks']),
      capturedAt: _readDate(json['capturedAt']) ?? DateTime.now(),
    );
  }
}

class CollectionReportDraft {
  CollectionReportDraft({
    required this.assignmentId,
    required this.requestReference,
    required this.collectorName,
    this.collectorId,
    this.lguId,
    this.lguName,
    this.binId,
    this.binName,
    this.binLocation,
    this.beforeImagePath,
    this.beforeCondition,
    this.initialRemarks,
    this.afterImagePath,
    this.finalBinStatus,
    this.finalRemarks,
    this.totalWeightKg,
    this.idempotencyKey,
    DateTime? startedAt,
    this.completedAt,
    List<CollectedEWasteItem>? items,
  })  : startedAt = startedAt ?? DateTime.now(),
        items = items ?? <CollectedEWasteItem>[];

  final String assignmentId;
  final String requestReference;
  final String collectorName;
  final String? collectorId;
  final String? lguId;
  final String? lguName;
  final String? binId;
  final String? binName;
  final String? binLocation;
  String? beforeImagePath;
  String? beforeCondition;
  String? initialRemarks;
  String? afterImagePath;
  String? finalBinStatus;
  String? finalRemarks;
  double? totalWeightKg;
  String? idempotencyKey;
  final DateTime startedAt;
  DateTime? completedAt;
  final List<CollectedEWasteItem> items;

  num get totalQuantity =>
      items.fold<num>(0, (total, item) => total + item.quantity);

  int get totalCategories =>
      items.map((item) => item.mappedCategory).toSet().length;

  Map<String, num> get confirmedCategorySummary {
    final summary = <String, num>{};
    for (final item in items) {
      summary[item.confirmedClass] =
          (summary[item.confirmedClass] ?? 0) + item.quantity;
    }
    return summary;
  }

  bool get hasBeforeDocumentation =>
      (beforeImagePath ?? '').trim().isNotEmpty &&
      (beforeCondition ?? '').trim().isNotEmpty;

  bool get hasAfterDocumentation =>
      (afterImagePath ?? '').trim().isNotEmpty &&
      (finalBinStatus ?? '').trim().isNotEmpty;

  bool get hasValidItems => items
      .map((item) => item.toCompletionItem())
      .every((item) => item.isValid);

  bool get canSubmit => hasValidItems;

  List<CollectedWastePayloadItem> get completionItems =>
      items.map((item) => item.toCompletionItem()).toList(growable: false);

  String? get completionNotes {
    final values = <String?>[
      beforeCondition == null ? null : 'Before: $beforeCondition',
      initialRemarks,
      finalBinStatus == null ? null : 'After: $finalBinStatus',
      finalRemarks,
    ];
    for (final item in items) {
      final details = <String?>[item.condition, item.remarks]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .join(', ');
      if (details.isNotEmpty) {
        values.add('${_completionCategory(item.confirmedClass)}: $details');
      }
    }
    final note = values
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('. ');
    return note.isEmpty ? null : note;
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'requestId': assignmentId,
      'requestReference': requestReference,
      'collectorId': collectorId,
      'collectorName': collectorName,
      'lguId': lguId,
      'lguName': lguName,
      'binId': binId,
      'binName': binName,
      'binLocation': binLocation,
      'beforeImagePath': beforeImagePath,
      'beforeCondition': beforeCondition,
      'initialRemarks': initialRemarks,
      'afterImagePath': afterImagePath,
      'finalBinStatus': finalBinStatus,
      'finalRemarks': finalRemarks,
      'totalWeightKg': totalWeightKg,
      'idempotencyKey': idempotencyKey,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'confirmedCategorySummary': confirmedCategorySummary,
      'totalCategories': totalCategories,
      'totalQuantity': totalQuantity,
    };
  }

  factory CollectionReportDraft.fromJson(Map<String, dynamic> json) {
    final remarks = _readMap(json['remarks']);
    final weight = _readMap(json['optionalTotalWeight']);
    final items = json['items'] is List
        ? (json['items'] as List)
            .whereType<Map>()
            .map((item) =>
                CollectedEWasteItem.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <CollectedEWasteItem>[];

    return CollectionReportDraft(
      assignmentId:
          (json['collectionRequestId'] ?? json['requestId'] ?? '').toString(),
      requestReference:
          (json['requestReference'] ?? json['id'] ?? '').toString(),
      collectorName: (json['collectorName'] ?? '').toString(),
      collectorId: _nullableString(json['collectorId']),
      lguId: _nullableString(json['partnerOrganizationId'] ?? json['lguId']),
      lguName:
          _nullableString(json['partnerOrganizationName'] ?? json['lguName']),
      binId: _nullableString(json['binId'] ?? json['binCode']),
      binName: _nullableString(json['binName']),
      binLocation: _nullableString(json['location'] ?? json['binLocation']),
      beforeImagePath: _nullableString(_readMap(json['beforeEvidence'])['url']),
      beforeCondition: _nullableString(remarks['beforeCondition']),
      initialRemarks: _nullableString(remarks['initialRemarks']),
      afterImagePath: _nullableString(_readMap(json['afterEvidence'])['url']),
      finalBinStatus: _nullableString(remarks['finalBinStatus']),
      finalRemarks: _nullableString(remarks['finalRemarks']),
      totalWeightKg:
          _readDouble(json['totalWeightKg'] ?? weight['totalWeightKg']),
      startedAt: _readDate(json['startedAt']) ?? DateTime.now(),
      completedAt: _readDate(json['completedAt'] ?? json['submittedAt']),
      items: items,
    );
  }
}

String? _nullableString(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty || text == 'null' ? null : text;
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString());
}

num _readNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse((value ?? '').toString()) ?? double.nan;
}

DateTime? _readDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String _completionCategory(String value) {
  final normalized =
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  switch (normalized) {
    case 'battery':
      return 'Battery';
    case 'smartphone':
    case 'mobile_device':
    case 'mobile_devices':
      return 'Mobile Devices';
    case 'pcb':
    case 'motherboard':
    case 'motherboards':
      return 'Motherboards';
    case 'cable':
    case 'cables':
    case 'cables_&_wires':
      return 'Cables & Wires';
    case 'air_conditioner':
    case 'fan':
    case 'microwave':
    case 'oven':
    case 'refrigerator':
    case 'washing_machine':
      return 'Small Appliances';
    case 'keyboard':
    case 'laptop':
    case 'monitor':
    case 'mouse':
    case 'printer':
    case 'television':
      return 'Small Electronics';
    case 'plastic':
    case 'plastics':
      return 'Plastics';
    case 'metal':
      return 'Metal';
    case 'other':
      return 'Other';
    default:
      return WasteTypeMapper.toBackendWasteType(value);
  }
}
