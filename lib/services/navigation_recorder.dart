import 'package:flutter/material.dart';
import 'event_recorder_service.dart';
import 'ui_event_recorder.dart';

class NavigationRecorder extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final screenName = _screenName(route);
    if (screenName != null) {
      UiEventRecorder.setCurrentScreen(screenName);
      EventRecorderService.recordEvent(
        rideId: UiEventRecorder.currentRideId,
        eventName: 'SCREEN_OPENED',
        category: 'FRONTEND',
        summary: 'Navigated to $screenName',
        screenName: screenName,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      final screenName = _screenName(previousRoute);
      if (screenName != null) {
        UiEventRecorder.setCurrentScreen(screenName);
      }
    }
  }

  String? _screenName(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      final parts = name.split('/');
      return parts.last.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
    return route.settings.name ?? route.runtimeType.toString();
  }
}
