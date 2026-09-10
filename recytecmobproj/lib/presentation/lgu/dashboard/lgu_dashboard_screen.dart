import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';
import '../../../data/models/drop_off_record_model.dart';
import '../../../data/models/partner_organization_model.dart';
import '../../../data/repositories/bin_monitoring_repository.dart';
import '../../../data/repositories/partner_organization_repository.dart';
import '../../../data/repositories/partner_validation_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../notifications/notification_center_screen.dart';
import '../deposits/pending_dropoff_validations_screen.dart';

class LguDashboardScreen extends StatefulWidget {
  const LguDashboardScreen({
    super.key,
    this.binRepository,
    this.partnerRepository,
    this.validationRepository,
  });

  final LguBinRepository? binRepository;
  final PartnerOrganizationRepository? partnerRepository;
  final PartnerValidationRepository? validationRepository;

  @override
  State<LguDashboardScreen> createState() => _LguDashboardScreenState();
}

class _LguDashboardScreenState extends State<LguDashboardScreen> {
  late final LguBinRepository _binRepository;
  late final PartnerOrganizationRepository _partnerRepository;
  late final PartnerValidationRepository _validationRepository;
  late Future<_DashboardData> _dashboardFuture;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    _binRepository = widget.binRepository ?? ApiPartnerBinRepository();
    _partnerRepository =
        widget.partnerRepository ?? PartnerOrganizationRepository();
    _validationRepository =
        widget.validationRepository ?? ApiPartnerValidationRepository();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final results = await Future.wait([
      _binRepository.fetchAssignedBins(),
      _partnerRepository.fetchProfile(),
      _partnerRepository.fetchStats(),
      _validationRepository.fetchPendingDropOffs(),
    ]);
    return _DashboardData(
      bins: results[0] as List<RecyTechBin>,
      profile: results[1] as PartnerOrganizationProfile,
      stats: results[2] as PartnerOrganizationStats,
      pendingDropOffs: results[3] as List<DropOffRecord>,
    );
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;
    final future = _loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  Future<void> _openPendingValidations() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PendingDropOffValidationsScreen(
          repository: _validationRepository,
        ),
      ),
    );
    if (mounted && changed == true) await _refresh();
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(
                  role: UserRole.partnerOrg,
                ),
              ),
            ),
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
            return const AppLoadingState(message: 'Loading dashboard…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'We could not load your dashboard. Please try again.',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final metrics = _PartnerDashboardMetrics.fromData(data);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              key: const Key('partner-dashboard-content'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                _header(
                  data.profile.organizationName.isEmpty
                      ? 'Name unavailable'
                      : data.profile.organizationName,
                ),
                SizedBox(height: 20.h),
                Text(
                  'At a glance',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 12.h),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14.h,
                    crossAxisSpacing: 14.w,
                    childAspectRatio: 1,
                  ),
                  children: [
                    _metricCard(
                      key: const Key('metric-assigned-bins'),
                      icon: Icons.delete_outline,
                      value: metrics.assignedBins.toString(),
                      title: 'Assigned Bins Count',
                    ),
                    _metricCard(
                      key: const Key('metric-pending-validations'),
                      icon: Icons.fact_check_outlined,
                      value: metrics.pendingValidations.toString(),
                      title: 'Pending Validations',
                      actionLabel: metrics.pendingValidations > 0
                          ? 'Needs review'
                          : 'Review',
                      emphasized: metrics.pendingValidations > 0,
                      onTap: _openPendingValidations,
                    ),
                    _metricCard(
                      key: const Key('metric-validated-dropoffs'),
                      icon: Icons.verified_outlined,
                      value: metrics.validatedDropOffs.toString(),
                      title: 'Total Dropoffs Validated',
                    ),
                    _metricCard(
                      key: const Key('metric-completed-collections'),
                      icon: Icons.local_shipping_outlined,
                      value: metrics.completedCollections.toString(),
                      title: 'Completed Collections',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(String organizationName) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: RecyTechTheme.pill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.apartment_outlined,
                color: RecyTechTheme.primary,
                size: 27.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organizationName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17.sp,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Manage your assigned bins and drop-off validations.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.4,
                      color: RecyTechTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required Key key,
    required IconData icon,
    required String value,
    required String title,
    String? actionLabel,
    bool emphasized = false,
    VoidCallback? onTap,
  }) {
    final card = Container(
      key: key,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: emphasized
            ? RecyTechTheme.primary.withValues(alpha: 0.07)
            : RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emphasized
              ? RecyTechTheme.primary.withValues(alpha: 0.42)
              : RecyTechTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: RecyTechTheme.pill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19.sp, color: RecyTechTheme.primary),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: RecyTechTheme.primary,
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 25.sp,
              height: 1,
              fontWeight: FontWeight.w900,
              color:
                  emphasized ? RecyTechTheme.primary : RecyTechTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.25,
              color: RecyTechTheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionLabel != null) ...[
            SizedBox(height: 5.h),
            Text(
              actionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w900,
                color: RecyTechTheme.primary,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: '$title, $value. ${actionLabel ?? 'Review'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('pending-validations-action'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.bins,
    required this.profile,
    required this.stats,
    required this.pendingDropOffs,
  });

  final List<RecyTechBin> bins;
  final PartnerOrganizationProfile profile;
  final PartnerOrganizationStats stats;
  final List<DropOffRecord> pendingDropOffs;
}

class _PartnerDashboardMetrics {
  const _PartnerDashboardMetrics({
    required this.assignedBins,
    required this.pendingValidations,
    required this.validatedDropOffs,
    required this.completedCollections,
  });

  final int assignedBins;
  final int pendingValidations;
  final int validatedDropOffs;
  final int completedCollections;

  factory _PartnerDashboardMetrics.fromData(_DashboardData data) {
    return _PartnerDashboardMetrics(
      assignedBins: data.bins.length,
      pendingValidations: data.pendingDropOffs.length,
      validatedDropOffs: _readMetric(data.stats.values, const [
        'validatedDropOffs',
        'totalDropoffsValidated',
        'totalDropOffsValidated',
        'dropOffsValidated',
      ]),
      completedCollections: _readMetric(data.stats.values, const [
        'completedCollections',
        'totalCompletedCollections',
        'collectionsCompleted',
      ]),
    );
  }

  static int _readMetric(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is num) return value.toInt();
      final parsed = int.tryParse((value ?? '').toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
