class PublicBin {
  const PublicBin({
    required this.id,
    required this.name,
    required this.address,
    this.publicStatus,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String? publicStatus;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
