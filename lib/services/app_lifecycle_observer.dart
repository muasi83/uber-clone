import 'package:flutter/material.dart';
import 'event_recorder_service.dart';
import 'ui_event_recorder.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final rideId = UiEventRecorder.currentRideId;
    switch (state) {
      case AppLifecycleState.resumed:
        EventRecorderService.recordEvent(
          rideId: rideId,
          eventName: 'APP_RESUMED',
          category: 'FRONTEND',
          summary: 'Application resumed from background',
          screenName: UiEventRecorder.currentScreen,
        );
      case AppLifecycleState.paused:
        EventRecorderService.recordEvent(
          rideId: rideId,
          eventName: 'APP_BACKGROUNDED',
          category: 'FRONTEND',
          summary: 'Application sent to background',
          screenName: UiEventRecorder.currentScreen,
        );
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.detached:
        EventRecorderService.recordEvent(
          rideId: rideId,
          eventName: 'APP_DETACHED',
          category: 'FRONTEND',
          summary: 'Application detached',
        );
    }
  }
}
