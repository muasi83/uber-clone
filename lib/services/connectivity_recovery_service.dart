import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'websocket_service.dart';
import 'storage_service.dart';

class ConnectivityRecoveryService {
  // ignore: unused_field
  static StreamSubscription<bool>? _sub;
  static bool _hasEverBeenOffline = false;

  static void init() {
    _sub = ConnectivityService.onStatusChanged.listen((online) {
      if (!online) {
        _hasEverBeenOffline = true;
        return;
      }
      if (!_hasEverBeenOffline) return;
      _hasEverBeenOffline = false;

      debugPrint('Recovery: internet restored — checking WebSocket in 2s');

      Future.delayed(const Duration(seconds: 2), () {
        if (WebSocketService.isConnected()) {
          debugPrint('Recovery: WebSocket already connected — nothing to do');
          return;
        }
        final userId = StorageService.getUserId();
        final username = StorageService.getUsername();
        if (userId == null || username == null) {
          debugPrint('Recovery: no credentials available — skipping');
          return;
        }
        debugPrint('Recovery: reconnecting WebSocket...');
        WebSocketService.connect(userId, username);
      });
    });
  }
}
