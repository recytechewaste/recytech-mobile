class PublicBin {
  const PublicBin({
    required this.id,
    required this.name,
    required this.address,
    required this.publicQrCode,
    this.binCode,
    this.publicStatus,
    this.building,
    this.locationDescription,
    this.accessInfo,
    this.partnerOrganizationName,
    this.assignedLguId,
    this.assignedLguContactPerson,
    this.assignedLguEmail,
    this.assignedLguPhone,
    this.acceptedCategories = const [],
    this.acceptedCategoryLabels = const [],
    this.latitude,
    this.longitude,
    this.fillPercentage,
    this.fullnessStatus,
    this.capacityKg,
    this.currentFillKg,
    this.isAvailableForDropoff,
    this.isActive = true,
    this.rewards = const [],
  });

  final String id;
  final String name;
  final String address;
  final String publicQrCode;
  final String? binCode;
  final String? publicStatus;
  final String? building;
  final String? locationDescription;
  final String? accessInfo;
  final String? partnerOrganizationName;
  final String? assignedLguId;
  final String? assignedLguContactPerson;
  final String? assignedLguEmail;
  final String? assignedLguPhone;
  final List<String> acceptedCategories;
  final List<String> acceptedCategoryLabels;
  final double? latitude;
  final double? longitude;
  final double? fillPercentage;
  final String? fullnessStatus;
  final double? capacityKg;
  final double? currentFillKg;
  final bool? isAvailableForDropoff;
  final bool isActive;
  final List<PublicBinReward> rewards;

  factory PublicBin.fromJson(Map<String, dynamic> json) {
    final location = _asMap(json['location']);
    final assignedLgu = _asMap(json['assignedLgu']);
    final locationCoordinates = location['coordinates'] is List
        ? location['coordinates'] as List
        : const [];
    final rootCoordinates =
        json['coordinates'] is List ? json['coordinates'] as List : const [];
    final parsedCoordinates = _readCoordinates(
      json,
      location,
      locationCoordinates,
      rootCoordinates,
    );
    final binCode = _optionalString(json['binId'] ?? json['binCode']);
    final publicQrCode = (json['publicQrCode'] ??
            json['publicQRCode'] ??
            json['publicCode'] ??
            json['qrCode'] ??
            binCode ??
            json['code'] ??
            '')
        .toString();
    final name = (json['name'] ??
            json['binName'] ??
            json['displayName'] ??
            json['label'] ??
            publicQrCode)
        .toString();
    final address = (json['address'] ??
            location['address'] ??
            json['locationAddress'] ??
            json['locationName'] ??
            '')
        .toString();
    final status =
        (json['publicStatus'] ?? json['availability'] ?? json['status'])
            ?.toString();
    final dropoffAvailability =
        _readOptionalBool(json['isAvailableForDropoff']);
    final activeValue = dropoffAvailability ??
        _readOptionalBool(
            json['isActive'] ?? json['active'] ?? json['enabled']);
    final capacityKg = _readDouble(json['capacityKg']);
    final currentFillKg = _readDouble(json['currentFillKg']);
    final explicitFillPercentage = _readDouble(
      json['fillPercentage'],
      json['fillLevel'],
      json['currentFillPercentage'],
      json['latestFillPercentage'],
    );
    final calculatedFillPercentage = capacityKg != null &&
            capacityKg > 0 &&
            currentFillKg != null &&
            currentFillKg >= 0
        ? currentFillKg / capacityKg * 100
        : null;

    return PublicBin(
      id: (json['_id'] ?? json['id'] ?? json['binId'] ?? publicQrCode)
          .toString(),
      publicQrCode: publicQrCode,
      binCode: binCode,
      name: name.trim().isEmpty ? 'RecyTech Bin' : name,
      building: _optionalString(
        json['building'] ?? json['buildingName'] ?? location['building'],
      ),
      locationDescription: _optionalString(
        json['locationDescription'] ??
            json['publicLocationDescription'] ??
            json['publicDropoffDescription'] ??
            (json['location'] is String ? json['location'] : null),
      ),
      address: address.trim().isEmpty ? 'Address unavailable' : address,
      accessInfo: _optionalString(json['accessInfo']),
      partnerOrganizationName: _optionalString(
        assignedLgu['name'] ??
            json['partnerOrganizationName'] ??
            json['partnerName'] ??
            json['organizationName'],
      ),
      assignedLguId: _optionalString(
        assignedLgu['_id'] ?? assignedLgu['id'],
      ),
      assignedLguContactPerson: _optionalString(
        assignedLgu['contactPerson'],
      ),
      assignedLguEmail: _optionalString(assignedLgu['email']),
      assignedLguPhone: _optionalString(assignedLgu['phone']),
      acceptedCategories: _readStringList(json['acceptedCategories']),
      acceptedCategoryLabels: _readCategoryLabels(
        json['acceptedCategoryDisplayNames'],
        json['acceptedCategories'],
      ),
      publicStatus: _optionalString(status) ?? 'Active',
      latitude: parsedCoordinates.latitude,
      longitude: parsedCoordinates.longitude,
      fillPercentage: explicitFillPercentage ?? calculatedFillPercentage,
      fullnessStatus: _optionalString(
        json['fullnessStatus'] ?? json['currentFullnessStatus'],
      ),
      capacityKg: capacityKg,
      currentFillKg: currentFillKg,
      isAvailableForDropoff: dropoffAvailability,
      isActive: _readOperationalState(activeValue, status),
      rewards: _readRewards(json['rewards']),
    );
  }

  bool get hasCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  String get displayCode => binCode ?? publicQrCode;

  String get availabilityLabel => (isAvailableForDropoff ?? isActive)
      ? 'Available for drop-off'
      : 'Unavailable for drop-off';

  String get locationLabel {
    final parts = [
      building,
      locationDescription,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? address : parts.join(' - ');
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static double? _readDouble(
    dynamic first, [
    dynamic second,
    dynamic third,
    dynamic fourth,
    dynamic fifth,
    dynamic sixth,
    dynamic seventh,
  ]) {
    for (final value in [
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
    ]) {
      if (value == null || value.toString().trim().isEmpty) continue;
      final parsed = double.tryParse(value.toString());
      if (parsed != null && parsed.isFinite) return parsed;
    }
    return null;
  }

  static ({double? latitude, double? longitude}) _readCoordinates(
    Map<String, dynamic> json,
    Map<String, dynamic> location,
    List<dynamic> locationCoordinates,
    List<dynamic> rootCoordinates,
  ) {
    final candidates = <({double? latitude, double? longitude})>[
      (
        latitude: _readDouble(json['latitude']),
        longitude: _readDouble(json['longitude']),
      ),
      (
        latitude: _readDouble(json['lat']),
        longitude: _readDouble(json['lng']),
      ),
      (
        latitude: _readDouble(
          locationCoordinates.length > 1 ? locationCoordinates[1] : null,
        ),
        longitude: _readDouble(
          locationCoordinates.isNotEmpty ? locationCoordinates[0] : null,
        ),
      ),
      (
        latitude: _readDouble(
          rootCoordinates.length > 1 ? rootCoordinates[1] : null,
        ),
        longitude: _readDouble(
          rootCoordinates.isNotEmpty ? rootCoordinates[0] : null,
        ),
      ),
      (
        latitude: _readDouble(location['latitude'], location['lat']),
        longitude: _readDouble(
          location['longitude'],
          location['lng'],
          location['lon'],
        ),
      ),
    ];

    for (final candidate in candidates) {
      final latitude = candidate.latitude;
      final longitude = candidate.longitude;
      if (latitude != null &&
          longitude != null &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180) {
        return candidate;
      }
    }
    return (latitude: null, longitude: null);
  }

  static bool? _readOptionalBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = (value ?? '').toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static String? _optionalString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _readOperationalState(dynamic activeValue, String? status) {
    if (activeValue is bool) return activeValue;

    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return const {'empty', 'operational', 'active', 'open', 'available'}
        .contains(normalized);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _readCategoryLabels(dynamic labels, dynamic fallback) {
    if (labels is List) {
      final parsed = labels
          .map((item) {
            if (item is Map) {
              return (item['label'] ?? item['value'] ?? '').toString().trim();
            }
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }

    return _readStringList(fallback).map(_displayCategory).toList();
  }

  static List<PublicBinReward> _readRewards(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => PublicBinReward.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static String _displayCategory(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (normalized == 'pcb') return 'PCB';
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class PublicBinReward {
  const PublicBinReward({
    required this.id,
    required this.title,
    required this.pointsCost,
    this.description,
    this.partnerOrganizationName,
  });

  final String id;
  final String title;
  final int pointsCost;
  final String? description;
  final String? partnerOrganizationName;

  factory PublicBinReward.fromJson(Map<String, dynamic> json) {
    return PublicBinReward(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Partner Reward').toString(),
      description: _optionalString(json['description']),
      partnerOrganizationName: _optionalString(
        json['partnerOrganizationName'] ?? json['partnerName'],
      ),
      pointsCost: _parseInt(json['pointsCost']) ?? 0,
    );
  }

  static String? _optionalString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }
}
