import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/partner_organization_model.dart';

class PartnerOrganizationRepository {
  PartnerOrganizationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PartnerOrganizationProfile> fetchProfile() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.partnerOrganizationMe);
    return PartnerOrganizationProfile.fromJson(_object(response.data));
  }

  Future<PartnerOrganizationStats> fetchStats() async {
    final response =
        await _apiClient.dio.get(ApiEndpoints.partnerOrganizationStats);
    return PartnerOrganizationStats.fromJson(_object(response.data));
  }

  Map<String, dynamic> _object(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}
