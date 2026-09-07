import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  late final String _idempotencyKey;
  String? _selectedCategory;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiDropOffRepository();
    _quantityController = TextEditingController(text: '1');
    _selectedCategory = widget.bin.acceptedCategories.isNotEmpty
        ? widget.bin.acceptedCategories.first
        : null;
    _idempotencyKey =
        '${widget.submissionMethod}-${widget.bin.publicQrCode}-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final category = _selectedCategory;
    final quantity = int.tryParse(_quantityController.text.trim());
    if (category == null || category.isEmpty) {
      setState(() => _errorMessage = 'Please select an accepted category.');
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() =>
          _errorMessage = 'Quantity must be a whole number greater than 0.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final record = await _repository.registerDropOff(
        bin: widget.bin,
        submissionMethod: widget.submissionMethod,
        idempotencyKey: _idempotencyKey,
        items: [
          DropOffSubmissionItem(category: category, quantity: quantity),
        ],
      );
      if (!mounted) return;
      await _showSuccess(record);
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

  Future<void> _showSuccess(DropOffRecord record) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Drop-off submitted successfully.'),
          content: Text(
            '${record.binName}\n${_itemsLabel(record)}\nReward processing will be handled in a later update.',
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
    final categoryOptions = widget.bin.acceptedCategories;

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
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
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
    final index = widget.bin.acceptedCategories.indexOf(category);
    if (index >= 0 && index < widget.bin.acceptedCategoryLabels.length) {
      return widget.bin.acceptedCategoryLabels[index];
    }
    return _displayCategory(category);
  }

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
