import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class EventRecorderService {
  static String _normalizeToken(String token) {
    var t = token.trim();
    if (t.length >= 2 &&
        ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'")))) {
      t = t.substring(1, t.length - 1).trim();
    }
    final lower = t.toLowerCase();
    if (lower.startsWith('bearer ')) {
      t = t.substring(7).trim();
    }
    return t;
  }

  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_normalizeToken(token)}';
    }
    return headers;
  }

  static Future<void> recordEvent({
    int? rideId,
    required String eventName,
    String actor = 'FLUTTER',
    int? actorId,
    String? actorName,
    String category = 'SYSTEM',
    String? summary,
    String? severity,
    String? screenName,
    Map<String, dynamic>? extraDetails,
  }) async {
    if (rideId == null) return;
    try {
      final token = StorageService.getToken();
      if (token == null) return;

      final details = <String, dynamic>{
        'category': category,
        'summary': summary ?? eventName,
        'severity': severity ?? 'INFO',
        if (screenName != null) 'screenName': screenName,
        if (extraDetails != null) ...extraDetails,
      };

      final body = jsonEncode({
        'rideId': rideId,
        'eventType': eventName,
        'actor': actor,
        'actorId': actorId,
        'actorName': actorName ?? actor,
        'details': details,
      });

      final url = '${StorageService.getServerUrl()}/api/events/record';
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        addDebugMessage('EventRecorder: failed to record $eventName: ${response.statusCode}');
      }
    } catch (e) {
      addDebugMessage('EventRecorder: exception recording $eventName: $e');
    }
  }

  static Future<void> recordUiEvent({
    int? rideId,
    required String eventName,
    String actor = 'FLUTTER',
    int? actorId,
    String? actorName,
    required String screenName,
    required String uiElementType,
    String? dialogText,
    String? triggerReason,
    String? availableButtons,
    String? userChoice,
    String? frontendAction,
    String? backendAction,
    String? outcome,
  }) async {
    if (rideId == null) return;
    try {
      final token = StorageService.getToken();
      if (token == null) return;

      final body = jsonEncode({
        'rideId': rideId,
        'eventType': eventName,
        'actor': actor,
        'actorId': actorId,
        'actorName': actorName ?? actor,
        'details': {
          'category': 'UI',
          'summary': uiElementType,
          'screenName': screenName,
          'uiElementType': uiElementType,
          if (dialogText != null) 'dialogText': dialogText,
          if (triggerReason != null) 'triggerReason': triggerReason,
          if (availableButtons != null) 'availableButtons': availableButtons,
          if (userChoice != null) 'userChoice': userChoice,
          if (frontendAction != null) 'frontendAction': frontendAction,
          if (backendAction != null) 'backendAction': backendAction,
          if (outcome != null) 'outcome': outcome,
        },
      });

      final url = '${StorageService.getServerUrl()}/api/events/record';
      await http
          .post(
            Uri.parse(url),
            headers: _headers(token: token),
            body: body,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      addDebugMessage('EventRecorder UI: exception: $e');
    }
  }
}
