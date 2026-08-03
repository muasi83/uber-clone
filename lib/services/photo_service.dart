import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class PhotoService {
  static Future<String?> uploadPhoto(Uint8List bytes, String filename, String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/photos/upload');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        addDebugMessage('✅ Photo uploaded: ${data['photoUrl']}');
        return data['photoUrl'] as String;
      }
      addDebugMessage('❌ Photo upload failed: ${response.statusCode}');
      return null;
    } catch (e) {
      addDebugMessage('❌ Photo upload exception: $e');
      return null;
    }
  }

  static Future<String?> getPhotoUrl(int userId, String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/photos/$userId');
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['photoUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deletePhoto(String token) async {
    try {
      final url = Uri.parse('${StorageService.getServerUrl()}/api/photos');
      final response = await http
          .delete(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 404) {
        addDebugMessage('✅ Photo deleted');
        return true;
      }
      addDebugMessage('❌ Photo delete failed: ${response.statusCode}');
      return false;
    } catch (e) {
      addDebugMessage('❌ Photo delete exception: $e');
      return false;
    }
  }

  static String? resolvePhotoUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${StorageService.getServerUrl()}${path.startsWith('/') ? '' : '/'}$path';
  }
}
