import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../../core/utils/waste_type_mapper.dart';
import '../models/ewaste_detection_result.dart';

class EWasteDetectionService {
  static const labelsAsset = 'assets/models/labels.txt';
  static const modelAsset = 'assets/models/recytech_yolov8.tflite';
  static const inputSize = 640;
  static const outputRows = 19;
  static const anchorCount = 8400;
  static const boxValueRows = 4;
  static const confidenceThreshold = 0.15;

  tfl.Interpreter? _interpreter;
  List<String> _labels = const [];

  bool get isLoaded => _interpreter != null && _labels.isNotEmpty;

  Future<void> load() async {
    if (isLoaded) return;

    tfl.Interpreter? interpreter;
    try {
      final options = tfl.InterpreterOptions()..threads = 2;
      interpreter = await tfl.Interpreter.fromAsset(
        modelAsset,
        options: options,
      );
      final labels = await _loadLabels();
      final inputShape = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;

      debugPrint(
        'RecyTech AI: direct TFLite model loaded '
        '(model=$modelAsset, inputShape=$inputShape, outputShape=$outputShape).',
      );
      debugPrint(
          'RecyTech AI: labels loaded count=${labels.length}, labels=$labels');
      debugPrint(
        'RecyTech AI: output shape assumption=[1, $outputRows, '
        '$anchorCount], threshold=$confidenceThreshold',
      );

      _interpreter = interpreter;
      _labels = labels;
    } catch (_) {
      interpreter?.close();
      rethrow;
    }
  }

  Future<EWasteDetectionResult?> detectImageBytes(
    Uint8List bytes, {
    String? imagePath,
  }) async {
    if (!isLoaded) {
      throw StateError('AI model is not loaded.');
    }

    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw StateError('Selected image could not be decoded.');
    }

    debugPrint(
      'RecyTech AI: decoded image width=${decodedImage.width}, '
      'height=${decodedImage.height}, bytes=${bytes.length}',
    );
    debugPrint(
      'RecyTech AI: running direct TFLite inference '
      'input=[1, $inputSize, $inputSize, 3], '
      'output=[1, $outputRows, $anchorCount]',
    );

    final detection = _runDirectTfliteInference(decodedImage);

    debugPrint(
      'RecyTech AI: best detected label=${detection.label}, '
      'confidence=${detection.confidence}, classIndex=${detection.classIndex}, '
      'anchorIndex=${detection.anchorIndex}',
    );

    if (detection.label.isEmpty || detection.confidence < confidenceThreshold) {
      debugPrint(
        'RecyTech AI: best score below threshold '
        '(best=${detection.confidence}, threshold=$confidenceThreshold).',
      );
      return null;
    }

    return EWasteDetectionResult(
      detectedClass: detection.label,
      confidence: detection.confidence,
      mappedWasteCategory: WasteTypeMapper.toBackendWasteType(detection.label),
      imagePath: imagePath,
    );
  }

  Future<List<String>> _loadLabels() async {
    final rawLabels = await rootBundle.loadString(labelsAsset);
    return rawLabels
        .split(RegExp(r'\r?\n'))
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  Float32List _imageToInputTensor(img.Image image) {
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );
    final input = Float32List(inputSize * inputSize * 3);
    var index = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.rNormalized.toDouble();
        input[index++] = pixel.gNormalized.toDouble();
        input[index++] = pixel.bNormalized.toDouble();
      }
    }

    return input;
  }

  _DetectionCandidate _parseBestDetection(Float32List output) {
    var bestClassIndex = -1;
    var bestAnchorIndex = -1;
    var bestScore = double.negativeInfinity;
    final classCount = _labels.length;

    for (var anchor = 0; anchor < anchorCount; anchor++) {
      for (var classIndex = 0; classIndex < classCount; classIndex++) {
        final row = boxValueRows + classIndex;
        if (row >= outputRows) break;

        final score = output[(row * anchorCount) + anchor].toDouble();
        if (score > bestScore) {
          bestScore = score;
          bestClassIndex = classIndex;
          bestAnchorIndex = anchor;
        }
      }
    }

    final label = bestClassIndex >= 0 && bestClassIndex < _labels.length
        ? _labels[bestClassIndex]
        : '';

    return _DetectionCandidate(
      label: label,
      confidence: bestScore.isFinite ? bestScore : 0,
      classIndex: bestClassIndex,
      anchorIndex: bestAnchorIndex,
    );
  }

  _DetectionCandidate _runDirectTfliteInference(img.Image decodedImage) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('AI model is not loaded.');
    }

    final input = _imageToInputTensor(decodedImage);
    final output = Float32List(outputRows * anchorCount);

    interpreter.run(input.buffer, output.buffer);

    debugPrint(
      'RecyTech AI: direct TFLite inference complete '
      '(nativeDurationUs=${interpreter.lastNativeInferenceDurationMicroSeconds})',
    );

    return _parseBestDetection(output);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = const [];
  }
}

class _DetectionCandidate {
  const _DetectionCandidate({
    required this.label,
    required this.confidence,
    required this.classIndex,
    required this.anchorIndex,
  });

  final String label;
  final double confidence;
  final int classIndex;
  final int anchorIndex;
}
