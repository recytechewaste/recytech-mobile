import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_qr_payload_model.dart';
import '../../../data/models/public_bin_model.dart';
import '../../../data/repositories/drop_off_repository.dart';
import 'drop_off_form_screen.dart';

class BinQrScannerScreen extends StatefulWidget {
  const BinQrScannerScreen({
    super.key,
    this.expectedBin,
    this.repository,
  });

  final PublicBin? expectedBin;
  final DropOffRepository? repository;

  @override
  State<BinQrScannerScreen> createState() => _BinQrScannerScreenState();
}

class _BinQrScannerScreenState extends State<BinQrScannerScreen> {
  late final MobileScannerController _controller;
  late final DropOffRepository _repository;

  bool _isHandlingScan = false;
  String? _message;
  PublicBin? _validatedBin;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiDropOffRepository();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_isHandlingScan || _validatedBin != null) return;

    final rawValue = _firstQrValue(capture);
    if (rawValue == null) return;

    setState(() {
      _isHandlingScan = true;
      _message = 'Validating RecyTech bin QR...';
    });
    await _controller.stop();

    try {
      final payload = BinQrPayload.parse(rawValue);
      final bin = await _repository.validateBinQr(payload);
      if (!mounted) return;
      setState(() {
        _validatedBin = bin;
        _message = null;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _message =
            'Invalid RecyTech QR. Scan the QR code attached to a designated RecyTech bin.';
        _isHandlingScan = false;
      });
    } on DropOffRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _isHandlingScan = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'Unable to validate this bin QR. Check your connection and try again.';
        _isHandlingScan = false;
      });
    }
  }

  String? _firstQrValue(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) return raw;
    }
    return null;
  }

  Future<void> _retryScan() async {
    setState(() {
      _isHandlingScan = false;
      _message = null;
      _validatedBin = null;
    });
    try {
      await _controller.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Camera could not restart. Close this screen and try again.';
      });
    }
  }

  Future<void> _openDropOffForm() async {
    final bin = _validatedBin;
    if (bin == null) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DropOffFormScreen(
          bin: bin,
          submissionMethod: 'qr',
          repository: _repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Bin QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _handleCapture,
            errorBuilder: (context, error) {
              return _cameraError(error);
            },
          ),
          _scannerOverlay(),
          if (_message != null) _statusBanner(_message!),
          if (_validatedBin != null) _confirmPanel(),
        ],
      ),
    );
  }

  Widget _scannerOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  'Scan the QR code attached to the RecyTech bin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 230.w,
                height: 230.w,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBanner(String message) {
    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: 24.h,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RecyTechTheme.textDark,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!_isHandlingScan) ...[
              SizedBox(height: 10.h),
              OutlinedButton.icon(
                onPressed: _retryScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Retry Scan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _confirmPanel() {
    final bin = _validatedBin!;
    final expected = widget.expectedBin;
    final differs = expected != null && expected.id != bin.id;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              differs ? 'Scanned Bin' : 'Bin QR Verified',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: RecyTechTheme.textDark,
              ),
            ),
            if (differs) ...[
              SizedBox(height: 6.h),
              Text(
                'This QR belongs to a different bin than the one selected. Confirm only if this is the bin you are using.',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  height: 1.35,
                  color: RecyTechTheme.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            _detailRow(Icons.delete_outline, bin.name),
            _detailRow(
              Icons.apartment_outlined,
              bin.partnerOrganizationName ?? '-',
            ),
            _detailRow(
              Icons.place_outlined,
              bin.locationDescription ?? bin.address,
            ),
            if (bin.acceptedCategoryLabels.isNotEmpty)
              _detailRow(
                Icons.check_circle_outline,
                'Accepts: ${bin.acceptedCategoryLabels.join(', ')}',
              ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retryScan,
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openDropOffForm,
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: RecyTechTheme.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraError(MobileScannerException error) {
    return Container(
      color: RecyTechTheme.bg,
      padding: EdgeInsets.all(24.w),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            color: RecyTechTheme.primary,
            size: 42.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'Camera access is required to scan the designated bin QR code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RecyTechTheme.textDark,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            error.errorDetails?.message ??
                'Allow camera permission in device settings and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RecyTechTheme.textMuted,
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
