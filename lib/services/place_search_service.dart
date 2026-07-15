import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class PlaceSearchResult {
  final String placeId;
  final String description;

  PlaceSearchResult({required this.placeId, required this.description});

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      placeId: json['placeId'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String address;

  PlaceDetails({required this.lat, required this.lng, required this.address});

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
    );
  }
}

class PlaceSearchService {
  static Future<List<PlaceSearchResult>> search(
    String query, {
    double? lat,
    double? lng,
    String language = 'en',
  }) async {
    addDebugMessage('[PLACES SEARCH] Query="$query" Language=$language Lat=$lat Lng=$lng');
    try {
      final token = StorageService.getToken();
      var url = '${StorageService.getServerUrl()}/api/routes/places/search?query=${Uri.encodeQueryComponent(query)}';
      url += '&language=$language';
      if (lat != null && lng != null) {
        url += '&lat=$lat&lng=$lng';
      }
      addDebugMessage('[PLACES SEARCH] URL=$url');
      final headers = <String, String>{
        'ngrok-skip-browser-warning': 'true',
      };
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      addDebugMessage('[PLACES SEARCH] Response HTTP=${response.statusCode} BodyLength=${response.body.length}');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        final results = list.map((e) => PlaceSearchResult.fromJson(e as Map<String, dynamic>)).toList();
        addDebugMessage('[PLACES SEARCH] Parsed ${results.length} results');
        if (results.isNotEmpty) {
          addDebugMessage('[PLACES SEARCH] First result="${results.first.description}"');
        }
        return results;
      }
      addDebugMessage('[PLACES SEARCH] Unexpected HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      addDebugMessage('[PLACES SEARCH] Exception: $e');
      return [];
    }
  }

  static Future<PlaceDetails?> getPlaceDetails(String placeId, {String language = 'en'}) async {
    addDebugMessage('[PLACES DETAILS] placeId=$placeId Language=$language');
    try {
      final token = StorageService.getToken();
      var url = '${StorageService.getServerUrl()}/api/routes/places/details?placeId=${Uri.encodeQueryComponent(placeId)}';
      url += '&language=$language';
      addDebugMessage('[PLACES DETAILS] URL=$url');
      final headers = <String, String>{
        'ngrok-skip-browser-warning': 'true',
      };
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      addDebugMessage('[PLACES DETAILS] Response HTTP=${response.statusCode} BodyLength=${response.body.length}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          addDebugMessage('[PLACES DETAILS] Backend error: ${json['error']}');
          return null;
        }
        final details = PlaceDetails.fromJson(json);
        addDebugMessage('[PLACES DETAILS] Parsed: lat=${details.lat} lng=${details.lng} address="${details.address}"');
        return details;
      }
      addDebugMessage('[PLACES DETAILS] Unexpected HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      addDebugMessage('[PLACES DETAILS] Exception: $e');
      return null;
    }
  }
}
