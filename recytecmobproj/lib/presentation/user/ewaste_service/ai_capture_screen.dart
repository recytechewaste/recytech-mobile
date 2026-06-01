import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../../../core/theme/recytechtheme.dart';
import '../../../widgets/primary_button.dart';
import 'submission_form_screen.dart';

class AICaptureScreen extends StatefulWidget {
  const AICaptureScreen({super.key});

  @override
  State<AICaptureScreen> createState() => _AICaptureScreenState();
}

class _AICaptureScreenState extends State<AICaptureScreen> {
  static const String _labelsAsset = 'assets/models/labels.txt';
  static const String _modelAsset = 'assets/models/recytech_yolov8.tflite';
  static const String _noDetectionLabel = 'No e-waste detected';
  static const String _noDetectionMessage =
      'No e-waste item detected. Try a clearer image with the object centered.';
  static const int _inputSize = 640;
  static const int _outputRows = 19;
  static const int _anchorCount = 8400;
  static const int _boxValueRows = 4;
  static const double _confidenceThreshold = 0.15;

  final ImagePicker picker = ImagePicker();

  tfl.Interpreter? _interpreter;
  List<String> _labels = [];

  File? selectedImage;
  String? detectedLabel;
  double? confidence;

  bool isModelLoaded = false;
  bool isDetecting = false;

  bool get hasUsableDetection =>
      detectedLabel != null &&
      detectedLabel != _noDetectionLabel &&
      confidence != null;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    tfl.Interpreter? interpreter;
    try {
      final options = tfl.InterpreterOptions()..threads = 2;
      interpreter = await tfl.Interpreter.fromAsset(
        _modelAsset,
        options: options,
      );
      final labels = await _loadLabels();
      final inputShape = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;

      debugPrint(
        'RecyTech AI: direct TFLite model loaded '
        '(model=$_modelAsset, inputShape=$inputShape, '
        'outputShape=$outputShape).',
      );
      debugPrint(
        'RecyTech AI: labels loaded count=${labels.length}, '
        'labels=$labels',
      );
      debugPrint(
        'RecyTech AI: output shape assumption=[1, $_outputRows, '
        '$_anchorCount], threshold=$_confidenceThreshold',
      );

      if (!mounted) return;

      setState(() {
        _interpreter = interpreter;
        _labels = labels;
        isModelLoaded = true;
      });
    } catch (e) {
      interpreter?.close();
      if (!mounted) return;

      debugPrint('RecyTech AI: failed to load direct TFLite model: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load AI model: $e')),
      );
    }
  }

  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void resetScan() {
    if (isDetecting) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _clearCurrentScan();
  }

  void _clearCurrentScan({bool detecting = false}) {
    if (!mounted) return;

    setState(() {
      selectedImage = null;
      detectedLabel = null;
      confidence = null;
      isDetecting = detecting;
    });
  }

  Future<void> navigateBackSafely() async {
    if (isDetecting) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      await navigator.maybePop();
    } else {
      resetScan();
    }
  }

  Future<List<String>> _loadLabels() async {
    final rawLabels = await rootBundle.loadString(_labelsAsset);
    return rawLabels
        .split(RegExp(r'\r?\n'))
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  Float32List _imageToInputTensor(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );
    final input = Float32List(_inputSize * _inputSize * 3);
    var index = 0;

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.rNormalized.toDouble();
        input[index++] = pixel.gNormalized.toDouble();
        input[index++] = pixel.bNormalized.toDouble();
      }
    }

    return input;
  }

  _DetectionResult _parseBestDetection(Float32List output) {
    var bestClassIndex = -1;
    var bestAnchorIndex = -1;
    var bestScore = double.negativeInfinity;
    final classCount = _labels.length;

    for (var anchor = 0; anchor < _anchorCount; anchor++) {
      for (var classIndex = 0; classIndex < classCount; classIndex++) {
        final row = _boxValueRows + classIndex;
        if (row >= _outputRows) break;

        final score = output[(row * _anchorCount) + anchor].toDouble();
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

    return _DetectionResult(
      label: label,
      confidence: bestScore.isFinite ? bestScore : 0,
      classIndex: bestClassIndex,
      anchorIndex: bestAnchorIndex,
    );
  }

  _DetectionResult _runDirectTfliteInference(img.Image decodedImage) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('AI model is not loaded.');
    }

    final input = _imageToInputTensor(decodedImage);
    final output = Float32List(_outputRows * _anchorCount);

    interpreter.run(input.buffer, output.buffer);

    debugPrint(
      'RecyTech AI: direct TFLite inference complete '
      '(nativeDurationUs=${interpreter.lastNativeInferenceDurationMicroSeconds})',
    );

    return _parseBestDetection(output);
  }

  Future<void> pickAndDetectImage(ImageSource source) async {
    if (isDetecting) return;

    if (!isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI model is still loading. Please wait.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _clearCurrentScan();

    final XFile? image;
    try {
      image = await picker.pickImage(source: source);
    } catch (e) {
      showErrorSnackBar('Could not open image picker: $e');
      return;
    }

    final pickedImage = image;
    if (pickedImage == null) return;
    if (!mounted) return;

    debugPrint('RecyTech AI: selected image path=${pickedImage.path}');

    setState(() {
      selectedImage = File(pickedImage.path);
      isDetecting = true;
    });

    try {
      final Uint8List bytes = await pickedImage.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw StateError('Selected image could not be decoded.');
      }

      debugPrint(
        'RecyTech AI: decoded image '
        'width=${decodedImage.width}, height=${decodedImage.height}, '
        'bytes=${bytes.length}',
      );
      debugPrint(
        'RecyTech AI: running direct TFLite inference '
        'input=[1, $_inputSize, $_inputSize, 3], '
        'output=[1, $_outputRows, $_anchorCount]',
      );

      final result = _runDirectTfliteInference(decodedImage);

      if (!mounted) return;

      debugPrint(
        'RecyTech AI: best detected label=${result.label}, '
        'confidence=${result.confidence}, '
        'classIndex=${result.classIndex}, anchorIndex=${result.anchorIndex}',
      );

      if (result.label.isNotEmpty &&
          result.confidence >= _confidenceThreshold) {
        setState(() {
          detectedLabel = result.label;
          confidence = result.confidence;
          isDetecting = false;
        });
      } else {
        debugPrint(
          'RecyTech AI: best score below threshold '
          '(best=${result.confidence}, threshold=$_confidenceThreshold).',
        );
        setState(() {
          detectedLabel = _noDetectionLabel;
          confidence = null;
          isDetecting = false;
        });

        showErrorSnackBar(_noDetectionMessage);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isDetecting = false;
      });

      debugPrint('RecyTech AI: detection failed: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detection failed: $e')),
      );
    }
  }

  void useDetectedResult() {
    if (isDetecting) return;

    if (!hasUsableDetection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan a valid e-waste item first.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionFormScreen(
          detectedItem: detectedLabel,
          confidence: confidence,
          wasteImage: selectedImage?.path,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canNavigateBack = Navigator.of(context).canPop();

    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: canNavigateBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: isDetecting ? null : navigateBackSafely,
                )
              : null,
          title: const Text('Submit E-Waste'),
          actions: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.more_vert),
            SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Center(
              child: Text(
                'AI Based Electronic Waste Identification',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              height: 420.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: RecyTechTheme.border),
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: RecyTechTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: selectedImage == null
                  ? Center(
                      child: Container(
                        width: 74.w,
                        height: 74.w,
                        decoration: const BoxDecoration(
                          color: RecyTechTheme.pill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.center_focus_strong,
                          size: 36.sp,
                          color: RecyTechTheme.primary,
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(22.r),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: Text(
                isModelLoaded
                    ? isDetecting
                        ? 'Detecting e-waste item...'
                        : 'Upload or capture image'
                    : 'Loading AI model...',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            if (isDetecting) ...[
              const Center(child: CircularProgressIndicator()),
              SizedBox(height: 14.h),
            ],
            if (detectedLabel != null && !isDetecting) ...[
              Center(
                child: Text(
                  'Detected: $detectedLabel',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              if (confidence != null)
                Center(
                  child: Text(
                    'Confidence: ${(confidence! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: RecyTechTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(height: 14.h),
            ],
            Center(
              child: PrimaryButton(
                text: 'Try Again',
                filled: false,
                width: 220.w,
                onPressed: isDetecting ? null : resetScan,
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: PrimaryButton(
                text: 'Capture Image',
                width: 220.w,
                onPressed: isModelLoaded && !isDetecting
                    ? () => pickAndDetectImage(ImageSource.camera)
                    : null,
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: PrimaryButton(
                text: 'Upload Image',
                width: 220.w,
                onPressed: isModelLoaded && !isDetecting
                    ? () => pickAndDetectImage(ImageSource.gallery)
                    : null,
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: PrimaryButton(
                text: 'Use this result',
                width: 220.w,
                onPressed: hasUsableDetection && !isDetecting
                    ? useDetectedResult
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionResult {
  const _DetectionResult({
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
