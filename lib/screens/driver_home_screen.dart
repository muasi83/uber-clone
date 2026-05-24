import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/driver_service.dart';
import '../services/websocket_service.dart';
import '../services/directions_service.dart';
import '../services/storage_service.dart';
import '../screens/settings_screen.dart';
import '../screens/debug_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String token;

  const DriverHomeScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.token,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  List<Ride> _availableRides = [];
  Ride? _currentRide;
  DriverProfile? _driverProfile;
  bool _isLoading = false;
  bool _isOnline = false;
  final Map<int, RouteData> _routeCache = {};

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 DRIVER HOME SCREEN LOADED');
    addDebugMessage('User: ${widget.username}');
    addDebugMessage('═══════════════════════════════════════');

    _loadDriverProfile();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    addDebugMessage('🔌 Connecting WebSocket for Driver...');
    WebSocketService.connect(widget.userId, widget.username);
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    try {
      WebSocketService.rideEvents.listen((event) {
        final type = event['type'] ?? '';
        if (type == 'ride_available') {
          addDebugMessage('📥 New ride request received');
          _loadAvailableRides();
        }
      });
    } catch (e) {
      addDebugMessage('⚠️ WebSocket listener error: $e');
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await DriverService.getDriverProfile(widget.token);

      if (profile != null) {
        setState(() => _driverProfile = profile);
        addDebugMessage('✅ Driver profile loaded');
      } else {
        addDebugMessage('⚠️ Driver profile is null');
        setState(() => _driverProfile = null);
      }
    } catch (e) {
      addDebugMessage('❌ Error loading driver profile: $e');
      setState(() => _driverProfile = null);
    }
  }

  Future<void> _loadAvailableRides() async {
    setState(() => _isLoading = true);
    try {
      final rides = await RideService.getAvailableRides(widget.token);
      setState(() => _availableRides = rides);
      addDebugMessage('✅ Found ${rides.length} available rides');

      // Preload route data for each ride
      for (var ride in rides) {
        try {
          final route = await DirectionsService.getDirections(
            origin: LatLng(ride.pickupLatitude ?? 0, ride.pickupLongitude ?? 0),
            destination: LatLng(ride.dropoffLatitude ?? 0, ride.dropoffLongitude ?? 0),
          );

          if (route != null && mounted) {
            setState(() {
              _routeCache[ride.id ?? 0] = RouteData(
                polylinePoints: route.polylinePoints,
                totalDistanceKm: route.distanceKm,
                totalDurationMinutes: route.durationMinutes,
              );
            });
          }
        } catch (e) {
          addDebugMessage('⚠️ Route preload error for ride ${ride.id}: $e');
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error loading rides: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnline() async {
    addDebugMessage('🔄 Toggling online status...');
    try {
      final result = await DriverService.toggleOnlineStatus(widget.token);

      if (result) {
        setState(() => _isOnline = !_isOnline);
        addDebugMessage('✅ Online status: $_isOnline');

        if (_isOnline) {
          _loadAvailableRides();
        }
      } else {
        _showError('Failed to toggle online status');
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _acceptRide(int rideId) async {
    try {
      final ride = await RideService.acceptRide(rideId, widget.token);
      if (ride != null && mounted) {
        setState(() => _currentRide = ride);
        _availableRides.removeWhere((r) => r.id == rideId);

        if (mounted) {
          Navigator.pushNamed(
            context,
            '/driver-navigation',
            arguments: {
              'rideId': rideId,
              'pickupAddress': ride.pickupAddress,
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride accepted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error accepting ride: $e');
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await http
                    .post(
                      Uri.parse(
                          '${StorageService.getServerUrl()}/api/users/${widget.userId}/logout'),
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                      },
                    )
                    .timeout(const Duration(seconds: 10));
              } catch (e) {
                // Continue logout
              }

              try {
                WebSocketService.setOffline(widget.userId);
                WebSocketService.disconnect();
              } catch (e) {
                // Continue logout
              }

              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/splash',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚗 Driver Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              _isOnline ? '🟢 Online' : '🔴 Offline',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Console',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DebugScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(username: widget.username),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            _loadAvailableRides();
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildAvailableRidesTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Online Toggle
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isOnline ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (_) => _toggleOnline(),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Current Ride
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Ride',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _currentRide != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rider: ${_currentRide!.rider.fullName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'From: ${_currentRide!.pickupAddress}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To: ${_currentRide!.dropoffAddress}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No active ride',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Go to Available tab to find rides',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRidesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _availableRides.isEmpty
            ? RefreshIndicator(
                onRefresh: _loadAvailableRides,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No available rides',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadAvailableRides,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                            ),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAvailableRides,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = _availableRides[index];
                    final routeData = _routeCache[ride.id];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ride.rideType,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${ride.estimatedFare?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mini map
                            if (routeData != null &&
                                routeData.polylinePoints != null &&
                                routeData.polylinePoints!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 150,
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: routeData.polylinePoints![0],
                                      zoom: 14,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId:
                                            const MarkerId('pickup'),
                                        position: LatLng(
                                          ride.pickupLatitude ?? 0,
                                          ride.pickupLongitude ?? 0,
                                        ),
                                        icon: BitmapDescriptor
                                            .defaultMarkerWithHue(
                                          BitmapDescriptor.hueGreen,
                                        ),
                                      ),
                                      Marker(
                                        markerId:
                                            const MarkerId('dropoff'),
                                        position: LatLng(
                                          ride.dropoffLatitude ?? 0,
                                          ride.dropoffLongitude ?? 0,
                                        ),
                                        icon: BitmapDescriptor
                                            .defaultMarkerWithHue(
                                          BitmapDescriptor.hueRed,
                                        ),
                                      ),
                                    },
                                    polylines: {
                                      Polyline(
                                        polylineId:
                                            const PolylineId('route'),
                                        points:
                                            routeData.polylinePoints!,
                                        color: Colors.blue,
                                        width: 4,
                                        geodesic: true,
                                      ),
                                    },
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                    myLocationButtonEnabled: false,
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Details
                            Text(
                              'From: ${ride.pickupAddress}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To: ${ride.dropoffAddress}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),

                            // Info row
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                if (routeData != null)
                                  Text(
                                    '${routeData.totalDistanceKm?.toStringAsFixed(1) ?? '0.0'} km • ${routeData.totalDurationMinutes ?? 0} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                else
                                  const SizedBox(),
                                ElevatedButton(
                                  onPressed: () => _acceptRide(ride.id ?? 0),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6366F1),
                                  ),
                                  child: const Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildProfileTab() {
    if (_driverProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Driver Profile Not Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to register as a driver first',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDriverProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Driver Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileRow(
                    'Name',
                    _driverProfile!.user.fullName,
                  ),
                  _buildProfileRow(
                    'License',
                    _driverProfile!.licenseNumber ?? 'Not provided',
                  ),
                  _buildProfileRow(
                    'Vehicle',
                    '${_driverProfile!.vehicleModel ?? 'Unknown'} (${_driverProfile!.vehicleColor ?? 'Unknown'})',
                  ),
                  _buildProfileRow(
                    'Vehicle #',
                    _driverProfile!.vehicleNumber ?? 'Not provided',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_driverProfile!.averageRating.toStringAsFixed(1)} ⭐',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Rides',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_driverProfile!.totalRides}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WebSocketService.disconnect();
    super.dispose();
  }
}

class RouteData {
  final List<LatLng>? polylinePoints;
  final double? totalDistanceKm;
  final int? totalDurationMinutes;

  RouteData({
    this.polylinePoints,
    this.totalDistanceKm,
    this.totalDurationMinutes,
  });
}