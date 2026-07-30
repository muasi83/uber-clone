import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<bool>? _sub;
  bool _isOnline = true;
  bool _showRestored = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.isOnline;
    _sub = ConnectivityService.onStatusChanged.listen((online) {
      if (!mounted) return;
      setState(() {
        _isOnline = online;
        if (online) {
          _showRestored = true;
          _restoredTimer?.cancel();
          _restoredTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showRestored = false);
          });
        } else {
          _showRestored = false;
          _restoredTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = !_isOnline || _showRestored;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: show ? Offset.zero : const Offset(0, -1),
        child: Material(
          elevation: 4,
          color: !_isOnline ? AppColors.error : const Color(0xFF4CAF50),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    !_isOnline ? Icons.wifi_off : Icons.wifi,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !_isOnline
                          ? 'No Internet Connection - Reconnecting...'
                          : 'Connection Restored',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
