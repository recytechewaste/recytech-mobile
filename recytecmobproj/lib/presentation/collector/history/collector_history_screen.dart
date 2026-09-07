import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/collected_item_model.dart';
import '../../../data/repositories/collection_completion_repository.dart';
import '../../../widgets/empty_state.dart';

class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  final CollectionCompletionRepository _repository =
      ApiCollectionCompletionRepository();
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
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Collection History')),
      body: FutureBuilder<List<CollectionReportDraft>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(
                message: 'Loading collection history…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load collection history. Please try again.',
              onRetry: _refresh,
            );
          }

          final reports = snapshot.data ?? <CollectionReportDraft>[];
          if (reports.isEmpty) {
            return _state(
              icon: Icons.history,
              title: 'You have no completed collection requests yet.',
              message: 'Completed collections will appear here.',
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
          color: RecyTechTheme.card,
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
            Text('Partner Organization: ${report.lguName ?? '-'}'),
            Text('Bin: ${report.binName ?? '-'}'),
            Text('Completed: ${_formatDate(report.completedAt)}'),
            Text('Categories: ${_summaryText(report)}'),
            Text('Total quantity: ${report.totalQuantity}'),
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
                  'Qty ${item.quantity}',
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

  String _summaryText(CollectionReportDraft report) {
    if (report.confirmedCategorySummary.isEmpty) return '-';
    return report.confirmedCategorySummary.entries
        .map((entry) => '${entry.key} x ${entry.value}')
        .join(', ');
  }
}
