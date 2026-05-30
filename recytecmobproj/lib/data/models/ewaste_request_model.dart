class EWasteRequestModel {
  final String id;
  final String residentName;
  final String wasteType;
  final String itemCategory;
  final String detectedClass;
  final String location;
  final int quantity;
  final double ratePerKg;
  final double ratePerItem;
  final String residentEmail;
  final String phone;
  final String wasteImage;
  final String status;
  final String assignedCollector;
  final String assignedCollectorId;
  final String scheduledAt;
  final String createdAt;
  final String updatedAt;

  EWasteRequestModel({
    required this.id,
    required this.residentName,
    required this.wasteType,
    required this.itemCategory,
    required this.detectedClass,
    required this.location,
    required this.quantity,
    required this.ratePerKg,
    required this.ratePerItem,
    required this.residentEmail,
    required this.phone,
    required this.wasteImage,
    required this.status,
    required this.assignedCollector,
    required this.assignedCollectorId,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get category => wasteType;
  String get description => itemCategory.isNotEmpty ? itemCategory : wasteType;
  String get condition => quantity.toString();
  String get address => location;

  factory EWasteRequestModel.fromJson(Map<String, dynamic> json) {
    final locationValue = json['location'];
    final locationAddress = locationValue is Map
        ? (locationValue['address'] ?? '').toString()
        : (locationValue ?? json['address'] ?? '').toString();

    final resident = _asMap(json['resident']);
    final assignedCollector = _asMap(json['assignedCollector']);
    final assignedCollectorName = [
      assignedCollector['firstName'],
      assignedCollector['lastName'],
    ].where((part) => (part ?? '').toString().trim().isNotEmpty).join(' ');

    return EWasteRequestModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      residentName: (json['residentName'] ?? '').toString(),
      wasteType: (json['wasteType'] ?? json['category'] ?? '').toString(),
      itemCategory: (json['itemCategory'] ?? '').toString(),
      detectedClass: (json['detectedClass'] ?? '').toString(),
      location: locationAddress,
      quantity: _parseQuantity(json['quantity']),
      ratePerKg: _parseDouble(json['ratePerKg']),
      ratePerItem: _parseDouble(json['ratePerItem']),
      residentEmail:
          (json['residentEmail'] ?? resident['email'] ?? '').toString(),
      phone: (json['phone'] ?? resident['phone'] ?? '').toString(),
      wasteImage: (json['wasteImage'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      assignedCollector: assignedCollectorName.isNotEmpty
          ? assignedCollectorName
          : (json['assignedCollector'] ?? '').toString(),
      assignedCollectorId: (assignedCollector['_id'] ??
              assignedCollector['id'] ??
              (json['assignedCollector'] is String
                  ? json['assignedCollector']
                  : ''))
          .toString(),
      scheduledAt: (json['scheduledAt'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static int _parseQuantity(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 1;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }
}
