class SensorIncidentSeverities {
  const SensorIncidentSeverities._();

  static const low = 'Low';
  static const medium = 'Medium';
  static const high = 'High';
  static const critical = 'Critical';

  static const values = [low, medium, high, critical];

  static bool isValid(String? value) => values.contains(value);

  static bool placesBinInMaintenance(String? value) =>
      value == high || value == critical;
}

class SensorIncidentStatuses {
  const SensorIncidentStatuses._();

  static const pending = 'Pending';
  static const inProgress = 'In Progress';
  static const resolved = 'Resolved';
  static const dismissed = 'Dismissed';

  static const values = [pending, inProgress, resolved, dismissed];

  static String normalize(String? value) {
    final normalized =
        (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
    return switch (normalized) {
      'pending' => pending,
      'in progress' => inProgress,
      'resolved' => resolved,
      'dismissed' => dismissed,
      _ => throw FormatException('Unsupported sensor incident status: $value'),
    };
  }
}

class SensorIncidentBin {
  const SensorIncidentBin({
    required this.id,
    this.name,
    this.address,
    this.status,
  });

  final String id;
  final String? name;
  final String? address;
  final String? status;

  String get displayName => (name ?? '').trim().isEmpty ? id : name!.trim();

  factory SensorIncidentBin.fromJson(dynamic value) {
    if (value is String) return SensorIncidentBin(id: value);
    final map = _map(value);
    final location = _map(map['location']);
    return SensorIncidentBin(
      id: (map['_id'] ?? map['id'] ?? map['binId'] ?? '').toString(),
      name: _optionalString(map['name'] ?? map['binName']),
      address: _optionalString(
        map['address'] ?? location['address'] ?? map['locationDescription'],
      ),
      status: _optionalString(map['status']),
    );
  }
}

class SensorIncident {
  const SensorIncident({
    required this.id,
    required this.bin,
    required this.sensorType,
    required this.issueDescription,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.resolutionNotes,
    this.resolvedAt,
  });

  final String id;
  final SensorIncidentBin bin;
  final String sensorType;
  final String issueDescription;
  final String severity;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? resolutionNotes;
  final DateTime? resolvedAt;

  factory SensorIncident.fromJson(Map<String, dynamic> json) {
    final severity = (json['severity'] ?? '').toString();
    if (!SensorIncidentSeverities.isValid(severity)) {
      throw FormatException('Unsupported sensor incident severity: $severity');
    }
    return SensorIncident(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      bin: SensorIncidentBin.fromJson(json['binId'] ?? json['bin']),
      sensorType: (json['sensorType'] ?? '').toString(),
      issueDescription: (json['issueDescription'] ?? '').toString(),
      severity: severity,
      status: SensorIncidentStatuses.normalize(json['status']?.toString()),
      createdAt:
          _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _date(json['updatedAt']),
      resolutionNotes: _optionalString(json['resolutionNotes']),
      resolvedAt: _date(json['resolvedAt']),
    );
  }
}

class SensorIncidentSubmissionResult {
  const SensorIncidentSubmissionResult({
    required this.success,
    required this.message,
    required this.incident,
  });

  final bool success;
  final String message;
  final SensorIncident incident;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

String? _optionalString(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) => DateTime.tryParse((value ?? '').toString());
