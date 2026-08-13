import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/collected_item_model.dart';
import '../../../data/repositories/collection_completion_repository.dart';
import '../../../services/auth_provider.dart';
import '../../../widgets/empty_state.dart';

class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  final CollectionCompletionRepository _repository =
      MockCollectionCompletionRepository();
  late Future<List<CollectionReportDraft>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchCompletedReports();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchCompletedReports();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Collection History')),
      body: FutureBuilder<List<CollectionReportDraft>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _state(
              icon: Icons.error_outline,
              title: 'Unable to load history',
              action: OutlinedButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            );
          }

          final reports = (snapshot.data ?? <CollectionReportDraft>[])
              .where((report) =>
                  user == null || report.collectorName == user.fullName)
              .toList();
          if (reports.isEmpty) {
            return _state(
              icon: Icons.history,
              title: 'No completed collections',
              message: 'Completed collection reports will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: reports.map(_reportCard).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _reportCard(CollectionReportDraft report) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showReport(report),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RecyTechTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.requestReference,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6.h),
            Text('LGU: ${report.lguName ?? '-'}'),
            Text('Bin: ${report.binName ?? '-'}'),
            Text('Completed: ${_formatDate(report.completedAt)}'),
            Text('Categories: ${report.totalCategories}'),
            Text('Quantity: ${report.totalQuantity}'),
            Text('Weight: ${report.totalWeightKg.toStringAsFixed(2)} kg'),
            Text('Final status: ${report.finalBinStatus ?? '-'}'),
          ],
        ),
      ),
    );
  }

  void _showReport(CollectionReportDraft report) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text(
              report.requestReference,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12.h),
            ...report.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.mappedCategory),
                subtitle: Text(
                  'AI: ${item.aiPredictedClass ?? '-'}\n'
                  'Confirmed: ${item.confirmedClass}\n'
                  'Qty ${item.quantity}, ${item.weightKg.toStringAsFixed(2)} kg',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
  }) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        EmptyState(
          icon: icon,
          title: title,
          message: message,
          action: action,
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
