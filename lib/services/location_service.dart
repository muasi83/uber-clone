import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../screens/debug_screen.dart';
import '../models/location_model.dart';

class LocationService {
  static Future<bool> ensureServiceAndPermission({bool openSettingsIfNeeded = false}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        addDebugMessage('❌ Location services disabled');
        if (openSettingsIfNeeded) {
          await Geolocator.openLocationSettings();
        }
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
        addDebugMessage('❌ Location permission not granted: $permission');
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        addDebugMessage('❌ Location permission denied forever');
        if (openSettingsIfNeeded) {
          await Geolocator.openAppSettings();
        }
        return false;
      }

      addDebugMessage('✅ Location service+permission OK: $permission');
      return true;
    } catch (e) {
      addDebugMessage('❌ ensureServiceAndPermission error: $e');
      return false;
    }
  }

  // Get current location with address
  static Future<LocationData?> getCurrentLocation() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📍 GETTING CURRENT LOCATION');

      final ok = await ensureServiceAndPermission();
      if (!ok) return null;

      // Try last known first (fast), then current (accurate)
      final lastKnown = await Geolocator.getLastKnownPosition();

      Position position;
      if (lastKnown != null) {
        position = lastKnown;
      } else {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 12),
          ),
        );
      }

      addDebugMessage('✅ Location obtained');
      addDebugMessage('Latitude: ${position.latitude}');
      addDebugMessage('Longitude: ${position.longitude}');

      final address = await getAddressFromCoordinates(position.latitude, position.longitude);

      addDebugMessage('✅ Address: $address');
      addDebugMessage('═══════════════════════════════════════');

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address ?? 'Unknown Location',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      addDebugMessage('❌ Error getting current location: $e');
      return null;
    }
  }

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      addDebugMessage('❌ Error checking location service: $e');
      return false;
    }
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔐 REQUESTING LOCATION PERMISSION');

      final permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.always:
          addDebugMessage('✅ Permission: ALWAYS');
          break;
        case LocationPermission.whileInUse:
          addDebugMessage('✅ Permission: WHILE IN USE');
          break;
        case LocationPermission.denied:
          addDebugMessage('❌ Permission: DENIED');
          break;
        case LocationPermission.deniedForever:
          addDebugMessage('❌ Permission: DENIED FOREVER');
          break;
        case LocationPermission.unableToDetermine:
          addDebugMessage('⚠️ Permission: UNABLE TO DETERMINE');
          break;
      }

      addDebugMessage('═══════════════════════════════════════');
      return permission;
    } catch (e) {
      addDebugMessage('❌ Error requesting permission: $e');
      rethrow;
    }
  }

  // Reverse Geocoding
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      addDebugMessage('🔄 Reverse geocoding...');
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address = '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
        addDebugMessage('✅ Address found: $address');
        return address;
      }

      addDebugMessage('❌ No address found');
      return null;
    } catch (e) {
      addDebugMessage('❌ Reverse geocoding error: $e');
      return null;
    }
  }

  // Forward Geocoding
  static Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔍 FORWARD GEOCODING');
      addDebugMessage('Address: $address');

      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations[0];
        addDebugMessage('✅ Coordinates found');
        addDebugMessage('Latitude: ${location.latitude}');
        addDebugMessage('Longitude: ${location.longitude}');
        addDebugMessage('═══════════════════════════════════════');

        final fullAddress = await getAddressFromCoordinates(location.latitude, location.longitude);

        return LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          address: fullAddress ?? address,
          timestamp: DateTime.now(),
        );
      }

      addDebugMessage('❌ No coordinates found for address');
      addDebugMessage('═══════════════════════════════════════');
      return null;
    } catch (e) {
      addDebugMessage('❌ Geocoding error: $e');
      addDebugMessage('═══════════════════════════════════════');
      return null;
    }
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    try {
      final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
      return distance / 1000;
    } catch (e) {
      addDebugMessage('❌ Error calculating distance: $e');
      return 0.0;
    }
  }

  static double calculateFare(double distance, RideType rideType) {
    try {
      final fare = rideType.baseFare + (distance * rideType.perKmRate);
      return double.parse(fare.toStringAsFixed(2));
    } catch (e) {
      addDebugMessage('❌ Error calculating fare: $e');
      return 0.0;
    }
  }

  static Stream<LocationData> watchLocation({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 10,
  }) async* {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('👁️ WATCHING LOCATION IN REAL-TIME');

      final ok = await ensureServiceAndPermission();
      if (!ok) return;

      final positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      );

      await for (final position in positionStream) {
        final address = await getAddressFromCoordinates(position.latitude, position.longitude);
        addDebugMessage('📍 Location update: ${position.latitude}, ${position.longitude}');

        yield LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address ?? 'Unknown Location',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error watching location: $e');
    }
  }

  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      addDebugMessage('❌ Error opening location settings: $e');
      return false;
    }
  }

  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      addDebugMessage('❌ Error opening app settings: $e');
      return false;
    }
  }

  static Future<LocationPermission> checkPermissionStatus() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      addDebugMessage('❌ Error checking permission: $e');
      rethrow;
    }
  }
}