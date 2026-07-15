import 'dart:convert';

class EventCategory {
  static const business = 'BUSINESS';
  static const network = 'NETWORK';
  static const frontend = 'FRONTEND';
  static const backend = 'BACKEND';
  static const webSocket = 'WEBSOCKET';
  static const database = 'DATABASE';
  static const gps = 'GPS';
  static const payments = 'PAYMENTS';
  static const notifications = 'NOTIFICATIONS';
  static const recovery = 'RECOVERY';
  static const scheduler = 'SCHEDULER';
  static const ui = 'UI';
  static const system = 'SYSTEM';

  static const all = [
    business, network, frontend, backend, webSocket,
    database, gps, payments, notifications, recovery,
    scheduler, ui, system,
  ];

  static String displayName(String cat) {
    switch (cat) {
      case business: return 'Business';
      case network: return 'Network';
      case frontend: return 'Frontend';
      case backend: return 'Backend';
      case webSocket: return 'WebSocket';
      case database: return 'Database';
      case gps: return 'GPS';
      case payments: return 'Payments';
      case notifications: return 'Notifications';
      case recovery: return 'Recovery';
      case scheduler: return 'Scheduler';
      case ui: return 'UI';
      case system: return 'System';
      default: return cat;
    }
  }
}

class TripBehaviourEvent {
  final int? id;
  final int? rideId;
  final String? correlationId;
  final DateTime? timestamp;
  final int? durationMs;
  final int? stageNumber;
  final String? rideStatus;
  final String? previousRideStatus;
  final String? nextRideStatus;
  final String? actor;
  final int? actorId;
  final String? actorName;
  final String? currentScreen;
  final String? businessFunction;
  final String? category;
  final String? eventName;
  final String? component;
  final String? restEndpoint;
  final String? restMethod;
  final int? restStatus;
  final String? wsEventName;
  final String? wsDirection;
  final String? wsDeliveryStatus;
  final String? backendController;
  final String? backendService;
  final String? backendRepository;
  final String? dbTable;
  final String? dbOperation;
  final String? notificationType;
  final String? notificationStatus;
  final String? paymentState;
  final double? passengerLat;
  final double? passengerLng;
  final double? driverLat;
  final double? driverLng;
  final String? internetQuality;
  final String? result;
  final String? severity;
  final String? summary;
  final Map<String, dynamic>? details;
  final bool? anomaly;
  final String? anomalyType;
  final String? anomalySuggestion;

  TripBehaviourEvent({
    this.id, this.rideId, this.correlationId, this.timestamp,
    this.durationMs, this.stageNumber, this.rideStatus,
    this.previousRideStatus, this.nextRideStatus, this.actor,
    this.actorId, this.actorName, this.currentScreen,
    this.businessFunction, this.category, this.eventName,
    this.component, this.restEndpoint, this.restMethod,
    this.restStatus, this.wsEventName, this.wsDirection,
    this.wsDeliveryStatus, this.backendController,
    this.backendService, this.backendRepository, this.dbTable,
    this.dbOperation, this.notificationType, this.notificationStatus,
    this.paymentState, this.passengerLat, this.passengerLng,
    this.driverLat, this.driverLng, this.internetQuality,
    this.result, this.severity, this.summary, this.details,
    this.anomaly, this.anomalyType, this.anomalySuggestion,
  });

  factory TripBehaviourEvent.fromJson(Map<String, dynamic> json) {
    return TripBehaviourEvent(
      id: json['id'] as int?,
      rideId: json['rideId'] as int?,
      correlationId: json['correlationId'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
      durationMs: json['durationMs'] as int?,
      stageNumber: json['stageNumber'] as int?,
      rideStatus: json['rideStatus'] as String?,
      previousRideStatus: json['previousRideStatus'] as String?,
      nextRideStatus: json['nextRideStatus'] as String?,
      actor: json['actor'] as String?,
      actorId: json['actorId'] as int?,
      actorName: json['actorName'] as String?,
      currentScreen: json['currentScreen'] as String?,
      businessFunction: json['businessFunction'] as String?,
      category: json['category'] as String?,
      eventName: json['eventName'] as String?,
      component: json['component'] as String?,
      restEndpoint: json['restEndpoint'] as String?,
      restMethod: json['restMethod'] as String?,
      restStatus: json['restStatus'] as int?,
      wsEventName: json['wsEventName'] as String?,
      wsDirection: json['wsDirection'] as String?,
      wsDeliveryStatus: json['wsDeliveryStatus'] as String?,
      backendController: json['backendController'] as String?,
      backendService: json['backendService'] as String?,
      backendRepository: json['backendRepository'] as String?,
      dbTable: json['dbTable'] as String?,
      dbOperation: json['dbOperation'] as String?,
      notificationType: json['notificationType'] as String?,
      notificationStatus: json['notificationStatus'] as String?,
      paymentState: json['paymentState'] as String?,
      passengerLat: (json['passengerLat'] as num?)?.toDouble(),
      passengerLng: (json['passengerLng'] as num?)?.toDouble(),
      driverLat: (json['driverLat'] as num?)?.toDouble(),
      driverLng: (json['driverLng'] as num?)?.toDouble(),
      internetQuality: json['internetQuality'] as String?,
      result: json['result'] as String?,
      severity: json['severity'] as String?,
      summary: json['summary'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      anomaly: json['anomaly'] as bool?,
      anomalyType: json['anomalyType'] as String?,
      anomalySuggestion: json['anomalySuggestion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (rideId != null) 'rideId': rideId,
    if (correlationId != null) 'correlationId': correlationId,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    if (durationMs != null) 'durationMs': durationMs,
    if (stageNumber != null) 'stageNumber': stageNumber,
    if (rideStatus != null) 'rideStatus': rideStatus,
    if (actor != null) 'actor': actor,
    if (actorName != null) 'actorName': actorName,
    if (category != null) 'category': category,
    if (eventName != null) 'eventName': eventName,
    if (severity != null) 'severity': severity,
    if (summary != null) 'summary': summary,
    if (details != null) 'details': details,
  };

  String get categoryDisplay => EventCategory.displayName(category ?? '');

  String get severityIcon {
    switch (severity) {
      case 'ERROR': return '❌';
      case 'WARNING': return '⚠️';
      case 'INFO': return 'ℹ️';
      default: return '';
    }
  }
}

class TripSummary {
  final int? rideId;
  final String? rideStatus;
  final String? duration;
  final int? durationMs;
  final int? healthScore;
  final int? warningCount;
  final int? errorCount;
  final int? recoveryCount;
  final int? networkInterruptions;
  final int? paymentRetries;
  final int? wsReconnects;
  final int? gpsInterruptions;
  final String? longestStage;
  final int? longestStageMs;
  final List<String>? possibleIssues;

  TripSummary({
    this.rideId, this.rideStatus, this.duration, this.durationMs,
    this.healthScore, this.warningCount, this.errorCount,
    this.recoveryCount, this.networkInterruptions, this.paymentRetries,
    this.wsReconnects, this.gpsInterruptions, this.longestStage,
    this.longestStageMs, this.possibleIssues,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      rideId: json['rideId'] as int?,
      rideStatus: json['rideStatus'] as String?,
      duration: json['duration'] as String?,
      durationMs: json['durationMs'] as int?,
      healthScore: json['healthScore'] as int?,
      warningCount: json['warningCount'] as int?,
      errorCount: json['errorCount'] as int?,
      recoveryCount: json['recoveryCount'] as int?,
      networkInterruptions: json['networkInterruptions'] as int?,
      paymentRetries: json['paymentRetries'] as int?,
      wsReconnects: json['wsReconnects'] as int?,
      gpsInterruptions: json['gpsInterruptions'] as int?,
      longestStage: json['longestStage'] as String?,
      longestStageMs: json['longestStageMs'] as int?,
      possibleIssues: (json['possibleIssues'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class TripAnomaly {
  final String? type;
  final String? message;
  final String? severity;
  final String? timestamp;

  TripAnomaly({this.type, this.message, this.severity, this.timestamp});

  factory TripAnomaly.fromJson(Map<String, dynamic> json) {
    return TripAnomaly(
      type: json['type'] as String?,
      message: json['message'] as String?,
      severity: json['severity'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}

class TripBehaviourResponse {
  final TripSummary? summary;
  final List<TripBehaviourEvent> events;
  final List<TripAnomaly> warnings;
  final List<TripAnomaly> anomalies;
  final int? totalEvents;
  final int? totalPages;
  final int? currentPage;
  final bool? hasMore;

  TripBehaviourResponse({
    this.summary, required this.events, this.warnings = const [],
    this.anomalies = const [], this.totalEvents, this.totalPages,
    this.currentPage, this.hasMore,
  });

  factory TripBehaviourResponse.fromJson(Map<String, dynamic> json) {
    return TripBehaviourResponse(
      summary: json['summary'] != null ? TripSummary.fromJson(json['summary'] as Map<String, dynamic>) : null,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => TripBehaviourEvent.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((w) => TripAnomaly.fromJson(w as Map<String, dynamic>))
              .toList() ?? [],
      anomalies: (json['anomalies'] as List<dynamic>?)
              ?.map((a) => TripAnomaly.fromJson(a as Map<String, dynamic>))
              .toList() ?? [],
      totalEvents: json['totalEvents'] as int?,
      totalPages: json['totalPages'] as int?,
      currentPage: json['currentPage'] as int?,
      hasMore: json['hasMore'] as bool?,
    );
  }
}

class TripReplaySnapshot {
  final int? stageNumber;
  final String? stageName;
  final DateTime? timestamp;
  final String? rideStatus;
  final double? passengerLat;
  final double? passengerLng;
  final double? driverLat;
  final double? driverLng;
  final String? currentRoutePolyline;
  final String? paymentState;
  final String? backendActivity;
  final String? wsEventName;
  final String? restRequest;
  final String? notificationInfo;
  final String? gpsInfo;
  final String? networkInfo;
  final String? errorInfo;
  final String? warningInfo;
  final String? recoveryInfo;
  final int? durationMs;
  final String? summary;
  final String? severity;

  TripReplaySnapshot({
    this.stageNumber, this.stageName, this.timestamp, this.rideStatus,
    this.passengerLat, this.passengerLng, this.driverLat, this.driverLng,
    this.currentRoutePolyline, this.paymentState, this.backendActivity,
    this.wsEventName, this.restRequest, this.notificationInfo, this.gpsInfo,
    this.networkInfo, this.errorInfo, this.warningInfo, this.recoveryInfo,
    this.durationMs, this.summary, this.severity,
  });

  factory TripReplaySnapshot.fromJson(Map<String, dynamic> json) {
    return TripReplaySnapshot(
      stageNumber: json['stageNumber'] as int?,
      stageName: json['stageName'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
      rideStatus: json['rideStatus'] as String?,
      passengerLat: (json['passengerLat'] as num?)?.toDouble(),
      passengerLng: (json['passengerLng'] as num?)?.toDouble(),
      driverLat: (json['driverLat'] as num?)?.toDouble(),
      driverLng: (json['driverLng'] as num?)?.toDouble(),
      currentRoutePolyline: json['currentRoutePolyline'] as String?,
      paymentState: json['paymentState'] as String?,
      backendActivity: json['backendActivity'] as String?,
      wsEventName: json['wsEventName'] as String?,
      restRequest: json['restRequest'] as String?,
      notificationInfo: json['notificationInfo'] as String?,
      gpsInfo: json['gpsInfo'] as String?,
      networkInfo: json['networkInfo'] as String?,
      errorInfo: json['errorInfo'] as String?,
      warningInfo: json['warningInfo'] as String?,
      recoveryInfo: json['recoveryInfo'] as String?,
      durationMs: json['durationMs'] as int?,
      summary: json['summary'] as String?,
      severity: json['severity'] as String?,
    );
  }
}

class TripReplayResponse {
  final int? rideId;
  final List<TripReplaySnapshot> snapshots;
  final int? totalSnapshots;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? rideType;
  final String? rideStatus;
  final String? estimatedDuration;
  final String? estimatedDistance;

  TripReplayResponse({
    this.rideId, required this.snapshots, this.totalSnapshots,
    this.pickupLat, this.pickupLng, this.dropoffLat, this.dropoffLng,
    this.pickupAddress, this.dropoffAddress, this.rideType,
    this.rideStatus, this.estimatedDuration, this.estimatedDistance,
  });

  factory TripReplayResponse.fromJson(Map<String, dynamic> json) {
    return TripReplayResponse(
      rideId: json['rideId'] as int?,
      snapshots: (json['snapshots'] as List<dynamic>?)
              ?.map((s) => TripReplaySnapshot.fromJson(s as Map<String, dynamic>))
              .toList() ?? [],
      totalSnapshots: json['totalSnapshots'] as int?,
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoffLng'] as num?)?.toDouble(),
      pickupAddress: json['pickupAddress'] as String?,
      dropoffAddress: json['dropoffAddress'] as String?,
      rideType: json['rideType'] as String?,
      rideStatus: json['rideStatus'] as String?,
      estimatedDuration: json['estimatedDuration'] as String?,
      estimatedDistance: json['estimatedDistance'] as String?,
    );
  }
}
