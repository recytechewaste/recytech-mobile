import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../data/models/public_bin_model.dart';
import '../../../data/repositories/public_bin_repository.dart';
import '../../../widgets/empty_state.dart';
import 'bin_qr_scanner_screen.dart';
import 'drop_off_form_screen.dart';

class BinLocatorScreen extends StatefulWidget {
  const BinLocatorScreen({super.key});

  @override
  State<BinLocatorScreen> createState() => _BinLocatorScreenState();
}

class _BinLocatorScreenState extends State<BinLocatorScreen> {
  final PublicBinRepository _repository = ApiPublicBinRepository();
  final MapLauncher _mapLauncher = const MapLauncher();
  late Future<List<PublicBin>> _future;
  PublicBin? _selectedBin;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchPublicBins();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchPublicBins();
    setState(() => _future = future);
    await future;
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

  Future<void> _scanBinQr(PublicBin bin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BinQrScannerScreen(expectedBin: bin),
      ),
    );
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
  }

  void _showBinDetails(PublicBin bin) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
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
                _detailRow(
                  Icons.apartment_outlined,
                  'Partner',
                  bin.partnerOrganizationName ?? '-',
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
                  bin.locationDescription ?? bin.address,
                ),
                _detailRow(Icons.map_outlined, 'Address', bin.address),
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
                        onPressed: () => _openMaps(bin),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View location on map'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: bin.isActive ? () => _scanBinQr(bin) : null,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Bin QR'),
                      ),
                    ),
                  ],
                ),
              ],
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
      body: FutureBuilder<List<PublicBin>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading drop-off points…');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load drop-off points. Please try again.',
              onRetry: _refresh,
            );
          }

          final bins = snapshot.data ?? <PublicBin>[];
          if (bins.isEmpty) {
            return _state(
              icon: Icons.location_off_outlined,
              title: 'No drop-off points available',
              message: 'Designated e-waste bins will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _mapPanel(bins),
                SizedBox(height: 14.h),
                ...bins.map(_binCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _binCard(PublicBin bin) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _selectedBin = bin);
        _showBinDetails(bin);
      },
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
            SizedBox(height: 8.h),
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
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(bin),
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
        padding: EdgeInsets.all(14.w),
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

    final selected =
        _selectedBin?.hasCoordinates == true ? _selectedBin : mappedBins.first;
    return _OpenStreetMapBinPreview(
      bins: mappedBins,
      selectedBin: selected!,
      onSelected: (bin) {
        setState(() => _selectedBin = bin);
        _showBinDetails(bin);
      },
    );
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
