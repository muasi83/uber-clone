import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final _statusController = StreamController<bool>.broadcast();
  static Stream<bool> get onStatusChanged => _statusController.stream;
  static bool _isOnline = true;
  static bool get isOnline => _isOnline;
  static StreamSubscription<List<ConnectivityResult>>? _sub;

  static void init() {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      _statusController.add(_isOnline);
      debugPrint(_isOnline ? 'Connectivity: online' : 'Connectivity: offline');
    });
    Connectivity().checkConnectivity().then((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      _statusController.add(_isOnline);
      debugPrint(_isOnline ? 'Connectivity: online' : 'Connectivity: offline');
    });
  }
}
