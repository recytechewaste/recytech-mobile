import '../datasources/contribution_api.dart';
import '../models/contribution_model.dart';

class ContributionRepository {
  final ContributionApi _api;

  ContributionRepository(this._api);

  Future<List<ContributionModel>> fetchMyContributions() async {
    final list = await _api.fetchContributions();
    return list
        .map((e) =>
            ContributionModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
