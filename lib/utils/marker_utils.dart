import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'marker_factory.dart';

Future<BitmapDescriptor> getPickupPinMarker() => MarkerFactory.pickup;

Future<BitmapDescriptor> getYellowPinMarker() => getPickupPinMarker();

Future<BitmapDescriptor> getGreenPinMarker() => getPickupPinMarker();

Future<BitmapDescriptor> getRedPinMarker() => MarkerFactory.dropoff;

Future<BitmapDescriptor> getPurplePinMarker() => MarkerFactory.destination;
