import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../data/models/public_bin_model.dart';
import '../../../data/repositories/public_bin_repository.dart';
import '../../../widgets/empty_state.dart';

class BinLocatorScreen extends StatefulWidget {
  const BinLocatorScreen({super.key});

  @override
  State<BinLocatorScreen> createState() => _BinLocatorScreenState();
}

class _BinLocatorScreenState extends State<BinLocatorScreen> {
  final PublicBinRepository _repository = MockPublicBinRepository();
  final MapLauncher _mapLauncher = const MapLauncher();
  late Future<List<PublicBin>> _future;

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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _state(
              icon: Icons.error_outline,
              title: 'Unable to load drop-off points',
              message: 'Check your connection and try again.',
              action: OutlinedButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
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
              children: bins.map(_binCard).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _binCard(PublicBin bin) {
    return Container(
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
            bin.address,
            style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openMaps(bin),
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Get Directions'),
            ),
          ),
        ],
      ),
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
}
