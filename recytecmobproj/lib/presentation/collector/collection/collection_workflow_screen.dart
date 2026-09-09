import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/waste_type_mapper.dart';
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
  final CollectionCompletionRepository _completionRepository =
      ApiCollectionCompletionRepository();

  final CollectorRepository _collectorRepository = CollectorRepository();

  late final CollectionReportDraft _draft;

  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().currentUser;

    _draft = CollectionReportDraft(
      assignmentId: widget.job.id,
      requestReference: widget.job.requestCode,
      collectorId: user?.profileId,
      collectorName:
          user?.fullName.trim().isNotEmpty == true ? user!.fullName.trim() : '',
      lguName: widget.job.partnerOrganizationName,
      binId: widget.job.binId,
      binName: widget.job.displayItem,
      binLocation: widget.job.location,
    );
  }

  Future<void> _addItem() async {
    final item = await Navigator.push<CollectedEWasteItem>(
      context,
      MaterialPageRoute(
        builder: (_) => const CollectorEWasteCaptureScreen(),
      ),
    );

    if (item == null || !mounted) return;

    setState(() {
      _draft.items.add(item);
    });
  }

  Future<void> _editItem(CollectedEWasteItem item) async {
    final index = _draft.items.indexOf(item);

    if (index < 0) return;

    final updated = await Navigator.push<CollectedEWasteItem>(
      context,
      MaterialPageRoute(
        builder: (_) => CollectorEWasteCaptureScreen(
          initialItem: item,
        ),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      _draft.items[index] = updated;
    });
  }

  void _removeItem(CollectedEWasteItem item) {
    setState(() {
      _draft.items.remove(item);
    });
  }

  Future<void> _complete() async {
    if (_isSubmitting) return;

    if (!_draft.canSubmit) {
      setState(() {
        _message =
            'Each collected item requires a category, non-negative quantity, and unit.';
      });

      return;
    }

    final confirmed = await _confirmCompletion();

    if (!confirmed) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final completedJob =
          await _completionRepository.submitCollectionReport(_draft);

      if (!completedJob.isCompleted) {
        throw const FormatException(
          'Completion response did not include completed request status.',
        );
      }

      try {
        await Future.wait([
          _collectorRepository.fetchProfile(),
          _collectorRepository.fetchStats(),
        ]);
      } catch (_) {
        // Collection completion already succeeded.
        // Summary/profile refresh can retry later.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection completed.'),
        ),
      );

      Navigator.pop(context, completedJob);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = userFacingError(
          error,
          fallback: 'Completion failed. Please retry.',
        );

        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnsaved = _draft.items.isNotEmpty;

    return PopScope(
      canPop: !hasUnsaved || _isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isSubmitting) return;

        final discard = await _confirmDiscard();

        if (discard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Collection Report'),
        ),
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _stepHeader(),
            SizedBox(height: 12.h),
            _itemsSection(),
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
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
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
          Text(
            widget.job.requestCode,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.job.location.isEmpty ? '-' : widget.job.location,
          ),
          SizedBox(height: 10.h),
          LinearProgressIndicator(
            value: _progress(),
          ),
        ],
      ),
    );
  }

  Widget _itemsSection() {
    return _panel(
      title: 'Collected Items',
      trailing: OutlinedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Scan / Capture E-Waste'),
      ),
      children: [
        if (_draft.items.isEmpty)
          Text(
            'No e-waste items scanned or captured yet.',
            style: TextStyle(
              color: RecyTechTheme.textMuted,
              fontSize: 11.sp,
            ),
          )
        else
          ..._draft.items.map(_itemTile),
        SizedBox(height: 8.h),
        Text(
          'Categories: ${_draft.totalCategories}   '
          'Total quantity: ${_draft.totalQuantity}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _reviewSection() {
    return _panel(
      title: 'Review',
      children: [
        _reviewRow(
          'Request',
          _draft.requestReference,
        ),
        _reviewRow(
          'Collector',
          _draft.collectorName,
        ),
        _reviewRow(
          'Bin / Item',
          widget.job.displayItem,
        ),
        _reviewRow(
          'Location',
          widget.job.location,
        ),
        _reviewRow(
          'Total quantity',
          _draft.totalQuantity.toString(),
        ),
        SizedBox(height: 4.h),
        ..._draft.confirmedCategorySummary.entries.map(
          (entry) => _reviewRow(
            WasteTypeMapper.toBackendWasteType(
              entry.key,
            ),
            entry.value.toString(),
          ),
        ),
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
      title: Text(
        item.mappedCategory,
      ),
      subtitle: Text(
        'AI: ${item.aiPredictedClass ?? '-'} '
        '(${((item.aiConfidence ?? 0) * 100).toStringAsFixed(1)}%)\n'
        'Confirmed: ${item.confirmedClass}\n'
        'Qty ${item.quantity}, ${item.condition ?? 'Unknown'}',
      ),
      trailing: Wrap(
        spacing: 4.w,
        children: [
          IconButton(
            tooltip: 'Edit item',
            onPressed: () {
              _editItem(item);
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: () {
              _removeItem(item);
            },
            icon: const Icon(
              Icons.delete_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(
    String message,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.danger.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: RecyTechTheme.danger.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: RecyTechTheme.danger,
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: RecyTechTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: RecyTechTheme.border,
      ),
    );
  }

  double _progress() {
    return _draft.items.isEmpty ? 0 : 1;
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Discard report?',
            ),
            content: const Text(
              'Unsubmitted collection details will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child: const Text(
                  'Keep Editing',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text(
                  'Discard',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmCompletion() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Complete collection?',
            ),
            content: Text(
              'Submit ${_draft.items.length} scanned item record(s) with '
              '${_draft.totalQuantity} total item(s) for backend analytics.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child: const Text(
                  'Review Again',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text(
                  'Complete Collection',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
