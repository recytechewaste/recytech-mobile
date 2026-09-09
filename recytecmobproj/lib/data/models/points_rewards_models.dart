class RewardPointRule {
  const RewardPointRule({
    required this.id,
    required this.fields,
  });

  final String id;
  final Map<String, dynamic> fields;

  String get title => (fields['title'] ??
          fields['name'] ??
          fields['wasteType'] ??
          fields['category'] ??
          'Reward Rule')
      .toString();

  String? get description {
    final value = (fields['description'] ?? '').toString().trim();

    return value.isEmpty ? null : value;
  }

  num get pointsValue {
    final value =
        fields['pointsPerItem'] ?? fields['pointsPerKg'] ?? fields['points'];

    if (value is num) {
      return value;
    }

    return num.tryParse(
          (value ?? '').toString(),
        ) ??
        0;
  }

  bool get isActive {
    final value = fields['isActive'];

    if (value is bool) {
      return value;
    }

    return true;
  }

  Map<String, dynamic> get displayFields => Map<String, dynamic>.fromEntries(
        fields.entries.where(
          (entry) => !const [
            '_id',
            'id',
            'title',
            'name',
            'description',
            'isActive',
            'createdAt',
            'updatedAt',
            '__v',
            'pointsPerKg',
            'weight',
            'weightKg',
            'kg',
          ].contains(entry.key),
        ),
      );

  factory RewardPointRule.fromJson(
    Map<String, dynamic> json,
  ) {
    return RewardPointRule(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fields: Map<String, dynamic>.unmodifiable(
        json,
      ),
    );
  }
}

class PointsSummary {
  const PointsSummary({
    required this.balance,
    this.transactions = const [],
  });

  final int balance;
  final List<PointsLedgerEntry> transactions;

  factory PointsSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    final transactions = json['transactions'];

    final account = json['account'] is Map
        ? (json['account'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return PointsSummary(
      balance: _parseInt(
            json['balance'] ?? account['balance'],
          ) ??
          0,
      transactions: transactions is List
          ? transactions
              .whereType<Map>()
              .map(
                (item) => PointsLedgerEntry.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }
}

class PointsLedgerEntry {
  const PointsLedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.signedAmount,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amount;
  final int signedAmount;
  final String description;
  final DateTime createdAt;

  factory PointsLedgerEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return PointsLedgerEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: _parseInt(json['amount']) ?? 0,
      signedAmount: _parseInt(json['signedAmount']) ?? 0,
      description: (json['description'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class PartnerRewardOffer {
  const PartnerRewardOffer({
    required this.id,
    required this.title,
    required this.pointsCost,
    required this.active,
    this.description,
    this.partnerOrganizationId,
    this.partnerOrganizationName,
    this.canRedeem,
    this.applicableBinIds = const [],
    this.applicableBins = const [],
  });

  final String id;
  final String title;
  final String? description;
  final int pointsCost;
  final bool active;
  final String? partnerOrganizationId;
  final String? partnerOrganizationName;
  final bool? canRedeem;
  final List<String> applicableBinIds;
  final List<RewardBinScope> applicableBins;

  bool get appliesToAllPartnerBins => applicableBinIds.isEmpty;

  factory PartnerRewardOffer.fromJson(
    Map<String, dynamic> json,
  ) {
    return PartnerRewardOffer(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Partner Reward').toString(),
      description: _optionalString(json['description']),
      pointsCost: _parseInt(json['pointsCost']) ?? 0,
      active: json['active'] != false,
      partnerOrganizationId: _optionalString(
        json['partnerOrganizationId'],
      ),
      partnerOrganizationName: _optionalString(
        json['partnerOrganizationName'] ?? json['partnerName'],
      ),
      canRedeem: json['canRedeem'] is bool ? json['canRedeem'] as bool : null,
      applicableBinIds: _readStringList(
        json['applicableBinIds'],
      ),
      applicableBins: _readBins(
        json['applicableBins'],
      ),
    );
  }
}

class RewardBinScope {
  const RewardBinScope({
    required this.id,
    this.binCode,
    this.name,
  });

  final String id;
  final String? binCode;
  final String? name;

  factory RewardBinScope.fromJson(
    Map<String, dynamic> json,
  ) {
    return RewardBinScope(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      binCode: _optionalString(json['binCode']),
      name: _optionalString(json['name']),
    );
  }
}

class RewardRedemptionRecord {
  const RewardRedemptionRecord({
    required this.id,
    required this.rewardTitle,
    required this.pointsCost,
    required this.status,
    required this.redeemedAt,
    this.partnerOrganizationName,
    this.fulfilledAt,
    this.cancelledAt,
  });

  final String id;
  final String rewardTitle;
  final int pointsCost;
  final String status;
  final DateTime redeemedAt;
  final String? partnerOrganizationName;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;

  factory RewardRedemptionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return RewardRedemptionRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      rewardTitle: (json['rewardTitle'] ??
              json['rewardTitleSnapshot'] ??
              'Partner Reward')
          .toString(),
      pointsCost: _parseInt(
            json['pointsCost'] ?? json['pointsCostSnapshot'],
          ) ??
          0,
      status: (json['status'] ?? 'requested').toString(),
      redeemedAt: _parseDate(
        json['redeemedAt'] ?? json['createdAt'],
      ),
      partnerOrganizationName: _optionalString(
        json['partnerOrganizationName'] ?? json['partnerName'],
      ),
      fulfilledAt: _optionalDate(
        json['fulfilledAt'],
      ),
      cancelledAt: _optionalDate(
        json['cancelledAt'],
      ),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    (value ?? '').toString(),
  );
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(
        (value ?? '').toString(),
      ) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _optionalDate(dynamic value) {
  final text = (value ?? '').toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

String? _optionalString(dynamic value) {
  final text = (value ?? '').toString().trim();

  return text.isEmpty ? null : text;
}

List<String> _readStringList(
  dynamic value,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .map(
        (item) => item.toString().trim(),
      )
      .where(
        (item) => item.isNotEmpty,
      )
      .toList(growable: false);
}

List<RewardBinScope> _readBins(
  dynamic value,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => RewardBinScope.fromJson(
          item.cast<String, dynamic>(),
        ),
      )
      .toList(growable: false);
}
