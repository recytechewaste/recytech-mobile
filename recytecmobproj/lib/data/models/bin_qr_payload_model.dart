class BinQrPayload {
  const BinQrPayload({
    required this.version,
    required this.publicBinCode,
  });

  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_-]{4,64}$');

  final int version;
  final String publicBinCode;

  factory BinQrPayload.parse(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const FormatException('Empty QR payload.');
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'recytech' ||
        uri.host.toLowerCase() != 'bin' ||
        uri.pathSegments.length != 1) {
      throw const FormatException('Invalid RecyTech bin QR.');
    }

    final code = uri.pathSegments.single.trim();
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
}
