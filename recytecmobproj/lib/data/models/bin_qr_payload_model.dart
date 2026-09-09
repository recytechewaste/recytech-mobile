import 'dart:convert';

class BinQrPayload {
  const BinQrPayload({
    required this.version,
    required this.publicBinCode,
  });

  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  final int version;
  final String publicBinCode;

  factory BinQrPayload.parse(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const FormatException('Empty QR payload.');
    }

    final code = _extractQrCode(value);
    if (!_codePattern.hasMatch(code)) {
      throw const FormatException('Invalid bin QR code.');
    }

    return BinQrPayload(version: 1, publicBinCode: code);
  }

  String toQrValue() => 'recytech://bin/$publicBinCode';

  Map<String, dynamic> toJson() => {
        'version': version,
        'publicBinCode': publicBinCode,
      };

  static String _extractQrCode(String value) {
    if (_codePattern.hasMatch(value)) return value;

    if (value.startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          final qrCode = (decoded['qrCode'] ?? decoded['publicQrCode'] ?? '')
              .toString()
              .trim();
          if (_codePattern.hasMatch(qrCode)) return qrCode;
        }
      } on FormatException {
        throw const FormatException('Invalid RecyTech bin QR.');
      }
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      throw const FormatException('Invalid RecyTech bin QR.');
    }

    if (uri.scheme.toLowerCase() == 'recytech' &&
        uri.host.toLowerCase() == 'bin' &&
        uri.pathSegments.length == 1) {
      return uri.pathSegments.single.trim();
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final queryCode = (uri.queryParameters['qrCode'] ?? '').trim();
      if (_codePattern.hasMatch(queryCode)) return queryCode;

      final segments = uri.pathSegments;
      final qrIndex = segments.lastIndexWhere(
        (segment) => segment.toLowerCase() == 'qr',
      );
      if (qrIndex >= 0 && qrIndex + 1 < segments.length) {
        return segments[qrIndex + 1].trim();
      }
    }

    throw const FormatException('Invalid RecyTech bin QR.');
  }
}
