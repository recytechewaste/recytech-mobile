class EWasteDetectionResult {
  EWasteDetectionResult({
    required this.detectedClass,
    required this.confidence,
    required this.mappedWasteCategory,
    this.imagePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String detectedClass;
  final double confidence;
  final String mappedWasteCategory;
  final String? imagePath;
  final DateTime timestamp;
}
