import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/ride_location_picker_screen.dart';
import '../models/models.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({Key? key}) : super(key: key);

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _selectedIndex = 0;
  List<Ride> _rideHistory = [];
  Ride? _currentRide;
  bool _isLoadingRides = false;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ RIDER HOME SCREEN INITIALIZED');
    addDebugMessage('═══════════════════════════════════════');
    _loadRideHistory();
    _setupWebSocketListeners();
  }

  /// Setup WebSocket listeners for real-time ride updates
  void _setupWebSocketListeners() {
    try {
      addDebugMessage('🔌 Setting up WebSocket listeners for Rider');
      
      WebSocketService.onRideStatusUpdate = (Map<String, dynamic> data) {
        addDebugMessage('📡 Ride status update received: ${data['status']}');
        
        if (mounted) {
          setState(() {
            if (_currentRide != null && _currentRide!.id == data['rideId']) {
              _currentRide = _currentRide!.copyWith(
                status: data['status'],
              );
            }
          });
        }
      };
      
      addDebugMessage('✅ WebSocket listeners configured');
    } catch (e) {
      addDebugMessage('❌ Error setting up listeners: $e');
    }
  }

  /// Load ride history from backend
  Future<void> _loadRideHistory() async {
    try {
      setState(() => _isLoadingRides = true);
      
      final token = StorageService.getToken();
      if (token == null) {
        addDebugMessage('❌ No token found');
        setState(() => _isLoadingRides = false);
        return;
      }

      addDebugMessage('📋 Loading ride history...');
      final rides = await RideService.getRideHistory(token);
      
      if (mounted) {
        setState(() {
          _rideHistory = rides;
          
          // Find current active ride
          try {
            _currentRide = rides.firstWhere(
              (ride) => ride.status == 'REQUESTED' || 
                       ride.status == 'ACCEPTED' || 
                       ride.status == 'STARTED',
            );
            addDebugMessage('✅ Found active ride: ${_currentRide!.id}');
          } catch (e) {
            _currentRide = null;
            addDebugMessage('ℹ️ No active rides');
          }
          
          _isLoadingRides = false;
        });
      }
      
      addDebugMessage('✅ Loaded ${rides.length} rides total');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRides = false);
      }
      addDebugMessage('❌ Error loading rides: $e');
    }
  }

  /// Request a new ride - opens RideLocationPickerScreen
  Future<void> _requestRide() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🚗 REQUEST RIDE BUTTON TAPPED');
      addDebugMessage('═══════════════════════════════════════');
      
      // ✅ CHECK LOCATION PERMISSION FIRST
      addDebugMessage('📍 Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      addDebugMessage('Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        addDebugMessage('⚠️ Permission denied - requesting from user...');
        permission = await Geolocator.requestPermission();
        addDebugMessage('Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          addDebugMessage('❌ User denied location permission');
          if (mounted) {
            _showError('Location permission is required to request a ride');
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        addDebugMessage('❌ Location permission denied forever');
        if (mounted) {
          _showError('Please enable location in app settings');
        }
        return;
      }
      
      addDebugMessage('✅ Location permission granted');
      addDebugMessage('📍 Opening RideLocationPickerScreen...');
      
      // ✅ OPEN RIDE LOCATION PICKER SCREEN
      if (mounted) {
        final rideDetails = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => const RideLocationPickerScreen(),
          ),
        );
        
        // User selected ride details
        if (rideDetails != null) {
          addDebugMessage('✅ User returned from location picker with ride details');
          await _submitRideRequest(rideDetails);
        } else {
          addDebugMessage('ℹ️ User cancelled location picker');
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error requesting ride: $e');
      if (mounted) {
        _showError('Error: $e');
      }
    }
  }

  /// Submit ride request to backend with all details from location picker
  Future<void> _submitRideRequest(Map<String, dynamic> rideDetails) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📤 SUBMITTING RIDE REQUEST TO BACKEND');
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('From: ${rideDetails['pickupAddress']}');
      addDebugMessage('To: ${rideDetails['dropoffAddress']}');
      addDebugMessage('Type: ${rideDetails['rideType']}');
      addDebugMessage('Distance: ${rideDetails['estimatedDistance']?.toStringAsFixed(2)} km');
      addDebugMessage('Duration: ${rideDetails['estimatedDuration']} min');
      addDebugMessage('Fare: \$${rideDetails['estimatedFare']?.toStringAsFixed(2)}');
      addDebugMessage('═══════════════════════════════════════');

      final token = StorageService.getToken();
      if (token == null) {
        addDebugMessage('❌ No authentication token found');
        _showError('Authentication error. Please login again.');
        return;
      }

      // ✅ SUBMIT WITH ALL REQUIRED FIELDS FROM LOCATION PICKER
      final ride = await RideService.requestRide(
        pickupLat: rideDetails['pickupLat'],
        pickupLng: rideDetails['pickupLng'],
        pickupAddress: rideDetails['pickupAddress'],
        dropoffLat: rideDetails['dropoffLat'],
        dropoffLng: rideDetails['dropoffLng'],
        dropoffAddress: rideDetails['dropoffAddress'],
        rideType: rideDetails['rideType'] ?? 'ECONOMY',
        estimatedDistance: rideDetails['estimatedDistance'] ?? 0.0,
        estimatedFare: rideDetails['estimatedFare'] ?? 0.0,
        estimatedDuration: rideDetails['estimatedDuration'] ?? 0,
        token: token,
      );

      if (ride != null) {
        addDebugMessage('✅ RIDE CREATED SUCCESSFULLY');
        addDebugMessage('Ride ID: ${ride.id}');
        addDebugMessage('Status: ${ride.status}');
        
        if (mounted) {
          setState(() {
            _currentRide = ride;
          });
          
          _showSuccess('Ride requested! Waiting for driver...');
          
          // Reload ride history
          await _loadRideHistory();
        }
      } else {
        addDebugMessage('❌ Backend returned null ride object');
        _showError('Failed to request ride. Please try again.');
      }
    } catch (e) {
      addDebugMessage('❌ ERROR SUBMITTING RIDE: $e');
      addDebugMessage('Stack trace: $e');
      _showError('Error: $e');
    }
  }

  /// Build current ride card
  Widget _buildCurrentRideCard() {
    // No active ride
    if (_currentRide == null || _currentRide!.status == 'NONE') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No active ride',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Request a Ride" to get started',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active ride exists
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentRide!.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentRide!.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // From address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _currentRide!.pickupAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // To address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _currentRide!.dropoffAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Driver info (if assigned)
            if (_currentRide!.driver != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _currentRide!.driver!.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            
            // Distance, duration, fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn(
                  label: 'Distance',
                  value: '${_currentRide!.estimatedDistance?.toStringAsFixed(2) ?? '0.00'} km',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildDetailColumn(
                  label: 'Duration',
                  value: '${_currentRide!.estimatedDuration ?? 0} min',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildDetailColumn(
                  label: 'Fare',
                  value: '\$${_currentRide!.estimatedFare?.toStringAsFixed(2) ?? '0.00'}',
                  isHighlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isHighlight ? const Color(0xFF6366F1) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for ride status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'REQUESTED':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'STARTED':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Build home tab
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: ListView(
        children: [
          _buildCurrentRideCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _requestRide,
              icon: const Icon(Icons.add),
              label: const Text('Request a Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build rides history tab
  Widget _buildRidesTab() {
    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: _isLoadingRides
          ? const Center(child: CircularProgressIndicator())
          : _rideHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rides yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _rideHistory.length,
                  itemBuilder: (context, index) {
                    final ride = _rideHistory[index];
                    return _buildRideHistoryCard(ride);
                  },
                ),
    );
  }

  Widget _buildRideHistoryCard(Ride ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ride.pickupAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.dropoffAddress,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ride.estimatedDistance?.toStringAsFixed(2) ?? '0.00'} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${ride.estimatedDuration ?? 0} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '\$${ride.estimatedFare?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build messages tab
  Widget _buildMessagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Logout
  Future<void> _logout() async {
    try {
      addDebugMessage('🚪 LOGGING OUT');
      WebSocketService.disconnect();
      await StorageService.clearAllData();
      addDebugMessage('✅ Logged out');

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = StorageService.getUsername() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uber Clone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome, $username',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'debug') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 18),
                    SizedBox(width: 12),
                    Text('Debug'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomeTab()
          : _selectedIndex == 1
              ? _buildRidesTab()
              : _buildMessagesTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}