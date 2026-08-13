import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/waste_type_mapper.dart';
import '../../../data/models/collected_item_model.dart';
import '../../../data/models/ewaste_detection_result.dart';
import '../../../data/services/ewaste_detection_service.dart';

class CollectorEWasteCaptureScreen extends StatefulWidget {
  const CollectorEWasteCaptureScreen({super.key});

  @override
  State<CollectorEWasteCaptureScreen> createState() =>
      _CollectorEWasteCaptureScreenState();
}

class _CollectorEWasteCaptureScreenState
    extends State<CollectorEWasteCaptureScreen> {
  static const labels = [
    'PCB',
    'air_conditioner',
    'battery',
    'fan',
    'keyboard',
    'laptop',
    'microwave',
    'monitor',
    'mouse',
    'oven',
    'printer',
    'refrigerator',
    'smartphone',
    'television',
    'washing_machine',
  ];

  final ImagePicker _picker = ImagePicker();
  final EWasteDetectionService _detectionService = EWasteDetectionService();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  File? _image;
  EWasteDetectionResult? _result;
  String? _confirmedClass;
  String? _condition = CollectorCollectionConstants.itemConditions.last;
  bool _isModelLoaded = false;
  bool _isDetecting = false;
  String? _message;

  bool get _isLowConfidence => _result != null && _result!.confidence < 0.50;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _detectionService.dispose();
    _quantity.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      await _detectionService.load();
      if (mounted) setState(() => _isModelLoaded = true);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to load local AI model.');
      }
    }
  }

  Future<void> _pickAndDetect(ImageSource source) async {
    if (!_isModelLoaded || _isDetecting) return;
    setState(() {
      _message = null;
      _isDetecting = true;
      _result = null;
      _confirmedClass = null;
    });

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1280,
      );
      if (image == null) {
        if (mounted) setState(() => _isDetecting = false);
        return;
      }

      final result = await _detectionService.detectImageBytes(
        await image.readAsBytes(),
        imagePath: image.path,
      );
      if (!mounted) return;
      setState(() {
        _image = File(image.path);
        _result = result;
        _confirmedClass = result?.detectedClass;
        _isDetecting = false;
        _message = result == null
            ? 'No e-waste detected. Choose a category manually or retake.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _message = 'Detection failed. Please retake or select another image.';
      });
    }
  }

  void _confirmPrediction() {
    final result = _result;
    if (result == null) return;
    setState(() => _confirmedClass = result.detectedClass);
  }

  void _saveItem() {
    final image = _image;
    final quantity = int.tryParse(_quantity.text.trim()) ?? 0;
    final confirmed = (_confirmedClass ?? '').trim();

    if (image == null || !image.existsSync()) {
      setState(() => _message = 'Capture or select an item image first.');
      return;
    }
    if (confirmed.isEmpty) {
      setState(() => _message = 'Confirm or change the collected category.');
      return;
    }
    if (quantity <= 0) {
      setState(() => _message = 'Quantity must be a whole number above zero.');
      return;
    }

    Navigator.pop(
      context,
      CollectedEWasteItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        imagePath: image.path,
        aiPredictedClass: _result?.detectedClass,
        aiConfidence: _result?.confidence,
        confirmedClass: confirmed,
        mappedCategory: WasteTypeMapper.toBackendWasteType(confirmed),
        quantity: quantity,
        condition: _condition,
        remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Scan / Capture E-Waste')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _imagePanel(),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isModelLoaded && !_isDetecting
                      ? () => _pickAndDetect(ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Capture'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isModelLoaded && !_isDetecting
                      ? () => _pickAndDetect(ImageSource.gallery)
                      : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_isDetecting) ...[
            SizedBox(height: 14.h),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_message != null) ...[
            SizedBox(height: 12.h),
            _messageBox(_message!, isWarning: true),
          ],
          if (_result != null) ...[
            SizedBox(height: 14.h),
            _predictionPanel(),
          ],
          SizedBox(height: 14.h),
          _categoryDropdown(),
          SizedBox(height: 12.h),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: _input('Quantity', 'Whole number greater than 0'),
          ),
          SizedBox(height: 12.h),
          DropdownButtonFormField<String>(
            initialValue: _condition,
            decoration: _input('Condition', null),
            items: CollectorCollectionConstants.itemConditions
                .map((condition) => DropdownMenuItem(
                      value: condition,
                      child: Text(condition),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _condition = value),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _remarks,
            maxLines: 3,
            decoration: _input('Remarks', 'Optional notes'),
          ),
          SizedBox(height: 18.h),
          ElevatedButton.icon(
            onPressed: _saveItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item to Collection'),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _imagePanel() {
    return Container(
      height: 260.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: _image == null
          ? Center(
              child: Icon(
                Icons.center_focus_strong,
                size: 42.sp,
                color: RecyTechTheme.primary,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_image!, fit: BoxFit.cover),
            ),
    );
  }

  Widget _predictionPanel() {
    final result = _result!;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prediction: ${result.detectedClass}',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp)),
          SizedBox(height: 4.h),
          Text(
            'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
          ),
          Text('Mapped category: ${result.mappedWasteCategory}'),
          if (_isLowConfidence) ...[
            SizedBox(height: 8.h),
            _messageBox(
              'Low confidence. Confirm carefully or change the category.',
              isWarning: true,
            ),
          ],
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            children: [
              OutlinedButton(
                onPressed: _confirmPrediction,
                child: const Text('Confirm'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _image = null;
                    _result = null;
                    _confirmedClass = null;
                  });
                },
                child: const Text('Retake'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: labels.contains(_confirmedClass) ? _confirmedClass : null,
      decoration: _input('Confirmed Category', 'Confirm or change category'),
      items: labels
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (value) => setState(() => _confirmedClass = value),
    );
  }

  Widget _messageBox(String message, {bool isWarning = false}) {
    final color = isWarning ? Colors.orange.shade800 : RecyTechTheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(message, style: TextStyle(color: color, fontSize: 11.sp)),
    );
  }

  InputDecoration _input(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: RecyTechTheme.border),
      ),
    );
  }
}
