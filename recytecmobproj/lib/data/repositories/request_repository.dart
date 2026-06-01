import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

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
    final list = await _api.fetchMyRequests();
    return list
        .map((e) =>
            EWasteRequestModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchMyTransactions() async {
    final list = await _api.fetchMyTransactions();
    return list
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
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
    final preparedWasteImage = await _prepareWasteImage(wasteImage);

    final payload = {
      'wasteType': wasteType,
      'location': {
        'address': location,
      },
      'quantity': quantity,
      'residentName': residentName,
      'residentEmail': residentEmail,
      'wasteImage': preparedWasteImage,
      'phone': phone ?? '',
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'mobileUserId': mobileUserId ?? '',
    };

    final res = await _api.createRequest(payload);
    return EWasteRequestModel.fromJson(res);
  }

  Future<String> _prepareWasteImage(String? value) async {
    final imageValue = (value ?? '').trim();
    if (imageValue.isEmpty ||
        imageValue.startsWith('http://') ||
        imageValue.startsWith('https://') ||
        imageValue.startsWith('data:image/')) {
      return imageValue;
    }

    final file = File(imageValue);
    if (!await file.exists()) return '';

    final originalBytes = await file.readAsBytes();
    final decoded = img.decodeImage(originalBytes);

    if (decoded == null) {
      return 'data:image/jpeg;base64,${base64Encode(originalBytes)}';
    }

    final resized = decoded.width > 1024 || decoded.height > 1024
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1024 : null,
            height: decoded.height > decoded.width ? 1024 : null,
            interpolation: img.Interpolation.linear,
          )
        : decoded;

    final Uint8List encodedBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: 78),
    );

    return 'data:image/jpeg;base64,${base64Encode(encodedBytes)}';
  }
}
