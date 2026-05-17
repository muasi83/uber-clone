import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import '../screens/debug_screen.dart';

class RiderDropoffLocationScreen extends StatefulWidget {
  final LocationData pickupLocation;
  final Function(LocationData) onLocationSelected;

  const RiderDropoffLocationScreen({
    Key? key,
    required this.pickupLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<RiderDropoffLocationScreen> createState() =>
      _RiderDropoffLocationScreenState();
}

class _RiderDropoffLocationScreenState
    extends State<RiderDropoffLocationScreen> {
  late GoogleMapController mapController;
  LocationData? _selectedLocation;
  Set<Marker> _markers = {};
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  List<LocationData> _searchResults = [];
  bool _mapCreated = false;
  List<LocationData> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('📍 DROPOFF LOCATION SCREEN LOADED');
    addDebugMessage('Pickup Location: ${widget.pickupLocation.address}');
    addDebugMessage('═══════════════════════════════════════');

    _addPickupMarker();
    _loadRecentLocations();
  }

  void _addPickupMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            widget.pickupLocation.latitude,
            widget.pickupLocation.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.pickupLocation.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      };
    });
  }

  void _addDropoffMarker(LocationData location) {
    setState(() {
      _markers = {
        // Pickup marker
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            widget.pickupLocation.latitude,
            widget.pickupLocation.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.pickupLocation.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        // Dropoff marker
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: 'Dropoff Location',
            snippet: location.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      };
    });
  }

  Future<void> _loadRecentLocations() async {
    try {
      addDebugMessage('📋 Loading recent locations...');
      // In a real app, you would get this from ride history
      // For now, we'll show some example locations
      setState(() {
        _recentLocations = [
          LocationData(
            latitude: 40.7580,
            longitude: -73.9855,
            address: 'Times Square, New York, NY',
          ),
          LocationData(
            latitude: 40.7489,
            longitude: -73.9680,
            address: 'Grand Central Terminal, New York, NY',
          ),
          LocationData(
            latitude: 40.7505,
            longitude: -73.9972,
            address: 'Central Park, New York, NY',
          ),
        ];
      });
      addDebugMessage('✅ Loaded ${_recentLocations.length} recent locations');
    } catch (e) {
      addDebugMessage('❌ Error loading recent locations: $e');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      addDebugMessage('🔍 Searching for: $query');

      final location = await LocationService.getCoordinatesFromAddress(query);

      if (location != null) {
        addDebugMessage('✅ Search result found');
        setState(() {
          _searchResults = [location];
        });
      } else {
        addDebugMessage('❌ No results found');
        setState(() => _searchResults = []);
        if (mounted) {
          _showError('Address not found. Please try another search.');
        }
      }
    } catch (e) {
      addDebugMessage('❌ Search error: $e');
      _showError('Search error: $e');
      setState(() => _searchResults = []);
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSearchResult(LocationData location) {
    addDebugMessage('✅ Selected from search: ${location.address}');
    setState(() {
      _selectedLocation = location;
      _searchController.text = location.address;
      _searchResults = [];
      _addDropoffMarker(location);
    });

    // Animate camera to show both markers
    if (_mapCreated) {
      _fitBoundsBetweenLocations();
    }
  }

  void _selectRecentLocation(LocationData location) {
    addDebugMessage('✅ Selected recent location: ${location.address}');
    setState(() {
      _selectedLocation = location;
      _searchController.text = location.address;
      _searchResults = [];
      _addDropoffMarker(location);
    });

    // Animate camera
    if (_mapCreated) {
      _fitBoundsBetweenLocations();
    }
  }

  void _fitBoundsBetweenLocations() {
    if (_selectedLocation == null) return;

    final double minLat = widget.pickupLocation.latitude <
            _selectedLocation!.latitude
        ? widget.pickupLocation.latitude
        : _selectedLocation!.latitude;

    final double maxLat = widget.pickupLocation.latitude >
            _selectedLocation!.latitude
        ? widget.pickupLocation.latitude
        : _selectedLocation!.latitude;

    final double minLng = widget.pickupLocation.longitude <
            _selectedLocation!.longitude
        ? widget.pickupLocation.longitude
        : _selectedLocation!.longitude;

    final double maxLng = widget.pickupLocation.longitude >
            _selectedLocation!.longitude
        ? widget.pickupLocation.longitude
        : _selectedLocation!.longitude;

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() => _mapCreated = true);

    mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          widget.pickupLocation.latitude,
          widget.pickupLocation.longitude,
        ),
      ),
    );
  }

  void _onMapLongPress(LatLng position) async {
    addDebugMessage(
        '📍 Long press on map: ${position.latitude}, ${position.longitude}');

    try {
      final address =
          await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final location = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address ?? 'Unknown Location',
        timestamp: DateTime.now(),
      );

      setState(() {
        _selectedLocation = location;
        _searchController.text = location.address;
        _searchResults = [];
        _addDropoffMarker(location);
      });

      _fitBoundsBetweenLocations();
      _showSuccess('Dropoff location selected!');
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      _showError('Error selecting location: $e');
    }
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      _showError('Please select a dropoff location');
      return;
    }

    if (_selectedLocation!.latitude == widget.pickupLocation.latitude &&
        _selectedLocation!.longitude == widget.pickupLocation.longitude) {
      _showError('Dropoff location cannot be the same as pickup location');
      return;
    }

    addDebugMessage('✅ Dropoff location confirmed: ${_selectedLocation!.address}');
    widget.onLocationSelected(_selectedLocation!);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm Dropoff Location',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.pickupLocation.latitude,
                widget.pickupLocation.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            onLongPress: _onMapLongPress,
          ),

          // Center Pin Indicator
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 30,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: IgnorePointer(
              child: Icon(
                Icons.location_on,
                size: 60,
                color: Colors.red,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar and Location Button
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search address...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6366F1),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.isNotEmpty) {
                        _searchAddress(value);
                      }
                    },
                  ),
                ),

                // Search Results or Recent Locations
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF6366F1),
                          ),
                          title: Text(result.address),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  )
                else if (_searchController.text.isEmpty &&
                    _recentLocations.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Recent Places',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentLocations.length,
                          itemBuilder: (context, index) {
                            final location = _recentLocations[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.history,
                                color: Color(0xFF6366F1),
                              ),
                              title: Text(location.address),
                              onTap: () =>
                                  _selectRecentLocation(location),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Info Card and Confirm Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dropoff Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null)
                      Text(
                        _selectedLocation!.address,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Select a location',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Confirm Dropoff Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Tip: Long press on map to select a location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}