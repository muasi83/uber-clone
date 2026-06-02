import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class RiderRoutePreviewScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double estimatedDistance;
  final double estimatedFare;
  final int estimatedDuration;
  final String rideType;

  const RiderRoutePreviewScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.estimatedDistance,
    required this.estimatedFare,
    required this.estimatedDuration,
    required this.rideType,
  });

  @override
  State<RiderRoutePreviewScreen> createState() =>
      _RiderRoutePreviewScreenState();
}

class _RiderRoutePreviewScreenState extends State<RiderRoutePreviewScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeRoute();
  }

  Future<void> _initializeRoute() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🗺️  ROUTE PREVIEW INITIALIZING');
      addDebugMessage('From: ${widget.pickupAddress}');
      addDebugMessage('To: ${widget.dropoffAddress}');

      final route = await DirectionsService.getDirections(
        origin: LatLng(widget.pickupLat, widget.pickupLng),
        destination: LatLng(widget.dropoffLat, widget.dropoffLng),
      );

      if (!mounted) return;

      if (route == null || !route.isSuccess) {
        setState(() {
          _error = 'Could not load route';
          _isLoading = false;
        });
        addDebugMessage('❌ Route fetch failed');
        return;
      }

      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat, widget.pickupLng),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.dropoffLat, widget.dropoffLng),
          infoWindow: const InfoWindow(title: 'Dropoff'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      if (route.polylinePoints != null && route.polylinePoints!.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: route.polylinePoints!,
            color: AppColors.primary,
            width: 5,
            geodesic: true,
            patterns: [
              PatternItem.dash(30),
              PatternItem.gap(20),
            ],
          ),
        );
        addDebugMessage(
            '✅ Route loaded with ${route.polylinePoints!.length} points');
      }

      setState(() => _isLoading = false);

      _fitBounds();

      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Route error: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading route: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.pickupLat < widget.dropoffLat
            ? widget.pickupLat - 0.01
            : widget.dropoffLat - 0.01,
        widget.pickupLng < widget.dropoffLng
            ? widget.pickupLng - 0.01
            : widget.dropoffLng - 0.01,
      ),
      northeast: LatLng(
        widget.pickupLat > widget.dropoffLat
            ? widget.pickupLat + 0.01
            : widget.dropoffLat + 0.01,
        widget.pickupLng > widget.dropoffLng
            ? widget.pickupLng + 0.01
            : widget.dropoffLng + 0.01,
      ),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          if (_error != null)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _error = null);
                            _initializeRoute();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Transparent AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Route Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
            ),
          ),

          // Bottom glass card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassCard(
              borderRadius: AppSpacing.radiusXxl,
              blur: 30,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    AppSpacing.gapLg,

                    // Pickup
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppSpacing.gapXs,
                              Text(
                                widget.pickupAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,

                    // Dropoff
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dropoff',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppSpacing.gapXs,
                              Text(
                                widget.dropoffAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapLg,

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    AppSpacing.gapLg,

                    // Stats row: Distance | Duration | Fare
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${widget.estimatedDistance.toStringAsFixed(2)} km',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.access_time,
                            label: 'Duration',
                            value: '${widget.estimatedDuration} min',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.attach_money,
                            label: 'Fare',
                            value: '\$${widget.estimatedFare.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,

                    // Ride type badge
                    Row(
                      children: [
                        StatusBadge(
                          label: widget.rideType,
                          icon: widget.rideType == 'LUXURY'
                              ? Icons.directions_car
                              : Icons.local_taxi,
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                    AppSpacing.gapLg,

                    // Request Ride button
                    PremiumButton(
                      label: _isLoading ? 'Loading...' : 'Request Ride',
                      isLoading: _isLoading,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, {
                                'routeConfirmed': true,
                                'pickupLat': widget.pickupLat,
                                'pickupLng': widget.pickupLng,
                                'pickupAddress': widget.pickupAddress,
                                'dropoffLat': widget.dropoffLat,
                                'dropoffLng': widget.dropoffLng,
                                'dropoffAddress': widget.dropoffAddress,
                                'estimatedDistance': widget.estimatedDistance,
                                'estimatedFare': widget.estimatedFare,
                                'estimatedDuration': widget.estimatedDuration,
                                'rideType': widget.rideType,
                              }),
                      icon: _isLoading ? null : Icons.navigation,
                      variant: ButtonVariant.gradient,
                      height: 56,
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
        AppSpacing.gapXs,
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        AppSpacing.gapXs,
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
