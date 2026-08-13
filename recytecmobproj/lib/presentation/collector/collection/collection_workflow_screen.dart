import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/collected_item_model.dart';
import '../../../data/models/collector_job_model.dart';
import '../../../data/repositories/collection_completion_repository.dart';
import '../../../data/repositories/collector_repository.dart';
import '../../../services/auth_provider.dart';
import 'collector_ewaste_capture_screen.dart';

class CollectionWorkflowScreen extends StatefulWidget {
  const CollectionWorkflowScreen({
    super.key,
    required this.job,
  });

  final CollectorJob job;

  @override
  State<CollectionWorkflowScreen> createState() =>
      _CollectionWorkflowScreenState();
}

class _CollectionWorkflowScreenState extends State<CollectionWorkflowScreen> {
  final ImagePicker _picker = ImagePicker();
  final CollectorRepository _collectorRepository = CollectorRepository();
  final CollectionCompletionRepository _completionRepository =
      MockCollectionCompletionRepository();
  final TextEditingController _initialRemarks = TextEditingController();
  final TextEditingController _finalRemarks = TextEditingController();

  late final CollectionReportDraft _draft;
  String? _beforeCondition;
  String? _finalStatus;
  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _draft = CollectionReportDraft(
      assignmentId: widget.job.id,
      requestReference: widget.job.requestCode,
      collectorName: user?.fullName.trim().isNotEmpty == true
          ? user!.fullName.trim()
          : 'Collector',
      binName: widget.job.displayItem,
      binLocation: widget.job.location,
    );
  }

  @override
  void dispose() {
    _initialRemarks.dispose();
    _finalRemarks.dispose();
    super.dispose();
  }

  Future<void> _pickBeforeImage() async {
    await _pickImage((path) => _draft.beforeImagePath = path);
  }

  Future<void> _pickAfterImage() async {
    await _pickImage((path) => _draft.afterImagePath = path);
  }

  Future<void> _pickImage(ValueChanged<String> onPicked) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 78,
        maxWidth: 1280,
      );
      if (image == null || !mounted) return;
      setState(() => onPicked(image.path));
    } catch (_) {
      setState(() => _message = 'Could not open camera. Please try again.');
    }
  }

  Future<void> _addItem() async {
    final item = await Navigator.push<CollectedEWasteItem>(
      context,
      MaterialPageRoute(builder: (_) => const CollectorEWasteCaptureScreen()),
    );
    if (item == null || !mounted) return;
    setState(() => _draft.items.add(item));
  }

  void _removeItem(CollectedEWasteItem item) {
    setState(() => _draft.items.remove(item));
  }

  Future<void> _complete() async {
    if (_isSubmitting) return;

    _draft.beforeCondition = _beforeCondition;
    _draft.initialRemarks = _initialRemarks.text.trim().isEmpty
        ? null
        : _initialRemarks.text.trim();
    _draft.finalBinStatus = _finalStatus;
    _draft.finalRemarks =
        _finalRemarks.text.trim().isEmpty ? null : _finalRemarks.text.trim();

    if (!_draft.canSubmit) {
      setState(() {
        _message =
            'Before image, before condition, at least one item, after image, and final status are required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      _draft.completedAt = DateTime.now();
      await _completionRepository.submitCollectionReport(_draft);
      await _collectorRepository.updateJobStatus(
        requestId: widget.job.id,
        status: CollectorJobStatuses.backendValue(
          CollectorJobStatuses.completed,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection report completed.')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Completion failed. Please retry.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnsaved = _draft.items.isNotEmpty ||
        (_draft.beforeImagePath ?? '').isNotEmpty ||
        (_draft.afterImagePath ?? '').isNotEmpty;

    return PopScope(
      canPop: !hasUnsaved || _isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isSubmitting) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(title: const Text('Collection Report')),
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _stepHeader(),
            SizedBox(height: 12.h),
            _beforeSection(),
            SizedBox(height: 16.h),
            _itemsSection(),
            SizedBox(height: 16.h),
            _afterSection(),
            SizedBox(height: 16.h),
            _reviewSection(),
            if (_message != null) ...[
              SizedBox(height: 12.h),
              _messageBox(_message!),
            ],
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _complete,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Confirm & Complete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepHeader() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.job.requestCode,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 4.h),
          Text(widget.job.location.isEmpty ? '-' : widget.job.location),
          SizedBox(height: 10.h),
          LinearProgressIndicator(value: _progress()),
        ],
      ),
    );
  }

  Widget _beforeSection() {
    return _panel(
      title: 'Before Collection',
      children: [
        _imagePreview(_draft.beforeImagePath),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: _pickBeforeImage,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Capture Before Image'),
        ),
        SizedBox(height: 10.h),
        DropdownButtonFormField<String>(
          initialValue: _beforeCondition,
          decoration: _input('Bin condition'),
          items: CollectorCollectionConstants.beforeBinConditions
              .map((condition) => DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _beforeCondition = value),
        ),
        SizedBox(height: 10.h),
        TextField(
          controller: _initialRemarks,
          maxLines: 2,
          decoration: _input('Initial remarks'),
        ),
      ],
    );
  }

  Widget _itemsSection() {
    return _panel(
      title: 'Collected Items',
      trailing: OutlinedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      children: [
        if (_draft.items.isEmpty)
          Text(
            'No collected items added yet.',
            style: TextStyle(color: RecyTechTheme.textMuted, fontSize: 11.sp),
          )
        else
          ..._draft.items.map(_itemTile),
        SizedBox(height: 8.h),
        Text(
          'Categories: ${_draft.totalCategories}   Quantity: ${_draft.totalQuantity}   Weight: ${_draft.totalWeightKg.toStringAsFixed(2)} kg',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _afterSection() {
    return _panel(
      title: 'After Collection',
      children: [
        _imagePreview(_draft.afterImagePath),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: _pickAfterImage,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Capture After Image'),
        ),
        SizedBox(height: 10.h),
        DropdownButtonFormField<String>(
          initialValue: _finalStatus,
          decoration: _input('Final bin status'),
          items: CollectorCollectionConstants.finalBinStatuses
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _finalStatus = value),
        ),
        SizedBox(height: 10.h),
        TextField(
          controller: _finalRemarks,
          maxLines: 2,
          decoration: _input('Final remarks'),
        ),
      ],
    );
  }

  Widget _reviewSection() {
    return _panel(
      title: 'Review',
      children: [
        _reviewRow('Request', _draft.requestReference),
        _reviewRow('Collector', _draft.collectorName),
        _reviewRow('Bin / Item', widget.job.displayItem),
        _reviewRow('Location', widget.job.location),
        _reviewRow('Before condition', _beforeCondition ?? '-'),
        _reviewRow('Final status', _finalStatus ?? '-'),
        _reviewRow('Total quantity', _draft.totalQuantity.toString()),
        _reviewRow(
            'Total weight', '${_draft.totalWeightKg.toStringAsFixed(2)} kg'),
      ],
    );
  }

  Widget _panel({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 10.h),
          ...children,
        ],
      ),
    );
  }

  Widget _itemTile(CollectedEWasteItem item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.mappedCategory),
      subtitle: Text(
        'AI: ${item.aiPredictedClass ?? '-'} (${((item.aiConfidence ?? 0) * 100).toStringAsFixed(1)}%)\n'
        'Qty ${item.quantity}, ${item.weightKg.toStringAsFixed(2)} kg, ${item.condition ?? 'Unknown'}',
      ),
      trailing: IconButton(
        tooltip: 'Remove item',
        onPressed: () => _removeItem(item),
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }

  Widget _imagePreview(String? path) {
    final value = (path ?? '').trim();
    if (value.isEmpty || !File(value).existsSync()) {
      return Container(
        height: 110.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RecyTechTheme.pill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RecyTechTheme.border),
        ),
        child: Text(
          value.isEmpty ? 'No image captured' : 'Image file unavailable',
          style: TextStyle(color: RecyTechTheme.textMuted, fontSize: 11.sp),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(value),
        width: double.infinity,
        height: 140.h,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(String message) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: RecyTechTheme.border),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: RecyTechTheme.border),
      ),
    );
  }

  double _progress() {
    var complete = 0;
    if ((_draft.beforeImagePath ?? '').trim().isNotEmpty) complete++;
    if (_beforeCondition != null) complete++;
    if (_draft.items.isNotEmpty) complete++;
    if ((_draft.afterImagePath ?? '').trim().isNotEmpty) complete++;
    if (_finalStatus != null) complete++;
    return complete / 5;
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard report?'),
            content: const Text('Unsubmitted collection details will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
