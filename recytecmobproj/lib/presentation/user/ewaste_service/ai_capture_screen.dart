import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/ewaste_detection_result.dart';
import '../../../data/services/ewaste_detection_service.dart';
import '../../../widgets/primary_button.dart';
import 'submission_form_screen.dart';

class AICaptureScreen extends StatefulWidget {
  const AICaptureScreen({super.key});

  @override
  State<AICaptureScreen> createState() => _AICaptureScreenState();
}

class _AICaptureScreenState extends State<AICaptureScreen> {
  static const String _noDetectionLabel = 'No e-waste detected';
  static const String _noDetectionMessage =
      'No e-waste item detected. Try a clearer image with the object centered.';

  final ImagePicker picker = ImagePicker();
  final EWasteDetectionService _detectionService = EWasteDetectionService();

  File? selectedImage;
  EWasteDetectionResult? detectionResult;
  String? detectedLabel;
  double? confidence;

  bool isModelLoaded = false;
  bool isDetecting = false;

  bool get hasUsableDetection =>
      detectionResult != null &&
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
      await _detectionService.load();
      if (!mounted) return;
      setState(() => isModelLoaded = true);
    } catch (e) {
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
      detectionResult = null;
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
      final bytes = await pickedImage.readAsBytes();
      final result = await _detectionService.detectImageBytes(
        bytes,
        imagePath: pickedImage.path,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          detectionResult = result;
          detectedLabel = result.detectedClass;
          confidence = result.confidence;
          isDetecting = false;
        });
      } else {
        setState(() {
          detectionResult = null;
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
          detectedItem: detectionResult!.mappedWasteCategory,
          confidence: confidence,
          wasteImage: selectedImage?.path,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detectionService.dispose();
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
              if (detectionResult != null) ...[
                SizedBox(height: 4.h),
                Center(
                  child: Text(
                    'Category: ${detectionResult!.mappedWasteCategory}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: RecyTechTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
