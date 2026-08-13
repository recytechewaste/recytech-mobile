import '../datasources/contribution_api.dart';
import '../models/contribution_model.dart';

class ContributionRepository {
  final ContributionApi _api;

  ContributionRepository(this._api);

  Future<List<ContributionModel>> fetchMyContributions() async {
    final list = await _api.fetchContributions();
    return list
        .whereType<Map>()
        .map((e) => ContributionModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
