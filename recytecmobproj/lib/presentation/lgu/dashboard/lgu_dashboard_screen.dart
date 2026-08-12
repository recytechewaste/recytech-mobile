import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../data/repositories/collection_request_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../services/auth_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';
import '../bins/bin_details_screen.dart';

class LguDashboardScreen extends StatefulWidget {
  const LguDashboardScreen({super.key});

  @override
  State<LguDashboardScreen> createState() => _LguDashboardScreenState();
}

class _LguDashboardScreenState extends State<LguDashboardScreen> {
  final LguBinRepository _binRepository = MockBinMonitoringService();
  final CollectionRequestRepository _requestRepository =
      MockCollectionRequestRepository();

  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final results = await Future.wait([
      _binRepository.fetchAssignedBins(),
      _requestRepository.fetchCollectionRequests(),
    ]);
    return _DashboardData(
      bins: results[0] as List<RecyTechBin>,
      requests: results[1] as List<CollectionRequestSummary>,
    );
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final lguName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'LGU';

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorState();
          }

          final data = snapshot.data ?? const _DashboardData();
          final activeRequests = data.requests
              .where((request) => CollectionRequestStatuses.isActive(
                    request.status,
                  ))
              .length;
          final completed = data.requests
              .where((request) =>
                  CollectionRequestStatuses.normalize(request.status) ==
                  CollectionRequestStatuses.completed)
              .length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _header(lguName),
                SizedBox(height: 14.h),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 1.35,
                  children: [
                    _metric('Assigned Bins', data.bins.length.toString()),
                    _metric('Full', _countBins(data.bins, FullnessStatuses.full)),
                    _metric(
                      'Nearly Full',
                      _countBins(data.bins, FullnessStatuses.nearlyFull),
                    ),
                    _metric('Active Requests', activeRequests.toString()),
                    _metric('Completed', completed.toString()),
                  ],
                ),
                SizedBox(height: 18.h),
                Text(
                  'Priority bins',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 10.h),
                if (data.priorityBins.isEmpty)
                  const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No priority bins',
                    message: 'No full or nearly full bins are pending review.',
                  )
                else
                  for (final bin in data.priorityBins) _priorityBin(bin),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(String lguName) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              color: RecyTechTheme.pill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_city_outlined,
              color: RecyTechTheme.primary,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lguName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'ToF bin readings shown from temporary mock repository.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: RecyTechTheme.primary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: RecyTechTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityBin(RecyTechBin bin) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BinDetailsScreen(binId: bin.binId)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    bin.displayName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: RecyTechTheme.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusBadge(label: FullnessStatuses.label(bin.fullnessStatus)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              bin.location,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
            SizedBox(height: 10.h),
            FillLevelIndicator(
              fillLevel: bin.fillPercentage,
              status: FullnessStatuses.label(bin.fullnessStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load dashboard',
          message: 'Check the connection and try again.',
          action: OutlinedButton(
            onPressed: _refresh,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  String _countBins(List<RecyTechBin> bins, String status) {
    return bins
        .where((bin) => FullnessStatuses.normalize(bin.fullnessStatus) == status)
        .length
        .toString();
  }
}

class _DashboardData {
  const _DashboardData({
    this.bins = const <RecyTechBin>[],
    this.requests = const <CollectionRequestSummary>[],
  });

  final List<RecyTechBin> bins;
  final List<CollectionRequestSummary> requests;

  List<RecyTechBin> get priorityBins {
    return bins.where((bin) {
      final status = FullnessStatuses.normalize(bin.fullnessStatus);
      return status == FullnessStatuses.full ||
          status == FullnessStatuses.nearlyFull;
    }).toList();
  }
}
