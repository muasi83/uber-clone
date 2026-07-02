# Graph Report - .  (2026-07-02)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1979 nodes · 2676 edges · 80 communities (73 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ba7448f3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_rider_dropoff_location_screen.dart|rider_dropoff_location_screen.dart]]
- [[_COMMUNITY_driver_home_screen.dart|driver_home_screen.dart]]
- [[_COMMUNITY_Win32Window|Win32Window]]
- [[_COMMUNITY_State|State]]
- [[_COMMUNITY_rider_home_screen.dart|rider_home_screen.dart]]
- [[_COMMUNITY_app_colors.dart|app_colors.dart]]
- [[_COMMUNITY_app_spacing.dart|app_spacing.dart]]
- [[_COMMUNITY_GeneratedPluginRegistrant.swift|GeneratedPluginRegistrant.swift]]
- [[_COMMUNITY_driver_active_ride_screen.dart|driver_active_ride_screen.dart]]
- [[_COMMUNITY_driver_navigation_to_rider_screen.dart|driver_navigation_to_rider_screen.dart]]
- [[_COMMUNITY_rider_active_ride_screen.dart|rider_active_ride_screen.dart]]
- [[_COMMUNITY_rider_tracking_screen.dart|rider_tracking_screen.dart]]
- [[_COMMUNITY_rider_pickup_location_screen.dart|rider_pickup_location_screen.dart]]
- [[_COMMUNITY_ride_model.dart|ride_model.dart]]
- [[_COMMUNITY_rider_searching_driver_screen.dart|rider_searching_driver_screen.dart]]
- [[_COMMUNITY_websocket_service.dart|websocket_service.dart]]
- [[_COMMUNITY_main.dart|main.dart]]
- [[_COMMUNITY_storage_service.dart|storage_service.dart]]
- [[_COMMUNITY_ride_map_screen.dart|ride_map_screen.dart]]
- [[_COMMUNITY_ride_location_picker_screen.dart|ride_location_picker_screen.dart]]
- [[_COMMUNITY_app_typography.dart|app_typography.dart]]
- [[_COMMUNITY_ride_preview_screen.dart|ride_preview_screen.dart]]
- [[_COMMUNITY_chat_screen.dart|chat_screen.dart]]
- [[_COMMUNITY_rider_trip_details_screen.dart|rider_trip_details_screen.dart]]
- [[_COMMUNITY_marker_factory.dart|marker_factory.dart]]
- [[_COMMUNITY_marker_animator.dart|marker_animator.dart]]
- [[_COMMUNITY_home_screen.dart|home_screen.dart]]
- [[_COMMUNITY_premium_card.dart|premium_card.dart]]
- [[_COMMUNITY_my_application.cc|my_application.cc]]
- [[_COMMUNITY_background_navigation_service.dart|background_navigation_service.dart]]
- [[_COMMUNITY_models.dart|models.dart]]
- [[_COMMUNITY_auth_screen.dart|auth_screen.dart]]
- [[_COMMUNITY_ride_service.dart|ride_service.dart]]
- [[_COMMUNITY_crash_reporter.dart|crash_reporter.dart]]
- [[_COMMUNITY_notification_service.dart|notification_service.dart]]
- [[_COMMUNITY_map_scaffold.dart|map_scaffold.dart]]
- [[_COMMUNITY_driver_registration_screen.dart|driver_registration_screen.dart]]
- [[_COMMUNITY_firebase_service.dart|firebase_service.dart]]
- [[_COMMUNITY_premium_text_field.dart|premium_text_field.dart]]
- [[_COMMUNITY_rider_ride_completed_screen.dart|rider_ride_completed_screen.dart]]
- [[_COMMUNITY_..themeapp_spacing.dart|../theme/app_spacing.dart]]
- [[_COMMUNITY_driver_ride_summary_screen.dart|driver_ride_summary_screen.dart]]
- [[_COMMUNITY_settings_screen.dart|settings_screen.dart]]
- [[_COMMUNITY_location_model.dart|location_model.dart]]
- [[_COMMUNITY_status_badge.dart|status_badge.dart]]
- [[_COMMUNITY_location_service.dart|location_service.dart]]
- [[_COMMUNITY_otp_screen.dart|otp_screen.dart]]
- [[_COMMUNITY_premium_button.dart|premium_button.dart]]
- [[_COMMUNITY_rider_location_permission_screen.dart|rider_location_permission_screen.dart]]
- [[_COMMUNITY_screensdebug_screen.dart|screens/debug_screen.dart]]
- [[_COMMUNITY_debug_screen.dart|debug_screen.dart]]
- [[_COMMUNITY_shimmer_loading.dart|shimmer_loading.dart]]
- [[_COMMUNITY_ride_utils.dart|ride_utils.dart]]
- [[_COMMUNITY_ride_status_bar.dart|ride_status_bar.dart]]
- [[_COMMUNITY_MaterialPageRoute|MaterialPageRoute]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]
- [[_COMMUNITY_themeapp_colors.dart|theme/app_colors.dart]]
- [[_COMMUNITY_driver_service.dart|driver_service.dart]]
- [[_COMMUNITY_wWinMain|wWinMain]]
- [[_COMMUNITY_dartmath|dart:math]]
- [[_COMMUNITY_manifest.json|manifest.json]]
- [[_COMMUNITY_payment_dialog.dart|payment_dialog.dart]]
- [[_COMMUNITY_map_style_loader.dart|map_style_loader.dart]]
- [[_COMMUNITY_packagegoogle_maps_fluttergoogle_maps_flutter.dart|package:google_maps_flutter/google_maps_flutter.dart]]
- [[_COMMUNITY_GeneratedPluginRegistrant|GeneratedPluginRegistrant]]
- [[_COMMUNITY_handle_new_rx_page|handle_new_rx_page]]
- [[_COMMUNITY_dependencies|dependencies]]
- [[_COMMUNITY_MainActivity|MainActivity]]
- [[_COMMUNITY__acceptRide|_acceptRide]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_DriverNavigationToRiderScreen|DriverNavigationToRiderScreen]]
- [[_COMMUNITY_RiderActiveRideScreen|RiderActiveRideScreen]]
- [[_COMMUNITY_RiderHomeScreen|RiderHomeScreen]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_String|String?]]

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `_timer` - 13 edges
3. `MessageHandler` - 12 edges
4. `_animationController` - 10 edges
5. `FlutterWindow` - 10 edges
6. `Create` - 10 edges
7. `WndProc` - 10 edges
8. `MessageHandler` - 9 edges
9. `_animation` - 7 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (80 total, 7 thin omitted)

### Community 0 - "rider_dropoff_location_screen.dart"
Cohesion: 0.02
Nodes (89): _addressLookupTimer, _autoShowReview, _bearingBetween, bounce, _bounceAnim, _bounceController, build, _buildDropPin (+81 more)

### Community 1 - "driver_home_screen.dart"
Cohesion: 0.03
Nodes (77): DriverProfile?, FlutterRingtonePlayer, _alertTimeoutTimer, _animatedDriverPos, _availableRides, build, _buildAddressRow, _buildAvailableRidesOverlay (+69 more)

### Community 2 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 3 - "State"
Cohesion: 0.05
Nodes (58): AuthScreen, _AuthScreenState, ChatScreen, _ChatScreenState, DebugScreen, _DebugScreenState, DriverActiveRideScreen, _DriverActiveRideScreenState (+50 more)

### Community 4 - "rider_home_screen.dart"
Cohesion: 0.03
Nodes (57): DraggableScrollableController, _animateToCurrentLocation, build, _buildConnectivityBanner, _buildDriverCountBadge, _buildErrorState, _buildFloatingButton, _buildSearchBar (+49 more)

### Community 5 - "app_colors.dart"
Cohesion: 0.04
Nodes (54): accent, accentContainer, accentDark, accentGradient, accentLight, AppColors, avatarColors, background (+46 more)

### Community 6 - "app_spacing.dart"
Cohesion: 0.04
Nodes (54): appBarHeight, AppSpacing, bottomNavHeight, bottomSheetTopRadius, buttonPadding, cardPadding, cardPaddingCompact, chipPadding (+46 more)

### Community 7 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (39): Any, audioplayers_darwin, Cocoa, device_info_plus, Firebase, firebase_core, firebase_messaging, Flutter (+31 more)

### Community 8 - "driver_active_ride_screen.dart"
Cohesion: 0.04
Nodes (51): _animatedDriverPos, _awaitingPayment, build, _buildUnreadBadge, _carIcon, _completeRide, createState, _destinationLocation (+43 more)

### Community 9 - "driver_navigation_to_rider_screen.dart"
Cohesion: 0.04
Nodes (49): _animatedDriverPos, build, _buildUnreadBadge, _carIcon, createState, dispose, _distanceKm, _driverAnimTimer (+41 more)

### Community 10 - "rider_active_ride_screen.dart"
Cohesion: 0.04
Nodes (49): _animatedDriverPos, _bearingBetween, build, _buildUnreadBadge, _carIcon, createState, dispose, _driverAnimTimer (+41 more)

### Community 11 - "rider_tracking_screen.dart"
Cohesion: 0.04
Nodes (49): _animatedDriverPos, _bearingBetween, build, _buildUnreadBadge, _carIcon, createState, dispose, _driverAnimTimer (+41 more)

### Community 12 - "rider_pickup_location_screen.dart"
Cohesion: 0.04
Nodes (47): CustomPainter, _DropPinPainter, _addressLookupTimer, _bearingBetween, bounce, _bounceAnim, _bounceController, build (+39 more)

### Community 13 - "ride_model.dart"
Cohesion: 0.04
Nodes (46): acceptedAt, averageRating, cancellationReason, cancelledAt, completedAt, currentLatitude, currentLongitude, driver (+38 more)

### Community 14 - "rider_searching_driver_screen.dart"
Cohesion: 0.04
Nodes (45): _acceptanceTimer, build, _buildDriverFoundContent, _buildSearchingContent, _cancelSearch, _checkRideStatus, _continueSearch, createState (+37 more)

### Community 15 - "websocket_service.dart"
Cohesion: 0.04
Nodes (45): _channel, _channelSubscription, _chatKey, _chatMessageController, chatMessages, connect, connectionState, _connectionStateController (+37 more)

### Community 16 - "main.dart"
Cohesion: 0.05
Nodes (41): GlobalKey, build, main, _navigatorKey, _routeError, _setupChatNotificationListener, build, _buildLocationRequest (+33 more)

### Community 17 - "storage_service.dart"
Cohesion: 0.05
Nodes (42): _activeRideIdKey, _activeRideStatusKey, clearActiveRideId, clearAllData, clearUserId, _defaultServerUrl, getActiveRideId, getActiveRideStatus (+34 more)

### Community 18 - "ride_map_screen.dart"
Cohesion: 0.05
Nodes (40): _animateToLocation, build, _buildDropoffPanel, _buildPickupPanel, _calculateDistanceAndFare, _calculateDuration, _confirmDropoff, _confirmPickup (+32 more)

### Community 19 - "ride_location_picker_screen.dart"
Cohesion: 0.05
Nodes (39): _backToPickup, build, _calculateDistance, _calculateRouteAndFare, _confirmDropoff, _confirmPickup, createState, _currentLocation (+31 more)

### Community 20 - "app_typography.dart"
Cohesion: 0.06
Nodes (34): AppTypography, body, bodyLarge, bodyMedium, bodySmall, bold, caption, displayLarge (+26 more)

### Community 21 - "ride_preview_screen.dart"
Cohesion: 0.06
Nodes (33): GoogleMapController?, _addMarkers, _autoDismissTimer, build, createState, dispose, driverMode, dropoffAddress (+25 more)

### Community 22 - "chat_screen.dart"
Cohesion: 0.06
Nodes (33): activeChatPartnerId, build, _buildEmptyState, _buildMessageInput, _buildMessageList, _buildTypingIndicator, clearAllCache, clearCache (+25 more)

### Community 23 - "rider_trip_details_screen.dart"
Cohesion: 0.06
Nodes (33): build, _buildPaymentOption, _buildRideTypeCard, _calculateFare, createState, dropoffAddress, dropoffLat, dropoffLng (+25 more)

### Community 24 - "marker_factory.dart"
Cohesion: 0.07
Nodes (28): _createDot, _createPin, _createStickPin, destination, _destinationCached, _destinationMemo, driver, _driverCached (+20 more)

### Community 25 - "marker_animator.dart"
Cohesion: 0.07
Nodes (26): BitmapDescriptor, LatLng?, anchorU, anchorV, AnimatedMarkerState, animationProgress, buildMarker, clear (+18 more)

### Community 26 - "home_screen.dart"
Cohesion: 0.08
Nodes (24): chat_screen.dart, debug_screen.dart, _connectWebSocket, createState, dispose, _handleTypingIndicator, _handleUserOffline, _handleUserOnline (+16 more)

### Community 27 - "premium_card.dart"
Cohesion: 0.08
Nodes (23): dart:ui, EdgeInsets?, EdgeInsetsGeometry?, blur, borderRadius, build, child, GlassCard (+15 more)

### Community 28 - "my_application.cc"
Cohesion: 0.10
Nodes (20): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+12 more)

### Community 29 - "background_navigation_service.dart"
Cohesion: 0.09
Nodes (23): @pragma, BackgroundNavigationService, _channelId, initialize, _instance, _isRunning, _locationTimer, _navigationType (+15 more)

### Community 30 - "models.dart"
Cohesion: 0.08
Nodes (23): int?, content, copyWith, createdAt, deviceToken, email, fromJson, fullName (+15 more)

### Community 31 - "auth_screen.dart"
Cohesion: 0.08
Nodes (23): _animController, _buildLoginForm, _buildPillToggle, _buildRegisterForm, _buildRoleCard, createState, dispose, _emailController (+15 more)

### Community 32 - "ride_service.dart"
Cohesion: 0.09
Nodes (22): dart:io, acceptRide, cancelRide, completeRide, confirmPayment, confirmPaymentReceived, continueSearch, disputePayment (+14 more)

### Community 33 - "crash_reporter.dart"
Cohesion: 0.09
Nodes (22): addLog, clearLogs, _crashLogs, CrashReporter, dispose, getFormattedLogs, _getLogFile, init (+14 more)

### Community 34 - "notification_service.dart"
Cohesion: 0.09
Nodes (22): _chatChannelId, _createRideAlertChannel, init, _initialized, _instance, isInitialized, _messageId, navigatorKey (+14 more)

### Community 35 - "map_scaffold.dart"
Cohesion: 0.10
Nodes (21): bottom_sheet_handle.dart, MyApp, _BouncingDots, DriverInfoCard, appBar, backgroundColor, bottomSheet, build (+13 more)

### Community 36 - "driver_registration_screen.dart"
Cohesion: 0.10
Nodes (21): build, _checkExistingProfile, createState, dispose, DriverRegistrationScreen, _DriverRegistrationScreenState, initState, _isLoading (+13 more)

### Community 37 - "firebase_service.dart"
Cohesion: 0.09
Nodes (21): body, _currentFcmToken, data, FirebaseService, _handleNotificationTap, init, _messaging, _onForegroundMessage (+13 more)

### Community 38 - "premium_text_field.dart"
Cohesion: 0.10
Nodes (21): build, controller, createState, dispose, enabled, _focusNode, _hasFocus, hint (+13 more)

### Community 39 - "rider_ride_completed_screen.dart"
Cohesion: 0.10
Nodes (20): build, _buildAddressSection, _buildSummaryRow, createState, dispose, distance, duration, _feedbackController (+12 more)

### Community 40 - "../theme/app_spacing.dart"
Cohesion: 0.11
Nodes (18): double?, IconData, build, driverName, licensePlate, onChatTap, rating, unreadCount (+10 more)

### Community 41 - "driver_ride_summary_screen.dart"
Cohesion: 0.11
Nodes (19): build, _buildAddressSection, _buildDetailRow, createState, dispose, DriverRideSummaryScreen, _DriverRideSummaryScreenState, _feedbackController (+11 more)

### Community 42 - "settings_screen.dart"
Cohesion: 0.11
Nodes (19): build, _buildAboutCard, _buildProfileCard, _buildSectionHeader, _buildServerConfigCard, createState, dispose, initState (+11 more)

### Community 43 - "location_model.dart"
Cohesion: 0.11
Nodes (18): DateTime?, address, baseFare, description, fromJson, icon, latitude, LocationData (+10 more)

### Community 44 - "status_badge.dart"
Cohesion: 0.11
Nodes (18): active, arriving, build, cancelled, color, completed, confirmed, _controller (+10 more)

### Community 45 - "location_service.dart"
Cohesion: 0.11
Nodes (17): calculateDistance, calculateFare, checkPermissionStatus, ensureServiceAndPermission, _formatGeocodeResponse, getAddressFromCoordinates, getCoordinatesFromAddress, getCurrentLocation (+9 more)

### Community 46 - "otp_screen.dart"
Cohesion: 0.12
Nodes (16): home_screen.dart, build, _buildMailIcon, _buildTimerOrResend, createState, dispose, email, _formatTime (+8 more)

### Community 47 - "premium_button.dart"
Cohesion: 0.12
Nodes (15): bool get, borderRadius, build, ButtonVariant, createState, _enabled, height, icon (+7 more)

### Community 48 - "rider_location_permission_screen.dart"
Cohesion: 0.12
Nodes (15): class, _bounceController, build, _checkLocationService, createState, dispose, initState, _isLoading (+7 more)

### Community 49 - "screens/debug_screen.dart"
Cohesion: 0.12
Nodes (15): dart:async, calculateFare, _degToRad, DirectionsResult, DirectionsService, distanceKm, durationMinutes, _fallback (+7 more)

### Community 50 - "debug_screen.dart"
Cohesion: 0.12
Nodes (15): addDebugMessage, build, _buildCrashReports, _buildDebugLogs, _clearAll, _copyToClipboard, createState, debugMessages (+7 more)

### Community 51 - "shimmer_loading.dart"
Cohesion: 0.12
Nodes (15): _animationController, baseColor, borderRadius, build, circular, _controller, createState, dispose (+7 more)

### Community 52 - "ride_utils.dart"
Cohesion: 0.12
Nodes (15): a, baseFare, c, calculateEstimatedFare, calculateHaversineDistance, dLat, dLng, earthRadius (+7 more)

### Community 53 - "ride_status_bar.dart"
Cohesion: 0.13
Nodes (14): Color get, IconData get, _animation, build, _color, _controller, createState, dispose (+6 more)

### Community 54 - "MaterialPageRoute"
Cohesion: 0.13
Nodes (15): build, _openChat, _showMenuSheet, _showRidePreview, _openChat, build, _openChat, _submitRideRequest (+7 more)

### Community 55 - "package:flutter/material.dart"
Cohesion: 0.17
Nodes (10): app_colors.dart, app_spacing.dart, app_typography.dart, AppTheme, CancelRideResult, confirmed, reason, reasonController (+2 more)

### Community 56 - "theme/app_colors.dart"
Cohesion: 0.17
Nodes (10): Color, BottomSheetHandle, build, color, reason, reasonController, received, ReceivedPaymentResult (+2 more)

### Community 57 - "driver_service.dart"
Cohesion: 0.17
Nodes (11): dart:convert, DriverService, getActiveRide, getDriverProfile, getNearbyDrivers, registerAsDriver, toggleOnlineStatus, updateLocation (+3 more)

### Community 58 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 59 - "dart:math"
Cohesion: 0.18
Nodes (10): dart:math, bearing, calculateBearing, calculateCarRotation, dLng, lat1, lat2, normalizeCarHeading (+2 more)

### Community 60 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 61 - "payment_dialog.dart"
Cohesion: 0.22
Nodes (8): confirmed, PaymentDialogResult, reason, result, showPaymentDialog, title, true, required double amount,
  String

### Community 62 - "map_style_loader.dart"
Cohesion: 0.25
Nodes (7): _cachedStyle, clearCache, load, MapStyleLoader, package:flutter/services.dart, static String?, static String? get

### Community 63 - "package:google_maps_flutter/google_maps_flutter.dart"
Cohesion: 0.25
Nodes (7): getGreenPinMarker, getPickupPinMarker, getPurplePinMarker, getRedPinMarker, getYellowPinMarker, marker_factory.dart, package:google_maps_flutter/google_maps_flutter.dart

### Community 64 - "GeneratedPluginRegistrant"
Cohesion: 0.47
Nodes (4): GeneratedPluginRegistrant, String, FlutterEngine, Keep

### Community 65 - "handle_new_rx_page"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 66 - "dependencies"
Cohesion: 0.50
Nodes (3): dependencies, framer-motion, pngjs

### Community 68 - "_acceptRide"
Cohesion: 0.67
Nodes (3): _acceptRide, _buildActiveRideCard, Route /driver-navigation

## Knowledge Gaps
- **1479 isolated node(s):** `flutter_export_environment.sh script`, `GoogleMaps`, `Firebase`, `+registerWithRegistry`, `_navigatorKey` (+1474 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_timer` connect `background_navigation_service.dart` to `rider_dropoff_location_screen.dart`, `driver_home_screen.dart`, `rider_home_screen.dart`, `driver_active_ride_screen.dart`, `driver_navigation_to_rider_screen.dart`, `rider_active_ride_screen.dart`, `rider_tracking_screen.dart`, `rider_pickup_location_screen.dart`, `rider_searching_driver_screen.dart`, `ride_preview_screen.dart`, `chat_screen.dart`, `marker_animator.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `_animationController` connect `shimmer_loading.dart` to `rider_dropoff_location_screen.dart`, `rider_tracking_screen.dart`, `rider_pickup_location_screen.dart`, `status_badge.dart`, `rider_searching_driver_screen.dart`, `rider_location_permission_screen.dart`, `main.dart`, `ride_status_bar.dart`, `auth_screen.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `_animation` connect `ride_status_bar.dart` to `rider_dropoff_location_screen.dart`, `rider_tracking_screen.dart`, `rider_pickup_location_screen.dart`, `status_badge.dart`, `rider_searching_driver_screen.dart`, `auth_screen.dart`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_export_environment.sh script`, `GoogleMaps` to the rest of the system?**
  _1480 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `rider_dropoff_location_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022222222222222223 - nodes in this community are weakly interconnected._
- **Should `driver_home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02564102564102564 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._