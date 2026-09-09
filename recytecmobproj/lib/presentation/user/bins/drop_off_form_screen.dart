import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/models/public_bin_model.dart';
import '../../../data/repositories/drop_off_repository.dart';
import '../history/history_screen.dart';

class DropOffFormScreen extends StatefulWidget {
  const DropOffFormScreen({
    super.key,
    required this.bin,
    required this.submissionMethod,
    this.repository,
  });

  final PublicBin bin;
  final String submissionMethod;
  final DropOffRepository? repository;

  @override
  State<DropOffFormScreen> createState() => _DropOffFormScreenState();
}

class _DropOffFormScreenState extends State<DropOffFormScreen> {
  late final DropOffRepository _repository;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedCategory;
  XFile? _selectedImage;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiDropOffRepository();
    _quantityController = TextEditingController(text: '1');
    _notesController = TextEditingController();
    final categories = _categoryOptions;
    _selectedCategory = categories.isEmpty ? null : categories.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final category = _selectedCategory;
    final quantity = num.tryParse(_quantityController.text.trim());
    if (category == null || category.isEmpty) {
      setState(() => _errorMessage = 'Please select an accepted category.');
      return;
    }
    if (quantity == null || !quantity.isFinite || quantity < 0) {
      setState(() => _errorMessage =
          'Quantity must be a number greater than or equal to 0.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final image = await _encodeSelectedImage();
      final result = await _repository.registerDropOff(
        bin: widget.bin,
        wasteType: category,
        quantity: quantity,
        notes: _notesController.text,
        image: image,
      );
      if (!mounted) return;
      await _showSuccess(result);
    } on DropOffRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _errorMessage = 'Drop-off could not be submitted. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String?> _encodeSelectedImage() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) return null;
    final bytes = await selectedImage.readAsBytes();
    if (bytes.length > 3500000) {
      throw const DropOffRepositoryException(
        'image_too_large',
        'Please choose an image smaller than 3.5 MB.',
      );
    }
    final mimeType = selectedImage.mimeType ?? _mimeType(selectedImage.name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _mimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null && mounted) setState(() => _selectedImage = image);
  }

  Future<void> _showSuccess(DropOffSubmissionResult result) {
    final record = result.dropOff;
    final projectedPoints = result.projectedPoints ?? record.pointsProjected;
    final pointsText = projectedPoints == null
        ? 'Points are pending validation.'
        : 'Projected / Pending: $projectedPoints points';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Drop-off submitted successfully.'),
          content: Text(
            '${result.message}\n${record.binName}\n${_itemsLabel(record)}\n$pointsText',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, record);
              },
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              child: const Text('View History'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = _categoryOptions;

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Submit Drop-Off'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _binSummary(),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: RecyTechTheme.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: RecyTechTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E-waste item',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: categoryOptions
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(_categoryLabel(category)),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _selectedCategory = value),
                  decoration: const InputDecoration(
                    labelText: 'Accepted category',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _quantityController,
                  enabled: !_submitting,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _notesController,
                  enabled: !_submitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take photo'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose photo'),
                      ),
                    ),
                  ],
                ),
                if (_selectedImage != null)
                  Text(
                    'One photo selected',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.textMuted,
                    ),
                  ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: RecyTechTheme.danger,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _submitting || categoryOptions.isEmpty ? null : _submit,
                    icon: _submitting
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label:
                        Text(_submitting ? 'Submitting...' : 'Submit Drop-Off'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _binSummary() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bin.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: RecyTechTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          _row(Icons.apartment_outlined, 'Partner Organization',
              widget.bin.partnerOrganizationName ?? '-'),
          _row(Icons.place_outlined, 'Location', widget.bin.address),
          _row(Icons.qr_code_2_outlined, 'Bin QR', widget.bin.publicQrCode),
          _row(Icons.input_outlined, 'Method',
              widget.submissionMethod.toUpperCase()),
          if (widget.bin.acceptedCategoryLabels.isNotEmpty)
            _row(
              Icons.check_circle_outline,
              'Accepts',
              widget.bin.acceptedCategoryLabels.join(', '),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17.sp, color: RecyTechTheme.primary),
          SizedBox(width: 8.w),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 5,
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    return category;
  }

  List<String> get _categoryOptions => widget.bin.acceptedCategories
      .map(DropOffWasteTypes.canonicalize)
      .whereType<String>()
      .toSet()
      .toList(growable: false);

  String _itemsLabel(DropOffRecord record) {
    if (record.items.isEmpty) return 'Item recorded.';
    return record.items
        .map((item) =>
            '${item.categoryLabel ?? _displayCategory(item.category)} x ${item.quantity}')
        .join(', ');
  }

  String _displayCategory(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (normalized == 'pcb') return 'PCB';
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
