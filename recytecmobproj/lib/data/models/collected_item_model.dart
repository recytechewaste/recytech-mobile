import '../../core/utils/waste_type_mapper.dart';

class CollectedEWasteItem {
  CollectedEWasteItem({
    required this.id,
    required this.imagePath,
    this.aiPredictedClass,
    this.aiConfidence,
    required this.confirmedClass,
    String? mappedCategory,
    required this.quantity,
    required this.weightKg,
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
  final int quantity;
  final double weightKg;
  final String? condition;
  final String? remarks;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'aiPredictedClass': aiPredictedClass,
      'aiConfidence': aiConfidence,
      'confirmedClass': confirmedClass,
      'mappedCategory': mappedCategory,
      'quantity': quantity,
      'weightKg': weightKg,
      'condition': condition,
      'remarks': remarks,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }
}

class CollectionReportDraft {
  CollectionReportDraft({
    required this.assignmentId,
    required this.requestReference,
    required this.collectorName,
    this.lguName,
    this.binName,
    this.binLocation,
    this.beforeImagePath,
    this.beforeCondition,
    this.initialRemarks,
    this.afterImagePath,
    this.finalBinStatus,
    this.finalRemarks,
    DateTime? startedAt,
    this.completedAt,
    List<CollectedEWasteItem>? items,
  })  : startedAt = startedAt ?? DateTime.now(),
        items = items ?? <CollectedEWasteItem>[];

  final String assignmentId;
  final String requestReference;
  final String collectorName;
  final String? lguName;
  final String? binName;
  final String? binLocation;
  String? beforeImagePath;
  String? beforeCondition;
  String? initialRemarks;
  String? afterImagePath;
  String? finalBinStatus;
  String? finalRemarks;
  final DateTime startedAt;
  DateTime? completedAt;
  final List<CollectedEWasteItem> items;

  int get totalQuantity =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  double get totalWeightKg =>
      items.fold<double>(0, (total, item) => total + item.weightKg);

  int get totalCategories =>
      items.map((item) => item.mappedCategory).toSet().length;

  bool get hasBeforeDocumentation =>
      (beforeImagePath ?? '').trim().isNotEmpty &&
      (beforeCondition ?? '').trim().isNotEmpty;

  bool get hasAfterDocumentation =>
      (afterImagePath ?? '').trim().isNotEmpty &&
      (finalBinStatus ?? '').trim().isNotEmpty;

  bool get canSubmit =>
      hasBeforeDocumentation && hasAfterDocumentation && items.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'requestReference': requestReference,
      'collectorName': collectorName,
      'lguName': lguName,
      'binName': binName,
      'binLocation': binLocation,
      'beforeImagePath': beforeImagePath,
      'beforeCondition': beforeCondition,
      'initialRemarks': initialRemarks,
      'afterImagePath': afterImagePath,
      'finalBinStatus': finalBinStatus,
      'finalRemarks': finalRemarks,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalCategories': totalCategories,
      'totalQuantity': totalQuantity,
      'totalWeightKg': totalWeightKg,
    };
  }
}
