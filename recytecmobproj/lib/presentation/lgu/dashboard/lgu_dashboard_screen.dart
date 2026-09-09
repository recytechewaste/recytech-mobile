import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/models/partner_organization_model.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../data/repositories/partner_organization_repository.dart';
import '../../../presentation/bin_monitoring/widgets/bin_monitoring_components.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_bagde.dart';
import '../../notifications/notification_center_screen.dart';
import '../bins/bin_details_screen.dart';

class LguDashboardScreen extends StatefulWidget {
  const LguDashboardScreen({super.key});

  @override
  State<LguDashboardScreen> createState() => _LguDashboardScreenState();
}

class _LguDashboardScreenState extends State<LguDashboardScreen> {
  final LguBinRepository _binRepository = ApiPartnerBinRepository();
  final PartnerOrganizationRepository _partnerRepository =
      PartnerOrganizationRepository();

  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final results = await Future.wait([
      _binRepository.fetchAssignedBins(),
      _partnerRepository.fetchProfile(),
      _partnerRepository.fetchStats(),
    ]);
    return _DashboardData(
      bins: results[0] as List<RecyTechBin>,
      profile: results[1] as PartnerOrganizationProfile,
      stats: results[2] as PartnerOrganizationStats,
    );
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(
                    role: UserRole.partnerOrg,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
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
            return const AppLoadingState(message: 'Loading smart bin summary…');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load smart bin data. Please try again.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final metrics = <String, dynamic>{
            ...data.profile.overview,
            ...data.stats.values,
          };

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _header(data.profile.organizationName.isEmpty
                    ? 'Partner Organization'
                    : data.profile.organizationName),
                SizedBox(height: 14.h),
                if (metrics.isNotEmpty)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 10.w,
                    childAspectRatio: 1.35,
                    children: metrics.entries
                        .map((entry) => _metric(
                            _metricLabel(entry.key), _display(entry.value)))
                        .toList(growable: false),
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
                if (data.bins.isEmpty)
                  const EmptyState(
                    icon: Icons.delete_outline,
                    title: 'You have no assigned smart bins right now.',
                    message: 'Assigned RecyTech smart bins will appear here.',
                  )
                else if (data.priorityBins.isEmpty)
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
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
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
                  'Latest stored bin readings from the RecyTech backend.',
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
        color: RecyTechTheme.card,
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

  String _metricLabel(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');

  String _display(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }
    if (value is List) return value.join(', ');
    return value.toString();
  }
}

class _DashboardData {
  const _DashboardData({
    required this.bins,
    required this.profile,
    required this.stats,
  });

  final List<RecyTechBin> bins;
  final PartnerOrganizationProfile profile;
  final PartnerOrganizationStats stats;

  List<RecyTechBin> get priorityBins {
    return bins.where((bin) {
      final status = FullnessStatuses.normalize(bin.fullnessStatus);
      return status == FullnessStatuses.full ||
          status == FullnessStatuses.nearlyFull;
    }).toList();
  }
}
