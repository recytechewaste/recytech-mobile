import '../datasources/request_api.dart';
import '../models/ewaste_request_model.dart';

class RequestRepository {
  final RequestApi _api;
  RequestRepository(this._api);

  Future<List<String>> fetchActiveWasteCategories() async {
    final list = await _api.fetchActiveWasteCategories();

    return list
        .map((item) {
          if (item is Map) {
            return (item['value'] ?? item['label'] ?? '').toString();
          }
          return item.toString();
        })
        .where((category) => category.trim().isNotEmpty)
        .toList();
  }

  Future<List<EWasteRequestModel>> fetchMyRequests() async {
    final list = await _api.fetchRequests();
    return list
        .map((e) =>
            EWasteRequestModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<EWasteRequestModel> submitRequest({
    required String wasteType,
    required String location,
    required int quantity,
    required String residentName,
    required String residentEmail,
    String? wasteImage,
    String? phone,
    String? firstName,
    String? lastName,
    String? mobileUserId,
  }) async {
    final payload = {
      'wasteType': wasteType,
      'location': {
        'address': location,
      },
      'quantity': quantity,
      'residentName': residentName,
      'residentEmail': residentEmail,
      'wasteImage': wasteImage ?? '',
      'phone': phone ?? '',
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'mobileUserId': mobileUserId ?? '',
    };

    final res = await _api.createRequest(payload);
    return EWasteRequestModel.fromJson(res);
  }
}
