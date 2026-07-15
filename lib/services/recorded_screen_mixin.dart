import 'package:flutter/material.dart';
import 'event_recorder_service.dart';
import 'ui_event_recorder.dart';

mixin RecordedScreenMixin<T extends StatefulWidget> on State<T> {
  String get screenName => widget.runtimeType.toString();

  @override
  void initState() {
    super.initState();
    UiEventRecorder.setCurrentScreen(screenName);
  }

  void recordEvent({
    int? rideId,
    required String eventName,
    String category = 'FRONTEND',
    String? summary,
    String? severity,
    Map<String, dynamic>? extraDetails,
  }) {
    EventRecorderService.recordEvent(
      rideId: rideId ?? UiEventRecorder.currentRideId,
      eventName: eventName,
      category: category,
      summary: summary ?? eventName,
      severity: severity,
      screenName: screenName,
      extraDetails: extraDetails,
    );
  }

  Future<T?> showRecordedDialog<T>({
    required BuildContext context,
    required String dialogType,
    String? dialogText,
    String? triggerReason,
    List<String>? buttons,
    bool barrierDismissible = true,
    required WidgetBuilder builder,
  }) {
    return UiEventRecorder.showDialog(
      context: context,
      dialogType: dialogType,
      dialogText: dialogText ?? dialogType,
      triggerReason: triggerReason,
      buttons: buttons,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  void showRecordedSnackBar({
    required BuildContext context,
    required String message,
    String? type,
    String? triggerReason,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    UiEventRecorder.showSnackBar(
      context: context,
      message: message,
      type: type,
      triggerReason: triggerReason,
      duration: duration,
      action: action,
    );
  }

  Future<T?> showRecordedModalBottomSheet<T>({
    required BuildContext context,
    required String sheetType,
    String? triggerReason,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    return UiEventRecorder.showModalBottomSheet(
      context: context,
      sheetType: sheetType,
      triggerReason: triggerReason,
      builder: builder,
      isScrollControlled: isScrollControlled,
    );
  }
}
