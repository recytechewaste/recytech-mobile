import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/core/utils/waste_type_mapper.dart';
import 'package:recytecmobproj/data/datasources/request_api.dart';
import 'package:recytecmobproj/data/repositories/request_repository.dart';
import 'package:recytecmobproj/services/auth_provider.dart';
import 'package:recytecmobproj/widgets/labeled_textfied.dart';

import '../../../widgets/primary_button.dart';
import 'tracking_screen.dart';

class SubmissionFormScreen extends StatefulWidget {
  final String? detectedItem;
  final double? confidence;
  final String? wasteImage;

  const SubmissionFormScreen({
    super.key,
    this.detectedItem,
    this.confidence,
    this.wasteImage,
  });

  @override
  State<SubmissionFormScreen> createState() => _SubmissionFormScreenState();
}

class _SubmissionFormScreenState extends State<SubmissionFormScreen> {
  final description = TextEditingController();
  final condition = TextEditingController();
  final address = TextEditingController();
  final RequestRepository _requestRepository = RequestRepository(RequestApi());

  bool isSubmitting = false;
  bool isLoadingCategories = false;
  List<String> wasteCategories = [];
  String? selectedWasteType;
  String? categoryLoadError;
  String? formMessage;

  @override
  void initState() {
    super.initState();

    if (widget.detectedItem != null) {
      description.text = WasteTypeMapper.toBackendWasteType(
        widget.detectedItem!,
      );
    }

    _loadWasteCategories();
  }

  @override
  void dispose() {
    description.dispose();
    condition.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final wasteType = WasteTypeMapper.toBackendWasteType(
      _cleanCategory(description.text),
    );
    final location = address.text.trim();

    if (wasteType.isEmpty || location.isEmpty) {
      _showInlineMessage('Please enter the item and pickup location.');
      return;
    }

    setState(() {
      isSubmitting = true;
      formMessage = null;
    });

    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      final residentName = currentUser?.fullName.trim().isNotEmpty == true
          ? currentUser!.fullName
          : 'Mobile Resident';
      final firstName = currentUser?.firstName.trim().isNotEmpty == true
          ? currentUser!.firstName
          : _firstNameFrom(residentName);
      final lastName = currentUser?.lastName.trim().isNotEmpty == true
          ? currentUser!.lastName
          : _lastNameFrom(residentName);

      await _requestRepository.submitRequest(
        wasteType: wasteType,
        location: location,
        quantity: _parseQuantity(condition.text),
        residentName: residentName,
        residentEmail: currentUser?.email ?? '',
        wasteImage: widget.wasteImage,
        phone: '',
        firstName: firstName,
        lastName: lastName,
        mobileUserId: currentUser?.id ?? '',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TrackingScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showInlineMessage(_messageForError(e));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showInlineMessage(String message) {
    setState(() {
      formMessage = message;
    });
  }

  Future<void> _loadWasteCategories() async {
    setState(() {
      isLoadingCategories = true;
      categoryLoadError = null;
    });

    try {
      final categories = await _requestRepository.fetchActiveWasteCategories();
      if (!mounted) return;

      final matchedCategory = _matchCategory(
        WasteTypeMapper.toBackendWasteType(
          widget.detectedItem ?? description.text,
        ),
        categories,
      );

      setState(() {
        wasteCategories = categories;
        selectedWasteType = matchedCategory;
        if (matchedCategory != null) {
          description.text = WasteTypeMapper.toBackendWasteType(
            matchedCategory,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        categoryLoadError = _messageForError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  int _parseQuantity(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return 1;
    return int.tryParse(match.group(0) ?? '') ?? 1;
  }

  String _firstNameFrom(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'Mobile' : parts.first;
  }

  String _lastNameFrom(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length <= 1) return 'Resident';
    return parts.sublist(1).join(' ');
  }

  String _messageForError(Object error) {
    final text = error.toString();
    const marker = 'message: ';
    if (text.contains(marker)) {
      return text.split(marker).last.replaceAll(')', '').trim();
    }

    return 'Request submission failed. Please try again.';
  }

  String _normalizeCategory(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _cleanCategory(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _displayCategory(String value) {
    final readableValue = value
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    return readableValue
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) {
      if (word.toUpperCase() == 'PCB') return 'PCB';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String? _matchCategory(String rawValue, List<String> categories) {
    final normalized = _normalizeCategory(rawValue);
    if (normalized.isEmpty) return null;

    for (final category in categories) {
      if (_normalizeCategory(category) == normalized) {
        return category;
      }
    }

    return null;
  }

  String? _dropdownCategoryValue() {
    final value = selectedWasteType;
    if (value == null || value.trim().isEmpty) return null;

    for (final category in wasteCategories) {
      if (_normalizeCategory(category) == _normalizeCategory(value)) {
        return category;
      }
    }

    return null;
  }

  Widget _categoryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Item Description',
          hintText: 'Describe the item',
          controller: description,
        ),
        if (isLoadingCategories) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 36.h,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ] else if (wasteCategories.isNotEmpty) ...[
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            initialValue: _dropdownCategoryValue(),
            decoration: InputDecoration(
              labelText: 'Active Category',
              hintText: 'Optional category match',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: RecyTechTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide:
                    const BorderSide(color: RecyTechTheme.primary, width: 1.6),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            items: wasteCategories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(
                      _displayCategory(category),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedWasteType = value;
                description.text = value == null
                    ? description.text
                    : WasteTypeMapper.toBackendWasteType(value);
              });
            },
          ),
        ] else if (categoryLoadError != null) ...[
          SizedBox(height: 6.h),
          Text(
            categoryLoadError!,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _inlineMessage() {
    final message = formMessage;
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.red.shade800,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Submission Form'),
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
                'E-Waste Submission Form',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: RecyTechTheme.textDark,
                ),
              ),
            ),
            SizedBox(height: 6.h),

            Center(
              child: Text(
                'Please fill in the details to submit your e-waste for recycling',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // 🔹 ITEM DESCRIPTION
            _categoryInput(),

            if (widget.confidence != null) ...[
              SizedBox(height: 6.h),
              Text(
                'AI Confidence: ${(widget.confidence! * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: RecyTechTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            SizedBox(height: 14.h),

            // 🔹 IMAGE UPLOAD (UI ONLY)
            Text(
              'Provide Upload',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: RecyTechTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),

            Container(
              height: 90.h,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: RecyTechTheme.border),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: _selectedImagePreview(),
            ),
            SizedBox(height: 14.h),

            // 🔹 QUANTITY / CONDITION
            LabeledTextField(
              label: 'Quantity / Condition',
              hintText: 'Enter quantity or condition',
              controller: condition,
            ),
            SizedBox(height: 14.h),

            // 🔹 LOCATION / ADDRESS
            LabeledTextField(
              label: 'Location / Address',
              hintText: 'Enter your address',
              controller: address,
              maxLines: 2,
            ),
            SizedBox(height: 22.h),

            _inlineMessage(),
            if (formMessage != null) SizedBox(height: 12.h),

            // 🔹 ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PrimaryButton(
                  text: 'Cancel',
                  filled: false,
                  width: 130.w,
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 12.w),
                isSubmitting
                    ? SizedBox(
                        width: 130.w,
                        height: 44.h,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : PrimaryButton(
                        text: 'Next',
                        width: 130.w,
                        onPressed: _submitRequest,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedImagePreview() {
    final imagePath = widget.wasteImage?.trim() ?? '';

    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Image.file(
          File(imagePath),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            color: RecyTechTheme.primary,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            imagePath.isEmpty ? 'No image selected' : 'Image ready for upload',
            style: TextStyle(
              fontSize: 10.sp,
              color: RecyTechTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
