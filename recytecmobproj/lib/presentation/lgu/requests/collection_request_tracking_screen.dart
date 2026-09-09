import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/collection_request_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';

class CollectionRequestTrackingScreen extends StatefulWidget {
  const CollectionRequestTrackingScreen({super.key});

  @override
  State<CollectionRequestTrackingScreen> createState() =>
      _CollectionRequestTrackingScreenState();
}

class _CollectionRequestTrackingScreenState
    extends State<CollectionRequestTrackingScreen> {
  final CollectionRequestRepository _repository =
      ApiCollectionRequestRepository();
  late Future<List<CollectionRequestSummary>> _requestsFuture;
  String _filter = 'active';

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchCollectionRequests();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchCollectionRequests();
    setState(() => _requestsFuture = future);
    await future;
  }

  List<CollectionRequestSummary> _filtered(
    List<CollectionRequestSummary> requests,
  ) {
    if (_filter == 'all') return requests;
    if (_filter == 'active') {
      return requests
          .where((request) => RequestStatuses.isActive(request.status))
          .toList();
    }
    return requests
        .where(
            (request) => RequestStatuses.normalize(request.status) == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh requests',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<CollectionRequestSummary>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(
                message: 'Loading collection requests…');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load collection requests. Please try again.',
              onRetry: _refresh,
            );
          }

          final allRequests =
              snapshot.data ?? const <CollectionRequestSummary>[];
          final requests = _filtered(allRequests);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _filterBar(),
                SizedBox(height: 12.h),
                if (requests.isEmpty)
                  EmptyState(
                    icon: Icons.assignment_outlined,
                    title: _emptyTitle(allRequests),
                    message: _emptyMessage(allRequests),
                  )
                else
                  for (final request in requests) _requestCard(request),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    final filters = <MapEntry<String, String>>[
      const MapEntry('active', 'Active'),
      const MapEntry('all', 'All'),
      ...RequestStatuses.values.map(
        (status) => MapEntry(status, RequestStatuses.label(status)),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: _filter == entry.key,
              onSelected: (_) => setState(() => _filter = entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _requestCard(CollectionRequestSummary request) {
    final statusLabel = RequestStatuses.label(request.status);

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  request.id,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
              ),
              StatusBadge(label: statusLabel),
            ],
          ),
          SizedBox(height: 8.h),
          _info('Bin', request.binName ?? request.binId),
          _info('Location', request.location),
          _info('Requested', formatDateTime(request.requestedAt)),
          _info(
            'Fill',
            request.fillPercentage == null
                ? '-'
                : '${request.fillPercentage!.round()}%',
          ),
          _info(
            'Status',
            request.fullnessStatus == null
                ? '-'
                : FullnessStatuses.label(request.fullnessStatus),
          ),
          _info('Collector', request.assignedCollectorName ?? '-'),
          _info('Started', formatDateTime(request.startedAt)),
          if (RequestStatuses.normalize(request.status) ==
              RequestStatuses.completed) ...[
            _info('Completed', formatDateTime(request.completedAt)),
            _info('Collected', request.completionItemSummaryText ?? '-'),
            _info(
              'Quantity',
              request.completionTotalQuantity?.toString() ?? '-',
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyTitle(List<CollectionRequestSummary> allRequests) {
    if (_filter == RequestStatuses.completed) {
      return 'You have no completed collection requests yet.';
    }
    if (_filter == 'active' || (_filter == 'all' && allRequests.isEmpty)) {
      return 'You have no active collection requests right now.';
    }
    return 'No collection requests match this status.';
  }

  String? _emptyMessage(List<CollectionRequestSummary> allRequests) {
    if (_filter == RequestStatuses.completed) return null;
    if (_filter == 'active' || (_filter == 'all' && allRequests.isEmpty)) {
      return 'Collection requests you submit will appear here.';
    }
    return null;
  }
}
