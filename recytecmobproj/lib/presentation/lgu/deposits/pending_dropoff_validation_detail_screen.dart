import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/repositories/partner_validation_repository.dart';
import 'partner_dropoff_widgets.dart';

class PendingDropOffValidationDetailScreen extends StatefulWidget {
  const PendingDropOffValidationDetailScreen({
    super.key,
    required this.record,
    required this.repository,
  });

  final DropOffRecord record;
  final PartnerValidationRepository repository;

  @override
  State<PendingDropOffValidationDetailScreen> createState() =>
      _PendingDropOffValidationDetailScreenState();
}

class _PendingDropOffValidationDetailScreenState
    extends State<PendingDropOffValidationDetailScreen> {
  bool _isValidating = false;

  Future<void> _review() async {
    if (_isValidating) return;
    final decision = await showModalBottomSheet<_ValidationDecision>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ValidationSheet(),
    );
    if (decision == null || _isValidating) return;

    setState(() => _isValidating = true);
    try {
      await widget.repository.validateDropOff(
        widget.record.id,
        action: decision.action,
        validationNotes: decision.notes,
      );
      if (!mounted) return;
      Navigator.pop(context, decision.action);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validation could not be completed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Review Drop-Off')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                children: [
                  _summary(record),
                  SizedBox(height: 14.h),
                  PartnerDropOffImage(
                    source: record.imageUrls.firstOrNull,
                    width: double.infinity,
                    height: 250.h,
                    borderRadius: 16,
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Drop-off details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: _details(record),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
              decoration: BoxDecoration(
                color: RecyTechTheme.card,
                border: Border(top: BorderSide(color: RecyTechTheme.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('validate-dropoff-button'),
                  onPressed: _isValidating ? null : _review,
                  icon: _isValidating
                      ? SizedBox.square(
                          dimension: 18.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _isValidating ? 'Validating…' : 'Validate Drop-Off',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(DropOffRecord record) => Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dropOffCategory(record),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: RecyTechTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      dropOffDate(record.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: RecyTechTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: RecyTechTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: RecyTechTheme.warning,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  List<Widget> _details(DropOffRecord record) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Category', dropOffCategory(record)),
      MapEntry('Quantity', dropOffQuantity(record)),
      MapEntry('Bin', record.binName),
      if ((record.locationDescription ?? '').trim().isNotEmpty)
        MapEntry('Location', record.locationDescription!.trim()),
      if ((record.householdName ?? '').trim().isNotEmpty)
        MapEntry('Household', record.householdName!.trim()),
      if ((record.householdEmail ?? '').trim().isNotEmpty)
        MapEntry('Email', record.householdEmail!.trim()),
      if ((record.notes ?? '').trim().isNotEmpty)
        MapEntry('Notes', record.notes!.trim()),
      if (record.pointsProjected != null && record.pointsProjected! > 0)
        MapEntry('Projected points', record.pointsProjected.toString()),
      if (record.pointsAwarded > 0)
        MapEntry('Awarded points', record.pointsAwarded.toString()),
    ];
    return [
      for (var index = 0; index < rows.length; index++) ...[
        _detailRow(rows[index].key, rows[index].value),
        if (index != rows.length - 1)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(height: 1, color: RecyTechTheme.border),
          ),
      ],
    ];
  }

  Widget _detailRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: RecyTechTheme.textDark,
              ),
            ),
          ),
        ],
      );
}

class _ValidationSheet extends StatefulWidget {
  const _ValidationSheet();

  @override
  State<_ValidationSheet> createState() => _ValidationSheetState();
}

class _ValidationSheetState extends State<_ValidationSheet> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit(String action) => Navigator.pop(
        context,
        _ValidationDecision(action: action, notes: _notesController.text),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          4.h,
          20.w,
          MediaQuery.viewInsetsOf(context).bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm validation',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: RecyTechTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Review the submitted item before approving or rejecting it.',
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.4,
                  color: RecyTechTheme.textMuted,
                ),
              ),
              SizedBox(height: 18.h),
              TextField(
                controller: _notesController,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Validation notes (optional)',
                  hintText: 'Add a short note for this decision',
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('approve-dropoff-button'),
                  onPressed: () => _submit('approve'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve Drop-Off'),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('reject-dropoff-button'),
                  onPressed: () => _submit('reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RecyTechTheme.danger,
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reject Drop-Off'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidationDecision {
  const _ValidationDecision({required this.action, required this.notes});

  final String action;
  final String notes;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
