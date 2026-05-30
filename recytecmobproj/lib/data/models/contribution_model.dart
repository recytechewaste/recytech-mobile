class ContributionModel {
  final String id;
  final String itemName;
  final String date;
  final String status;

  ContributionModel({
    required this.id,
    required this.itemName,
    required this.date,
    required this.status,
  });

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    return ContributionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      itemName: (json['itemName'] ?? json['title'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: (json['status'] ?? 'Completed').toString(),
    );
  }
}
