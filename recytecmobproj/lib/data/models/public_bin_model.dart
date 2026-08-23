class PublicBin {
  const PublicBin({
    required this.id,
    required this.name,
    required this.address,
    required this.publicQrCode,
    this.publicStatus,
    this.building,
    this.locationDescription,
    this.accessInfo,
    this.latitude,
    this.longitude,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String address;
  final String publicQrCode;
  final String? publicStatus;
  final String? building;
  final String? locationDescription;
  final String? accessInfo;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get locationLabel {
    final parts = [
      building,
      locationDescription,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? address : parts.join(' - ');
  }
}
