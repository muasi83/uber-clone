import 'package:flutter/material.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/rider_searching_driver_screen.dart';
import '../screens/debug_screen.dart';

class RiderTripDetailsScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double estimatedDistance;
  final int estimatedDuration;
  final String initialRideType;

  const RiderTripDetailsScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.estimatedDistance,
    required this.estimatedDuration,
    this.initialRideType = 'ECONOMY',
  });

  @override
  State<RiderTripDetailsScreen> createState() => _RiderTripDetailsScreenState();
}

class _RiderTripDetailsScreenState extends State<RiderTripDetailsScreen> {
  late String _selectedRideType;
  late double _selectedFare;
  String _selectedPaymentMethod = 'CASH';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRideType = widget.initialRideType;
    _selectedFare = _calculateFare(widget.initialRideType);

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('💳 TRIP DETAILS');
    addDebugMessage('Distance: ${widget.estimatedDistance.toStringAsFixed(2)} km');
    addDebugMessage('═══════════════════════════════════════');
  }

  double _calculateFare(String rideType) {
    const baseFare = 2.0;
    final ratePerKm = rideType == 'ECONOMY' ? 0.20 : 0.35;
    return baseFare + (widget.estimatedDistance * ratePerKm);
  }

  void _updateRideType(String rideType) {
    final newFare = _calculateFare(rideType);

    setState(() {
      _selectedRideType = rideType;
      _selectedFare = newFare;
    });

    addDebugMessage(
        '💱 Ride type: $rideType - \$${newFare.toStringAsFixed(2)}');
  }

  Future<void> _submitRideRequest() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📤 SUBMITTING RIDE REQUEST');
      addDebugMessage('Type: $_selectedRideType');
      addDebugMessage('Payment: $_selectedPaymentMethod');
      addDebugMessage('═══════════════════════════════════════');

      final token = StorageService.getToken();
      if (token == null) {
        _showError('Authentication error');
        return;
      }

      final ride = await RideService.requestRide(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        pickupAddress: widget.pickupAddress,
        dropoffLat: widget.dropoffLat,
        dropoffLng: widget.dropoffLng,
        dropoffAddress: widget.dropoffAddress,
        rideType: _selectedRideType,
        estimatedDistance: widget.estimatedDistance,
        estimatedFare: _selectedFare,
        estimatedDuration: widget.estimatedDuration,
        token: token,
      );

      if (ride != null && mounted) {
        addDebugMessage('✅ Ride created: ${ride.id}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiderSearchingDriverScreen(
              rideId: ride.id!,
              pickupAddress: widget.pickupAddress,
              dropoffAddress: widget.dropoffAddress,
              estimatedFare: _selectedFare,
            ),
          ),
        );
      } else {
        _showError('Failed to request ride');
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('WALLET', Icons.account_balance_wallet),
            _buildPaymentOption('CASH', Icons.money),
            _buildPaymentOption('CARD', Icons.credit_card),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6366F1)),
      title: Text(method),
      trailing: _selectedPaymentMethod == method
          ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
          : null,
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
        Navigator.pop(context);
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: const Text(
          'Trip Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // From
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.green, size: 20),
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
                                widget.pickupAddress,
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
                    // To
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 20),
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
                                widget.dropoffAddress,
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
                    const SizedBox(height: 16),
                    // Summary row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.straighten,
                                  color: Colors.grey, size: 18),
                              const SizedBox(height: 4),
                              Text(
                                'Distance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.estimatedDistance.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.grey, size: 18),
                              const SizedBox(height: 4),
                              Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.estimatedDuration} min',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ride Type Selection
            Text(
              'Choose Ride Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // ECONOMY Card
            _buildRideTypeCard(
              type: 'ECONOMY',
              icon: Icons.local_taxi,
              description: 'Affordable, everyday rides',
              rate: '\$0.20/km',
              isSelected: _selectedRideType == 'ECONOMY',
            ),
            const SizedBox(height: 12),
            // LUXURY Card
            _buildRideTypeCard(
              type: 'LUXURY',
              icon: Icons.directions_car,
              description: 'Premium vehicles, top drivers',
              rate: '\$0.35/km',
              isSelected: _selectedRideType == 'LUXURY',
            ),
            const SizedBox(height: 24),

            // Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showPaymentMethodSelector,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedPaymentMethod == 'WALLET'
                              ? Icons.account_balance_wallet
                              : _selectedPaymentMethod == 'CASH'
                                  ? Icons.money
                                  : Icons.credit_card,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        Text(_selectedPaymentMethod),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fare Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Fare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${_selectedFare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRideRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSubmitting ? 'Requesting...' : 'Confirm Trip',
                  style: TextStyle(
                    color: _isSubmitting ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypeCard({
    required String type,
    required IconData icon,
    required String description,
    required String rate,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _updateRideType(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rate,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_selectedFare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}