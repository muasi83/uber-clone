import 'package:flutter/material.dart' as flutter;
import 'event_recorder_service.dart';

class UiEventRecorder {
  static int? _currentRideId;
  static String? _currentScreen;

  static void setCurrentRideId(int? rideId) {
    _currentRideId = rideId;
  }

  static void setCurrentScreen(String screen) {
    _currentScreen = screen;
  }

  static int? get currentRideId => _currentRideId;
  static String? get currentScreen => _currentScreen;

  static Future<T?> showDialog<T>({
    required flutter.BuildContext context,
    required String dialogType,
    String? dialogText,
    String? triggerReason,
    List<String>? buttons,
    bool barrierDismissible = true,
    required flutter.WidgetBuilder builder,
  }) async {
    final rideId = _currentRideId;
    if (rideId != null) {
      EventRecorderService.recordUiEvent(
        rideId: rideId,
        eventName: 'UI_DIALOG_SHOWN',
        screenName: _currentScreen ?? 'Unknown',
        uiElementType: 'Dialog',
        dialogText: dialogText ?? dialogType,
        triggerReason: triggerReason,
        availableButtons: buttons?.join(', '),
        outcome: 'displayed',
      );
    }

    final result = await flutter.showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );

    if (rideId != null) {
      EventRecorderService.recordUiEvent(
        rideId: rideId,
        eventName: 'UI_DIALOG_RESULT',
        screenName: _currentScreen ?? 'Unknown',
        uiElementType: 'Dialog',
        dialogText: dialogText ?? dialogType,
        userChoice: result?.toString() ?? (barrierDismissible ? 'dismissed' : 'closed'),
        outcome: 'resolved',
      );
    }

    return result;
  }

  static void showSnackBar({
    required flutter.BuildContext context,
    required String message,
    String? type,
    String? triggerReason,
    String? dialogType,
    String? sheetType,
    Duration duration = const Duration(seconds: 4),
    flutter.SnackBarAction? action,
  }) {
    final rideId = _currentRideId;
    if (rideId != null) {
      EventRecorderService.recordUiEvent(
        rideId: rideId,
        eventName: 'UI_SNACKBAR_SHOWN',
        screenName: _currentScreen ?? 'Unknown',
        uiElementType: 'Snackbar',
        dialogText: message,
        triggerReason: triggerReason,
        availableButtons: action != null ? action.label : null,
        outcome: 'displayed',
      );
    }

    flutter.ScaffoldMessenger.of(context).showSnackBar(
      flutter.SnackBar(
        content: flutter.Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  static Future<T?> showModalBottomSheet<T>({
    required flutter.BuildContext context,
    required String sheetType,
    String? triggerReason,
    String? dialogType,
    required flutter.WidgetBuilder builder,
    bool isScrollControlled = false,
  }) async {
    final rideId = _currentRideId;
    if (rideId != null) {
      EventRecorderService.recordUiEvent(
        rideId: rideId,
        eventName: 'UI_BOTTOM_SHEET_SHOWN',
        screenName: _currentScreen ?? 'Unknown',
        uiElementType: 'BottomSheet',
        triggerReason: triggerReason,
        dialogText: sheetType,
        outcome: 'displayed',
      );
    }

    final result = await flutter.showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );

    if (rideId != null) {
      EventRecorderService.recordUiEvent(
        rideId: rideId,
        eventName: 'UI_BOTTOM_SHEET_RESULT',
        screenName: _currentScreen ?? 'Unknown',
        uiElementType: 'BottomSheet',
        dialogText: sheetType,
        userChoice: result?.toString() ?? 'dismissed',
        outcome: 'resolved',
      );
    }

    return result;
  }

  static Future<void> showPermissionDialog({
    required flutter.BuildContext context,
    required String permissionType,
    String? triggerReason,
  }) async {
    final rideId = _currentRideId;
    if (rideId != null) {
      EventRecorderService.recordUiEvent(
        rideId: rideId,
        eventName: 'UI_PERMISSION_REQUESTED',
        screenName: _currentScreen ?? 'Unknown',
        uiElementType: 'PermissionDialog',
        dialogText: permissionType,
        triggerReason: triggerReason,
        outcome: 'requested',
      );
    }
  }
}
