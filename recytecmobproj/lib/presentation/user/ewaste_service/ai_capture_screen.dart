import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';

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

  final FlutterVision vision = FlutterVision();
  final ImagePicker picker = ImagePicker();

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
    try {
      await vision.loadYoloModel(
        labels: _labelsAsset,
        modelPath: _modelAsset,
        modelVersion: 'yolov8',
        quantization: false,
        numThreads: 2,
        useGpu: false,
      );

      if (!mounted) return;

      setState(() {
        isModelLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;

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

  double confidenceFor(Map<String, dynamic> detection) {
    final box = detection['box'];
    if (box is List && box.length > 4 && box[4] is num) {
      return (box[4] as num).toDouble();
    }

    final score = detection['confidence'] ?? detection['score'];
    if (score is num) return score.toDouble();

    return 0;
  }

  String labelFor(Map<String, dynamic> detection) {
    return (detection['tag'] ?? detection['label'] ?? detection['class'] ?? '')
        .toString()
        .trim();
  }

  Future<ui.Image> decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> pickAndDetectImage(ImageSource source) async {
    if (!isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI model is still loading. Please wait.'),
        ),
      );
      return;
    }

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

    setState(() {
      selectedImage = File(pickedImage.path);
      detectedLabel = null;
      confidence = null;
      isDetecting = true;
    });

    try {
      final Uint8List bytes = await pickedImage.readAsBytes();
      final decodedImage = await decodeImage(bytes);

      final result = await vision.yoloOnImage(
        bytesList: bytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );

      if (!mounted) return;

      final detections = result
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

      if (detections.isNotEmpty) {
        detections.sort(
          (a, b) => confidenceFor(b).compareTo(confidenceFor(a)),
        );

        final bestDetection = detections.first;
        final bestLabel = labelFor(bestDetection);
        final bestConfidence = confidenceFor(bestDetection);

        if (bestLabel.isEmpty || bestConfidence <= 0) {
          setState(() {
            detectedLabel = _noDetectionLabel;
            confidence = null;
            isDetecting = false;
          });
          showErrorSnackBar('No e-waste object detected. Try another image.');
          return;
        }

        setState(() {
          detectedLabel = bestLabel;
          confidence = bestConfidence;
          isDetecting = false;
        });
      } else {
        setState(() {
          detectedLabel = _noDetectionLabel;
          confidence = null;
          isDetecting = false;
        });

        showErrorSnackBar('No e-waste object detected. Try another image.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isDetecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detection failed: $e')),
      );
    }
  }

  void useDetectedResult() {
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
    vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
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
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              height: 420.h,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: selectedImage == null
                  ? Center(
                      child: Icon(
                        Icons.center_focus_strong,
                        size: 36.sp,
                        color: Colors.black54,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
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
                  color: Colors.black54,
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
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(height: 14.h),
            ],
            Center(
              child: PrimaryButton(
                text: 'Cancel',
                filled: false,
                width: 220.w,
                onPressed: () => Navigator.pop(context),
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
