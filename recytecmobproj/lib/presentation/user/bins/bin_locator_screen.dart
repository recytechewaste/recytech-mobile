import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../data/models/public_bin_model.dart';
import '../../../data/repositories/public_bin_repository.dart';
import '../../../services/location_service.dart';
import '../../../widgets/empty_state.dart';
import 'bin_qr_scanner_screen.dart';
import 'drop_off_form_screen.dart';

class BinLocatorScreen extends StatefulWidget {
  const BinLocatorScreen({
    super.key,
    this.repository,
    this.locationService,
  });

  final PublicBinRepository? repository;
  final LocationService? locationService;

  @override
  State<BinLocatorScreen> createState() => _BinLocatorScreenState();
}

class _BinLocatorScreenState extends State<BinLocatorScreen> {
  late final PublicBinRepository _repository;
  late final LocationService _locationService;
  final MapLauncher _mapLauncher = const MapLauncher();
  late Future<BinLocatorData> _future;
  PublicBin? _selectedBin;
  Future<void>? _refreshing;
  Map<String, double> _distanceByBinId = const {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiPublicBinRepository();
    _locationService = widget.locationService ?? const LocationService();
    _future = _loadBins();
  }

  Future<BinLocatorData> _loadBins() async {
    final locationFuture = _locationService.getCurrentLocation();
    final bins = await _repository.fetchPublicBins();
    final location = await locationFuture;
    final data = BinLocatorData.from(bins: bins, location: location);
    _distanceByBinId = {
      for (final entry in data.entries)
        if (entry.distanceMeters != null) entry.bin.id: entry.distanceMeters!,
    };
    return data;
  }

  Future<void> _refresh() async {
    final active = _refreshing;
    if (active != null) return active;

    final future = _loadBins();
    setState(() {
      _future = future;
    });
    final refresh = future.whenComplete(() {
      if (mounted) _refreshing = null;
    });
    _refreshing = refresh;
    await refresh;
  }

  Future<void> _openMaps(PublicBin bin) async {
    final opened = await _mapLauncher.open(
      MapLaunchTarget(
        label: bin.name,
        address: bin.address,
        latitude: bin.latitude,
        longitude: bin.longitude,
      ),
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No maps app is available.')),
      );
    }
  }

  Future<void> _openLocationSettings() async {
    final opened = await _locationService.openLocationSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open location settings.')),
      );
    }
  }

  Future<void> _openAppSettings() async {
    final opened = await _locationService.openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open app settings.')),
      );
    }
  }

  Future<void> _scanBinQr(PublicBin bin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BinQrScannerScreen(expectedBin: bin),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openDropOffForm(PublicBin bin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DropOffFormScreen(
          bin: bin,
          submissionMethod: 'manual',
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  void _showBinDetails(PublicBin bin) {
    final distanceMeters = _distanceFor(bin);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 18.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bin.name,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if ((bin.partnerOrganizationName ?? '').trim().isNotEmpty)
                    _detailRow(
                      Icons.apartment_outlined,
                      'Partner',
                      bin.partnerOrganizationName!,
                    ),
                  if ((bin.building ?? '').trim().isNotEmpty)
                    _detailRow(
                      Icons.business_outlined,
                      'Building',
                      bin.building!,
                    ),
                  _detailRow(
                    Icons.place_outlined,
                    'Location',
                    bin.locationLabel,
                  ),
                  _detailRow(Icons.map_outlined, 'Address', bin.address),
                  _detailRow(
                    Icons.qr_code_2_outlined,
                    'Bin code',
                    bin.displayCode,
                  ),
                  if (distanceMeters != null)
                    _detailRow(
                      Icons.near_me_outlined,
                      'Distance',
                      formatDistance(distanceMeters),
                    ),
                  if (_fullnessLabel(bin) case final fullness?)
                    _detailRow(
                      Icons.delete_outline,
                      'Fullness',
                      fullness,
                    ),
                  if (bin.acceptedCategoryLabels.isNotEmpty)
                    _detailRow(
                      Icons.check_circle_outline,
                      'Accepts',
                      bin.acceptedCategoryLabels.join(', '),
                    ),
                  if (bin.rewards.isNotEmpty)
                    _detailRow(
                      Icons.redeem_outlined,
                      'Rewards',
                      _rewardsLabel(bin),
                    ),
                  if ((bin.accessInfo ?? '').trim().isNotEmpty)
                    _detailRow(
                      Icons.schedule_outlined,
                      'Access',
                      bin.accessInfo!,
                    ),
                  if ((bin.publicStatus ?? '').trim().isNotEmpty)
                    _detailRow(
                      Icons.info_outline,
                      'Status',
                      bin.publicStatus!,
                    ),
                  _detailRow(
                    Icons.check_circle_outline,
                    'Availability',
                    bin.availabilityLabel,
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: bin.isActive
                          ? () {
                              Navigator.pop(context);
                              _openDropOffForm(bin);
                            }
                          : null,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Submit Drop-Off'),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              bin.hasCoordinates ? () => _openMaps(bin) : null,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('View location on map'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              bin.isActive ? () => _scanBinQr(bin) : null,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Bin QR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Bin Locator'),
        actions: [
          IconButton(
            tooltip: 'Refresh locations',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<BinLocatorData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading drop-off points…');
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _state(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to load drop-off points',
                message: 'Check your connection, then refresh to try again.',
                action: FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          if (data.entries.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _state(
                icon: Icons.location_off_outlined,
                title: 'No drop-off points available',
                message: 'Designated e-waste bins will appear here.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
              children: [
                _locationNotice(data.location),
                if (data.location.availability !=
                    LocationAvailability.available)
                  SizedBox(height: 14.h),
                if (data.geolocatedEntries.isEmpty)
                  _missingCoordinatesNotice()
                else
                  _mapPanel(
                    data.geolocatedEntries.map((entry) => entry.bin).toList(),
                  ),
                SizedBox(height: 14.h),
                Text(
                  data.location.availability == LocationAvailability.available
                      ? 'Nearby bins'
                      : 'Public bins',
                  style: TextStyle(
                    color: RecyTechTheme.textDark,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10.h),
                ...data.geolocatedEntries.map(_binCard),
                if (data.unlocatedEntries.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    'Location unavailable',
                    style: TextStyle(
                      color: RecyTechTheme.textDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'These bins do not have usable map coordinates.',
                    style: TextStyle(
                      color: RecyTechTheme.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...data.unlocatedEntries.map(_binCard),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _binCard(LocatedPublicBin entry) {
    final bin = entry.bin;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _selectedBin = bin);
        _showBinDetails(bin);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
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
                    bin.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                ),
                if ((bin.publicStatus ?? '').trim().isNotEmpty)
                  Chip(
                    label: Text(bin.publicStatus!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Code: ${bin.displayCode}',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: RecyTechTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (entry.distanceMeters != null)
                  Text(
                    formatDistance(entry.distanceMeters!),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              bin.locationLabel,
              style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted),
            ),
            SizedBox(height: 4.h),
            Text(
              bin.address,
              style:
                  TextStyle(fontSize: 10.5.sp, color: RecyTechTheme.textMuted),
            ),
            SizedBox(height: 6.h),
            Text(
              'Availability: ${bin.availabilityLabel}',
              style: TextStyle(
                fontSize: 10.5.sp,
                color: RecyTechTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((bin.partnerOrganizationName ?? '').trim().isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                bin.partnerOrganizationName!,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: RecyTechTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (_fullnessLabel(bin) case final fullness?) ...[
              SizedBox(height: 6.h),
              Text(
                'Fullness: $fullness',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: RecyTechTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (bin.acceptedCategoryLabels.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                'Accepts: ${bin.acceptedCategoryLabels.join(', ')}',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ],
            if (bin.rewards.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                'Rewards: ${_rewardsLabel(bin)}',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: RecyTechTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if ((bin.accessInfo ?? '').trim().isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                bin.accessInfo!,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: bin.hasCoordinates ? () => _openMaps(bin) : null,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View location on map'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: bin.isActive ? () => _scanBinQr(bin) : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPanel(List<PublicBin> bins) {
    final mappedBins = bins.where((bin) => bin.hasCoordinates).toList();
    if (mappedBins.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RecyTechTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.map_outlined, color: RecyTechTheme.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Map coordinates are not available for the listed bins.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    var selected = mappedBins.first;
    for (final bin in mappedBins) {
      if (bin.id == _selectedBin?.id) {
        selected = bin;
        break;
      }
    }
    return _OpenStreetMapBinPreview(
      bins: mappedBins,
      selectedBin: selected,
      onSelected: (bin) {
        setState(() => _selectedBin = bin);
        _showBinDetails(bin);
      },
    );
  }

  Widget _locationNotice(DeviceLocationResult location) {
    late final IconData icon;
    late final String title;
    late final String message;
    late final Widget action;

    switch (location.availability) {
      case LocationAvailability.available:
        return const SizedBox.shrink();
      case LocationAvailability.serviceDisabled:
        icon = Icons.location_disabled_outlined;
        title = 'Location services are disabled';
        message =
            'Turn on device location, then refresh to sort bins by distance.';
        action = TextButton(
          onPressed: _openLocationSettings,
          child: const Text('Location settings'),
        );
      case LocationAvailability.permissionDenied:
        icon = Icons.location_off_outlined;
        title = 'Location permission denied';
        message = 'Allow location access, then refresh to see nearby bins.';
        action = TextButton(
          onPressed: _refresh,
          child: const Text('Try again'),
        );
      case LocationAvailability.permissionDeniedForever:
        icon = Icons.location_off_outlined;
        title = 'Location permission blocked';
        message =
            'Enable location permission in app settings, then refresh this list.';
        action = TextButton(
          onPressed: _openAppSettings,
          child: const Text('App settings'),
        );
      case LocationAvailability.unavailable:
        icon = Icons.gps_off_outlined;
        title = 'Current location unavailable';
        message = 'Public bins are shown without distance. Pull down to retry.';
        action = TextButton(
          onPressed: _refresh,
          child: const Text('Try again'),
        );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: RecyTechTheme.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _missingCoordinatesNotice() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.wrong_location_outlined, color: RecyTechTheme.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'No public bins have usable location coordinates. Distances and map directions are unavailable.',
              style: TextStyle(
                fontSize: 12.sp,
                color: RecyTechTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _distanceFor(PublicBin bin) => _distanceByBinId[bin.id];

  String? _fullnessLabel(PublicBin bin) {
    final status = bin.fullnessStatus;
    final percentage = bin.fillPercentage;
    final statusLabel = status == null ? null : FullnessStatuses.label(status);
    final percentageLabel =
        percentage == null ? null : '${percentage.clamp(0, 100).round()}% full';
    if (statusLabel != null && percentageLabel != null) {
      return '$statusLabel · $percentageLabel';
    }
    return statusLabel ?? percentageLabel;
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: RecyTechTheme.primary, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textMuted,
              ),
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

  String _rewardsLabel(PublicBin bin) {
    return bin.rewards
        .map((reward) => '${reward.title} (${reward.pointsCost} pts)')
        .join(', ');
  }

  Widget _state({
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
}

class BinLocatorData {
  const BinLocatorData({required this.entries, required this.location});

  factory BinLocatorData.from({
    required List<PublicBin> bins,
    required DeviceLocationResult location,
  }) {
    final coordinates = location.coordinates;
    final entries = <LocatedPublicBin>[];
    for (var index = 0; index < bins.length; index++) {
      final bin = bins[index];
      double? distanceMeters;
      if (coordinates != null && bin.hasCoordinates) {
        distanceMeters = geographicDistanceMeters(
          coordinates.latitude,
          coordinates.longitude,
          bin.latitude!,
          bin.longitude!,
        );
      }
      entries.add(
        LocatedPublicBin(
          bin: bin,
          originalIndex: index,
          distanceMeters: distanceMeters,
        ),
      );
    }

    entries.sort((first, second) {
      if (first.bin.hasCoordinates != second.bin.hasCoordinates) {
        return first.bin.hasCoordinates ? -1 : 1;
      }
      final firstDistance = first.distanceMeters;
      final secondDistance = second.distanceMeters;
      if (firstDistance != null && secondDistance != null) {
        final distanceOrder = firstDistance.compareTo(secondDistance);
        if (distanceOrder != 0) return distanceOrder;
      }
      return first.originalIndex.compareTo(second.originalIndex);
    });

    return BinLocatorData(entries: entries, location: location);
  }

  final List<LocatedPublicBin> entries;
  final DeviceLocationResult location;

  List<LocatedPublicBin> get geolocatedEntries =>
      entries.where((entry) => entry.bin.hasCoordinates).toList();

  List<LocatedPublicBin> get unlocatedEntries =>
      entries.where((entry) => !entry.bin.hasCoordinates).toList();
}

class LocatedPublicBin {
  const LocatedPublicBin({
    required this.bin,
    required this.originalIndex,
    required this.distanceMeters,
  });

  final PublicBin bin;
  final int originalIndex;
  final double? distanceMeters;
}

String formatDistance(double distanceMeters) {
  if (distanceMeters < 1000) return '${distanceMeters.round()} m away';
  final kilometers = distanceMeters / 1000;
  final decimals = kilometers < 10 ? 1 : 0;
  return '${kilometers.toStringAsFixed(decimals)} km away';
}

class _OpenStreetMapBinPreview extends StatelessWidget {
  const _OpenStreetMapBinPreview({
    required this.bins,
    required this.selectedBin,
    required this.onSelected,
  });

  final List<PublicBin> bins;
  final PublicBin selectedBin;
  final ValueChanged<PublicBin> onSelected;

  static const int _zoom = 15;
  static const double _tileSize = 256;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 230.h,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final center = _project(
              selectedBin.latitude!,
              selectedBin.longitude!,
            );
            final topLeft = Offset(
              center.dx - size.width / 2,
              center.dy - size.height / 2,
            );
            final startX = (topLeft.dx / _tileSize).floor();
            final endX = ((topLeft.dx + size.width) / _tileSize).ceil();
            final startY = (topLeft.dy / _tileSize).floor();
            final endY = ((topLeft.dy + size.height) / _tileSize).ceil();

            final tiles = <Widget>[];
            for (var x = startX; x <= endX; x++) {
              for (var y = startY; y <= endY; y++) {
                if (y < 0 || y >= math.pow(2, _zoom)) continue;
                final wrappedX = x % math.pow(2, _zoom).toInt();
                final left = x * _tileSize - topLeft.dx;
                final top = y * _tileSize - topLeft.dy;
                tiles.add(
                  Positioned(
                    left: left,
                    top: top,
                    width: _tileSize,
                    height: _tileSize,
                    child: Image.network(
                      'https://tile.openstreetmap.org/$_zoom/$wrappedX/$y.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE8EFEA),
                      ),
                    ),
                  ),
                );
              }
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xFFE8EFEA),
                    child: Stack(children: tiles),
                  ),
                ),
                ...bins.map((bin) => _marker(bin, topLeft)),
                Positioned(
                  left: 8.w,
                  right: 8.w,
                  bottom: 8.h,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          color: RecyTechTheme.card.withValues(alpha: 0.92),
                          child: Text(
                            selectedBin.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: RecyTechTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 5.h,
                        ),
                        color: RecyTechTheme.card.withValues(alpha: 0.92),
                        child: Text(
                          'OpenStreetMap',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: RecyTechTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _marker(PublicBin bin, Offset topLeft) {
    final point = _project(bin.latitude!, bin.longitude!);
    final left = point.dx - topLeft.dx;
    final top = point.dy - topLeft.dy;
    final isSelected = bin.id == selectedBin.id;
    return Positioned(
      left: left - 18,
      top: top - 38,
      width: 36,
      height: 42,
      child: Tooltip(
        message: bin.name,
        child: GestureDetector(
          onTap: () => onSelected(bin),
          child: Icon(
            Icons.location_pin,
            size: isSelected ? 38 : 32,
            color: isSelected ? RecyTechTheme.primary : Colors.redAccent,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Offset _project(double latitude, double longitude) {
    final scale = _tileSize * math.pow(2, _zoom);
    final sinLatitude =
        math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
    final x = (longitude + 180) / 360 * scale;
    final y = (0.5 -
            math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) *
        scale;
    return Offset(x, y);
  }
}
