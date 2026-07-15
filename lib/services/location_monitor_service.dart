import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationMonitorService {
  LocationMonitorService._();
  static final LocationMonitorService _instance = LocationMonitorService._();
  factory LocationMonitorService() => _instance;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChanged => _controller.stream;

  bool _gpsEnabled = true;
  bool get isGpsEnabled => _gpsEnabled;

  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled != _gpsEnabled) {
        _gpsEnabled = enabled;
        _controller.add(enabled);
      }
    } catch (_) {}
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
