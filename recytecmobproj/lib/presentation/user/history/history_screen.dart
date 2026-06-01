import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/datasources/request_api.dart';
import '../../../data/models/ewaste_request_model.dart';
import '../../../data/repositories/request_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<HistoryScreen> {
  final RequestRepository _repository = RequestRepository(RequestApi());
  final tabs = const ['Pending', 'Completed', 'Cancelled'];

  late Future<List<EWasteRequestModel>> _requestsFuture;
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchMyRequests();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchMyRequests();
    setState(() {
      _requestsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('History'),
          actions: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.more_vert),
            SizedBox(width: 8),
          ],
        ),
        body: FutureBuilder<List<EWasteRequestModel>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _messageState(
                'Unable to load your request history. Please try again.',
              );
            }

            final requests = snapshot.data ?? <EWasteRequestModel>[];
            final filtered = _filteredRequests(requests);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                children: [
                  Text(
                    'My History',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: RecyTechTheme.textMuted,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Center(
                    child: Text(
                      'My Requests & Pickup History',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: RecyTechTheme.textDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Center(
                    child: Text(
                      'Track submitted e-waste requests, collection status, and payout progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: RecyTechTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _tabs(),
                  SizedBox(height: 14.h),
                  Center(
                    child: Text(
                      '${tabs[tabIndex]} Requests',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: RecyTechTheme.textDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: Text(
                      _tabDescription(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        color: RecyTechTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  if (filtered.isEmpty)
                    _emptyCard()
                  else
                    ...filtered.map(_requestCard),
                  SizedBox(height: 18.h),
                  Center(
                    child: Text(
                      '2026 RecyTech',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: RecyTechTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: Text(
                      'All rights reserved.',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: RecyTechTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == tabIndex;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(
                tabs[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.sp),
              ),
              selected: selected,
              onSelected: (_) => setState(() => tabIndex = i),
              selectedColor: RecyTechTheme.pill,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? RecyTechTheme.primary.withValues(alpha: 0.28)
                    : RecyTechTheme.border,
                width: 1.w,
              ),
              shape: const StadiumBorder(),
              labelPadding: EdgeInsets.symmetric(horizontal: 10.w),
            ),
          );
        }),
      ),
    );
  }

  List<EWasteRequestModel> _filteredRequests(
      List<EWasteRequestModel> requests) {
    return requests.where((request) {
      if (tabIndex == 1) return _isCompleted(request);
      if (tabIndex == 2) return _isCancelled(request);
      return !_isCompleted(request) && !_isCancelled(request);
    }).toList();
  }

  bool _isCompleted(EWasteRequestModel request) {
    final status = request.status.toLowerCase();
    return request.hasReleasedPayout ||
        status == 'completed' ||
        status == 'paid' ||
        status == 'reward released';
  }

  bool _isCancelled(EWasteRequestModel request) {
    final status = request.status.toLowerCase();
    return status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected';
  }

  String _tabDescription() {
    if (tabIndex == 1) {
      return 'Completed and paid requests from backend records.';
    }
    if (tabIndex == 2) {
      return 'Rejected or cancelled requests from backend records.';
    }
    return 'Requests still awaiting pickup, drop-off confirmation, or payout release.';
  }

  Widget _requestCard(EWasteRequestModel request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            color: RecyTechTheme.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _imagePreview(request.wasteImage),
          SizedBox(height: 12.h),
          _requestRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Request ID',
            value: request.requestCode,
          ),
          _divider(),
          _requestRow(
            icon: Icons.devices_other,
            label: 'E-Waste Type',
            value: request.description,
          ),
          _divider(),
          _requestRow(
            icon: Icons.event_note_outlined,
            label: 'Submission Date',
            value: _formatDate(request.createdAt),
          ),
          _divider(),
          _requestRow(
            icon: Icons.show_chart,
            label: 'Status',
            value: request.status,
          ),
          _divider(),
          _requestRow(
            icon: Icons.payments_outlined,
            label: 'Payout',
            value: request.hasReleasedPayout
                ? _formatMoney(request.monetaryValue)
                : request.payoutStatus,
          ),
          _divider(),
          _requestRow(
            icon: Icons.badge_outlined,
            label: 'Collector',
            value: request.assignedCollector.trim().isEmpty
                ? 'Not assigned'
                : request.assignedCollector,
          ),
        ],
      ),
    );
  }

  Widget _imagePreview(String image) {
    final value = image.trim();
    if (value.isEmpty) return const SizedBox.shrink();

    if (value.startsWith('data:image/')) {
      final bytes = _decodeDataImage(value);
      if (bytes == null) return const SizedBox.shrink();

      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 140.h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.network(
          value,
          width: double.infinity,
          height: 140.h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Uint8List? _decodeDataImage(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0 || commaIndex == value.length - 1) return null;

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(
        'No ${tabs[tabIndex].toLowerCase()} requests yet.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
      ),
    );
  }

  Widget _messageState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted),
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: const Divider(height: 1),
      );

  Widget _requestRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: RecyTechTheme.primary),
        SizedBox(width: 10.w),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          flex: 5,
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: RecyTechTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '-';
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _formatMoney(double value) {
    if (value <= 0) return 'Released';
    return 'PHP ${value.toStringAsFixed(2)}';
  }
}
