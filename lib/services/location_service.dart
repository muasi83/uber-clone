import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../screens/debug_screen.dart';
import '../models/location_model.dart';
import 'storage_service.dart';

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

  /// Reverse geocode — tries backend first, then direct Google API
  /// Returns formatted address: {CountryCode}-{CityCode3}-{District}-{Street}
  static Future<String?> getFormattedAddress(double latitude, double longitude) async {
    try {
      // 1) Try backend endpoint
      final serverUrl = StorageService.getServerUrl();
      if (serverUrl.isNotEmpty) {
        final backendUrl = '$serverUrl/api/routes/geocode?lat=$latitude&lng=$longitude';
        addDebugMessage('📍 Geocoding via backend: $backendUrl');
        try {
          final token = StorageService.getToken();
          final headers = <String, String>{
            'ngrok-skip-browser-warning': 'true',
          };
          if (token != null && token.trim().isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
          }
          final backendRes = await http
              .get(Uri.parse(backendUrl), headers: headers)
              .timeout(const Duration(seconds: 10));
          if (backendRes.statusCode == 200) {
            final json = jsonDecode(backendRes.body) as Map<String, dynamic>;
            final result = _formatGeocodeResponse(json);
            if (result != null) return result;
          }
        } catch (_) {
          addDebugMessage('ℹ️ Backend geocode unavailable, trying direct API');
        }
      }

      // 2) Fallback: direct Google Geocoding API (works on web + mobile)
      const googleKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      if (googleKey.isEmpty) {
        addDebugMessage('❌ GOOGLE_MAPS_API_KEY not set — skipping direct geocode');
        return null;
      }
      final directUrl = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$latitude,$longitude&key=$googleKey&language=en';

      addDebugMessage('📍 Geocoding direct: $directUrl');
      final directRes = await http
          .get(Uri.parse(directUrl))
          .timeout(const Duration(seconds: 10));

      if (directRes.statusCode == 200) {
        final root = jsonDecode(directRes.body) as Map<String, dynamic>;
        final status = root['status'] as String? ?? '';
        addDebugMessage('📍 Direct geocode status: $status');

        if (status == 'OK') {
          final results = root['results'] as List? ?? [];
          if (results.isNotEmpty) {
            final first = results[0] as Map<String, dynamic>;
            final formattedAddress = first['formatted_address'] as String? ?? '';

            String countryCode = '', city = '', district = '', street = '';
            final components = first['address_components'] as List? ?? [];
            for (final comp in components) {
              final c = comp as Map<String, dynamic>;
              final types = (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
              final longName = (c['long_name'] as String? ?? '');
              final shortName = (c['short_name'] as String? ?? '');

              if (types.contains('country')) {
                countryCode = shortName;
              } else if (types.contains('locality')) {
                city = longName;
              } else if (types.contains('sublocality') || types.contains('sublocality_level_1') || types.contains('neighborhood')) {
                district = longName;
              } else if (types.contains('administrative_area_level_1') && city.isEmpty) {
                city = longName;
              } else if (types.contains('route')) {
                street = longName;
              }
            }

            // If no district, try extracting from formatted address
            if (district.isEmpty && formattedAddress.contains(',')) {
              final commaParts = formattedAddress.split(',');
              if (commaParts.length >= 3) {
                final possible = commaParts[commaParts.length - 3].trim();
                if (!possible.contains(RegExp(r'^\d')) && possible.length < 40) {
                  district = possible;
                }
              }
            }

            // Build result
            final cc = countryCode.toUpperCase() == 'SA' ? 'KSA' : countryCode.toUpperCase();
            final cityCode = city.length >= 3
                ? city.substring(0, 3).toUpperCase()
                : city.isNotEmpty ? city.toUpperCase() : '';

            String shortStreet = '';
            if (street.isNotEmpty) {
              final segs = street
                  .split(RegExp(r'[,،/]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty && !RegExp(r'^\d+$').hasMatch(s))
                  .toList();
              shortStreet = segs.isNotEmpty ? segs.last : street;
              if (shortStreet.length > 25) {
                final words = shortStreet.split(' ');
                final kept = <String>[];
                for (final w in words) {
                  if ((kept.join(' ').length + w.length) > 20) break;
                  kept.add(w);
                }
                shortStreet = kept.isNotEmpty ? kept.join(' ') : words.first;
              }
            }

            final parts = <String>[];
            if (cc.isNotEmpty) parts.add(cc);
            if (cityCode.isNotEmpty) parts.add(cityCode);
            if (district.isNotEmpty) parts.add(district);
            if (shortStreet.isNotEmpty) parts.add(shortStreet);

            if (parts.length >= 2) {
              final result = parts.join('-');
              addDebugMessage('✅ Formatted: $result');
              return result;
            }

            // Last fallback: just use district from formatted address
            if (district.isNotEmpty) {
              final fb = <String>[];
              if (cc.isNotEmpty) fb.add(cc);
              if (cityCode.isNotEmpty) fb.add(cityCode);
              fb.add(district);
              final result = fb.join('-');
              addDebugMessage('✅ District-only: $result');
              return result;
            }
          }
        }
      }
    } catch (e) {
      addDebugMessage('❌ Geocoding error: $e');
    }
    return null;
  }

  static String? _formatGeocodeResponse(Map<String, dynamic> json) {
    final countryCode = (json['countryCode'] as String? ?? '').trim().toUpperCase();
    final cc = countryCode == 'SA' ? 'KSA' : (countryCode.isNotEmpty ? countryCode : '');
    final district = (json['district'] as String? ?? '').trim();
    final street = (json['street'] as String? ?? '').trim();
    final city = (json['city'] as String? ?? '').trim();
    final formatted = (json['formattedAddress'] as String? ?? '').trim();

    final cityCode = city.length >= 3
        ? city.substring(0, 3).toUpperCase()
        : city.isNotEmpty ? city.toUpperCase() : '';

    String shortStreet = '';
    if (street.isNotEmpty) {
      final segments = street
          .split(RegExp(r'[,،/]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !RegExp(r'^\d+$').hasMatch(s))
          .toList();
      shortStreet = segments.isNotEmpty ? segments.last : street;
      if (shortStreet.length > 25) {
        final words = shortStreet.split(' ');
        final kept = <String>[];
        for (final w in words) {
          if ((kept.join(' ').length + w.length) > 20) break;
          kept.add(w);
        }
        shortStreet = kept.isNotEmpty ? kept.join(' ') : words.first;
      }
    }

    final parts = <String>[];
    if (cc.isNotEmpty) parts.add(cc);
    if (cityCode.isNotEmpty) parts.add(cityCode);
    if (district.isNotEmpty) parts.add(district);
    if (shortStreet.isNotEmpty) parts.add(shortStreet);

    if (parts.length >= 2) {
      addDebugMessage('✅ Backend formatted: ${parts.join('-')}');
      return parts.join('-');
    }

    // Fallback: extract from formatted address
    if (formatted.isNotEmpty && formatted.contains(',')) {
      final commaParts = formatted.split(',');
      if (commaParts.length >= 3) {
        final districtFallback = commaParts[commaParts.length - 3].trim();
        if (districtFallback.length < 40) {
          final fb = <String>[];
          if (cc.isNotEmpty) fb.add(cc);
          if (cityCode.isNotEmpty) fb.add(cityCode);
          fb.add(districtFallback);
          addDebugMessage('✅ Backend fallback: ${fb.join('-')}');
          return fb.join('-');
        }
      }
    }
    return null;
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