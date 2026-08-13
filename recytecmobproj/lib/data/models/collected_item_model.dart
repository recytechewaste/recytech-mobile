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
  final DateTime startedAt;
  DateTime? completedAt;
  final List<CollectedEWasteItem> items;

  int get totalQuantity =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  int get totalCategories =>
      items.map((item) => item.mappedCategory).toSet().length;

  Map<String, int> get confirmedCategorySummary {
    final summary = <String, int>{};
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

  bool get hasValidItems =>
      items.isNotEmpty && items.every((item) => item.quantity > 0);

  bool get canSubmit =>
      hasBeforeDocumentation && hasAfterDocumentation && hasValidItems;

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
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'confirmedCategorySummary': confirmedCategorySummary,
      'totalCategories': totalCategories,
      'totalQuantity': totalQuantity,
    };
  }
}
