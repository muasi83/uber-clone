import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';

const int _pinWidth = 40;
const int _pinHeight = 90;

class MarkerFactory {
  MarkerFactory._();

  static Future<BitmapDescriptor> get pickup => _pickupMemo();
  static Future<BitmapDescriptor> get dropoff => _dropoffMemo();
  static Future<BitmapDescriptor> get destination => _destinationMemo();
  static Future<BitmapDescriptor> get driver => _driverMemo();
  static Future<BitmapDescriptor> get userLocation => _userMemo();
  static Future<BitmapDescriptor> get stickPickup => _stickPickupMemo();
  static Future<BitmapDescriptor> get stickDropoff => _stickDropoffMemo();

  // ── Memoized descriptors ─────────────────────────────────────────
  static Future<BitmapDescriptor>? _pickupCached;
  static Future<BitmapDescriptor> _pickupMemo() =>
      _pickupCached ??= _createPin(AppColors.pickupMarker);

  static Future<BitmapDescriptor>? _dropoffCached;
  static Future<BitmapDescriptor> _dropoffMemo() =>
      _dropoffCached ??= _createPin(AppColors.dropoffMarker);

  static Future<BitmapDescriptor>? _destinationCached;
  static Future<BitmapDescriptor> _destinationMemo() =>
      _destinationCached ??= _createPin(AppColors.secondary);

  static Future<BitmapDescriptor>? _driverCached;
  static Future<BitmapDescriptor> _driverMemo() =>
      _driverCached ??= _createPin(AppColors.driverMarker);

  static Future<BitmapDescriptor>? _userCached;
  static Future<BitmapDescriptor> _userMemo() =>
      _userCached ??= _createDot(AppColors.primary);

  static Future<BitmapDescriptor>? _stickPickupCached;
  static Future<BitmapDescriptor> _stickPickupMemo() =>
      _stickPickupCached ??= _createStickPin(AppColors.pickupMarker);

  static Future<BitmapDescriptor>? _stickDropoffCached;
  static Future<BitmapDescriptor> _stickDropoffMemo() =>
      _stickDropoffCached ??= _createStickPin(AppColors.dropoffMarker);

  // ── Pin marker (teardrop shape) ───────────────────────────────────
  static Future<BitmapDescriptor> _createPin(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()..color = const Color(0x40000000);

    // Stick shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 32, 6, 50),
        const Radius.circular(3),
      ),
      shadowPaint,
    );

    // Main stick
    final stickPaint = Paint()
      ..color = AppColors.textTertiary
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 30, 4, 50),
        const Radius.circular(2),
      ),
      stickPaint,
    );

    // Point at bottom of stick
    final pointPaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(20, 76)
      ..lineTo(16, 84)
      ..lineTo(24, 84)
      ..close();
    canvas.drawPath(path, pointPaint);

    // Head shadow
    canvas.drawCircle(const Offset(20, 16), 15, shadowPaint);

    // Colored circle head
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(20, 15), 14, headPaint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(20, 15), 14, borderPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = const Color(0x80FFFFFF);
    canvas.drawCircle(const Offset(16, 11), 4, highlightPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(_pinWidth, _pinHeight);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Dot marker (user location) ───────────────────────────────────
  static Future<BitmapDescriptor> _createDot(Color color) async {
    const int size = 32;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, ringPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 4, dotPaint);

    // White center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 8, centerPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Stick pin (simple stick with rounded top) ─────────────────────
  static Future<BitmapDescriptor> _createStickPin(Color color) async {
    const int w = 20;
    const int h = 60;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(10, 55), width: 8, height: 4),
      shadowPaint,
    );

    final stickPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(10, 50),
      const Offset(10, 20),
      stickPaint,
    );

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(10, 18), 5, headPaint);

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(10, 18), 2, centerPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
