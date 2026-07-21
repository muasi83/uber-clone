import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_monitor_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class LocationBanner extends StatefulWidget {
  const LocationBanner({super.key});

  @override
  State<LocationBanner> createState() => _LocationBannerState();
}

class _LocationBannerState extends State<LocationBanner>
    with WidgetsBindingObserver {
  final _monitor = LocationMonitorService();
  bool _dismissedByUser = false;
  StreamSubscription<bool>? _sub;
  BuildContext? _sheetContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = _monitor.onStatusChanged.listen((enabled) {
      if (!mounted) return;
      if (enabled) {
        _dismissedByUser = false;
        _dismissSheet();
      } else if (!_dismissedByUser) {
        _showSheet();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGpsNow();
    }
  }

  Future<void> _checkGpsNow() async {
    if (!mounted) return;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      _dismissedByUser = false;
      _dismissSheet();
    } else if (!_dismissedByUser && _sheetContext == null) {
      _showSheet();
    }
  }

  void _showSheet() {
    if (!mounted) return;
    if (_sheetContext != null) return;
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        _sheetContext = ctx;
        return _buildSheet();
      },
    ).then((_) {
      _sheetContext = null;
    });
  }

  void _dismissSheet() {
    if (_sheetContext != null) {
      Navigator.of(_sheetContext!).pop();
      _sheetContext = null;
    }
  }

  Future<void> _onAllowLocation() async {
    await Geolocator.requestPermission();
    if (!mounted) return;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      _dismissedByUser = false;
      _dismissSheet();
    }
  }

  void _onMaybeLater() {
    _dismissedByUser = true;
    _dismissSheet();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _dismissSheet();
    super.dispose();
  }

  String get _subtitle {
    final role = StorageService.getRole() ?? '';
    if (role == 'DRIVER') {
      return 'Turn on location — it will help us find your rider.';
    }
    return 'Turn on location — it will help us find your driver.';
  }

  Widget _buildSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/location not available.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 120,
                  height: 120,
                  child: Icon(Icons.location_off, size: 64, color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Allow location',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: _buildButton(
                label: 'Allow Location',
                filled: true,
                onTap: _onAllowLocation,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _buildButton(
                label: 'Maybe Later',
                filled: false,
                onTap: _onMaybeLater,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: AppColors.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: filled ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
