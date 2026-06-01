import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/datasources/request_api.dart';
import 'package:recytecmobproj/data/models/ewaste_request_model.dart';
import 'package:recytecmobproj/data/repositories/request_repository.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RequestRepository _repository = RequestRepository(RequestApi());
  late Future<_PayoutHistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadPayoutHistory();
  }

  Future<_PayoutHistoryData> _loadPayoutHistory() async {
    final requestsFuture = _repository.fetchMyRequests();
    final transactionsFuture = _repository.fetchMyTransactions();

    return _PayoutHistoryData(
      requests: await requestsFuture,
      transactions: await transactionsFuture,
    );
  }

  Future<void> _refresh() async {
    final future = _loadPayoutHistory();
    setState(() {
      _historyFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Payout History'),
        ),
        body: FutureBuilder<_PayoutHistoryData>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _messageState(
                'Unable to load payout history. Please try again.',
              );
            }

            final data = snapshot.data ?? const _PayoutHistoryData();
            final rows = _buildRows(data);
            final releasedTotal = data.transactions.fold<double>(
              0,
              (sum, tx) => sum + _asDouble(tx['amount']),
            );

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                children: [
                  Text(
                    'Monetary Rewards',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Released payouts and pending reward status from your real recycling requests.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: RecyTechTheme.textMuted,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _summaryCard(releasedTotal, data.pendingPayoutCount),
                  SizedBox(height: 22.h),
                  Text(
                    'Payout records',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (rows.isEmpty) _emptyCard() else ...rows.map(_historyRow),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_PayoutRow> _buildRows(_PayoutHistoryData data) {
    final rows = <_PayoutRow>[];

    for (final tx in data.transactions) {
      final request = _asMap(tx['requestId']);
      final requestId = (request['_id'] ?? tx['requestId'] ?? '').toString();
      rows.add(
        _PayoutRow(
          title: '${_requestCode(requestId)} - ${_displayItem(request, tx)}',
          subtitle: _formatDate(
            (tx['releasedAt'] ?? tx['createdAt'] ?? '').toString(),
            fallback: 'Released',
          ),
          amount: _formatMoney(_asDouble(tx['amount'])),
          status: (tx['status'] ?? 'Released').toString(),
          released: true,
        ),
      );
    }

    final releasedRequestIds = data.transactions
        .map((tx) => _asMap(tx['requestId'])['_id'] ?? tx['requestId'])
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final request in data.requests) {
      if (request.hasReleasedPayout ||
          releasedRequestIds.contains(request.id)) {
        continue;
      }

      if (!_isPendingPayoutRequest(request)) continue;

      rows.add(
        _PayoutRow(
          title: '${request.requestCode} - ${request.description}',
          subtitle: _formatDate(request.updatedAt, fallback: request.status),
          amount: request.monetaryValue > 0
              ? _formatMoney(request.monetaryValue)
              : 'Pending',
          status: _pendingPayoutLabel(request),
          released: false,
        ),
      );
    }

    return rows;
  }

  bool _isPendingPayoutRequest(EWasteRequestModel request) {
    final status = request.status.toLowerCase();
    return status == 'collected' ||
        status == 'drop-off confirmed' ||
        status == 'received' ||
        request.payoutStatus.toLowerCase() == 'pending' ||
        request.payoutStatus.toLowerCase() == 'processing';
  }

  String _pendingPayoutLabel(EWasteRequestModel request) {
    final status = request.status.toLowerCase();
    if (status == 'collected') return 'Awaiting drop-off confirmation';
    if (status == 'drop-off confirmed' || status == 'received') {
      return 'Ready for payout';
    }
    return request.payoutStatus;
  }

  Widget _summaryCard(double releasedTotal, int pendingCount) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Row(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: RecyTechTheme.pill,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: RecyTechTheme.primary,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Released',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatMoney(releasedTotal),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$pendingCount payout${pendingCount == 1 ? '' : 's'} pending confirmation or release.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: RecyTechTheme.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(_PayoutRow row) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  row.subtitle,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  row.status,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: row.released
                        ? RecyTechTheme.primary
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            row.amount,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: row.released
                  ? RecyTechTheme.primary
                  : RecyTechTheme.textMuted,
            ),
          ),
        ],
      ),
    );
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
        'No payout history yet.',
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  String _displayItem(Map<String, dynamic> request, Map<String, dynamic> tx) {
    return (request['itemCategory'] ??
            request['detectedClass'] ??
            request['wasteType'] ??
            tx['wasteType'] ??
            'E-waste item')
        .toString();
  }

  String _requestCode(String id) {
    final clean = id.trim();
    if (clean.isEmpty) return 'Request';
    return 'REQ-${clean.substring(0, clean.length < 6 ? clean.length : 6).toUpperCase()}';
  }

  String _formatMoney(double value) => 'PHP ${value.toStringAsFixed(2)}';

  String _formatDate(String value, {required String fallback}) {
    final date = DateTime.tryParse(value);
    if (date == null) return fallback;
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _PayoutHistoryData {
  const _PayoutHistoryData({
    this.requests = const <EWasteRequestModel>[],
    this.transactions = const <Map<String, dynamic>>[],
  });

  final List<EWasteRequestModel> requests;
  final List<Map<String, dynamic>> transactions;

  int get pendingPayoutCount => requests.where((request) {
        final status = request.status.toLowerCase();
        return !request.hasReleasedPayout &&
            (status == 'collected' ||
                status == 'drop-off confirmed' ||
                status == 'received' ||
                request.payoutStatus.toLowerCase() == 'pending' ||
                request.payoutStatus.toLowerCase() == 'processing');
      }).length;
}

class _PayoutRow {
  const _PayoutRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.released,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final bool released;
}
