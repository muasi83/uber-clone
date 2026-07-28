import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/place_search_service.dart';
import '../screens/rider_dropoff_location_screen.dart';
import '../widgets/location_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum _FieldType { pickup, dropoff }

class RideCollectorScreen extends StatefulWidget {
  const RideCollectorScreen({super.key});

  @override
  State<RideCollectorScreen> createState() => _RideCollectorScreenState();
}

class _RideCollectorScreenState extends State<RideCollectorScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _pickupFocus = FocusNode();
  final _dropoffFocus = FocusNode();

  bool _isSearching = false;
  bool _searchedOnce = false;
  List<PlaceSearchResult> _searchResults = [];
  Timer? _debounce;

  double? _pickupLat;
  double? _pickupLng;
  String _pickupAddress = '';

  double? _dropoffLat;
  double? _dropoffLng;
  String _dropoffAddress = '';

  double? _lastNavPickupLat;
  double? _lastNavPickupLng;
  String _lastNavPickupAddress = '';
  double? _lastNavDropoffLat;
  double? _lastNavDropoffLng;
  String _lastNavDropoffAddress = '';

  _FieldType? _activeField;
  _FieldType? _lastActiveField;
  int _searchSequence = 0;
  bool _isProgrammaticChange = false;

  bool _isNavigating = false;

  String _userLanguage = 'en';

  static const String _mapButtonAsset = 'assets/images/map_button.png';
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _pickupController.addListener(_onPickupChanged);
    _dropoffController.addListener(_onDropoffChanged);
    _pickupFocus.addListener(_onFocusChanged);
    _dropoffFocus.addListener(_onFocusChanged);
    _initUserContext();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initUserContext() async {
    try {
      final lang = Platform.localeName.split('_').firstOrNull ?? 'en';
      if (mounted) setState(() => _userLanguage = lang);
    } catch (_) {}
  }

  void _onFocusChanged() {
    setState(() {
      if (_pickupFocus.hasFocus) {
        _activeField = _FieldType.pickup;
      } else if (_dropoffFocus.hasFocus) {
        _activeField = _FieldType.dropoff;
      } else {
        _activeField = null;
      }
      if (_activeField != _lastActiveField) {
        _searchedOnce = false;
        _lastActiveField = _activeField;
      }
    });
  }

  void _onPickupChanged() {
    if (_isProgrammaticChange) return;
    setState(() => _activeField = _FieldType.pickup);
    _debounceSearch(_pickupController.text);
  }

  void _onDropoffChanged() {
    if (_isProgrammaticChange) return;
    setState(() => _activeField = _FieldType.dropoff);
    _debounceSearch(_dropoffController.text);
  }

  void _debounceSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _searchSequence++;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchedOnce = false;
        if (_activeField == _FieldType.pickup && _pickupController.text.isEmpty) {
          _pickupLat = null;
          _pickupLng = null;
          _pickupAddress = '';
        } else if (_activeField == _FieldType.dropoff && _dropoffController.text.isEmpty) {
          _dropoffLat = null;
          _dropoffLng = null;
          _dropoffAddress = '';
        }
      });
      return;
    }
    _debounce = Timer(_debounceDuration, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    _searchSequence++;
    final seq = _searchSequence;
    setState(() => _isSearching = true);
    try {
      final language = _searchLanguage(query);
      final results = await PlaceSearchService.search(
        query.trim(),
        language: language,
      );
      if (mounted && seq == _searchSequence) {
        final currentText = _activeControllerText;
        if (query.trim() != currentText.trim()) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _searchedOnce = true;
        });
      }
    } catch (e) {
      if (mounted && seq == _searchSequence) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchedOnce = true;
        });
      }
    }
  }

  String _searchLanguage(String query) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(query) ? 'ar' : _userLanguage;
  }

  String get _activeControllerText {
    if (_activeField == _FieldType.pickup) return _pickupController.text;
    if (_activeField == _FieldType.dropoff) return _dropoffController.text;
    return '';
  }

  Future<void> _onSelectResult(PlaceSearchResult result) async {
    final field = _activeField;

    PlaceDetails? details;
    try {
      details = await PlaceSearchService.getPlaceDetails(result.placeId, language: _userLanguage);
    } catch (_) {
      details = null;
    }

    if (!mounted) return;
    if (_activeField != field) return;

    final lat = details?.lat;
    final lng = details?.lng;
    final address = details?.address ?? result.description;

    _isProgrammaticChange = true;
    try {
      if (field == _FieldType.pickup) {
        _pickupController.text = result.description;
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupAddress = address;
        _pickupFocus.unfocus();
      } else if (field == _FieldType.dropoff) {
        _dropoffController.text = result.description;
        _dropoffLat = lat;
        _dropoffLng = lng;
        _dropoffAddress = address;
        _dropoffFocus.unfocus();
      }
    } finally {
      _isProgrammaticChange = false;
    }
    setState(() => _searchResults = []);

    _checkAndNavigate();
  }

  Future<void> _onMapButton(_FieldType field) async {
    final l10n = AppLocalizations.of(context);
    final initialLat = field == _FieldType.pickup ? _pickupLat : _dropoffLat;
    final initialLng = field == _FieldType.pickup ? _pickupLng : _dropoffLng;
    final mode = field == _FieldType.pickup ? LocationPickerMode.pickup : LocationPickerMode.dropoff;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          mode: mode,
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );
    print('MAP_RESULT = $result');

    if (result != null && mounted) {
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      final address = result['address'] as String? ?? l10n.selectedLocation;

      _isProgrammaticChange = true;
      try {
        if (field == _FieldType.pickup) {
          _pickupController.text = address;
          _pickupLat = lat;
          _pickupLng = lng;
          _pickupAddress = address;
        } else {
          _dropoffController.text = address;
          _dropoffLat = lat;
          _dropoffLng = lng;
          _dropoffAddress = address;
        }
      } finally {
        _isProgrammaticChange = false;
      }
      setState(() {});

      _checkAndNavigate();
    }
  }

  bool get _bothReady =>
      _pickupLat != null &&
      _pickupLng != null &&
      _pickupAddress.isNotEmpty &&
      _dropoffLat != null &&
      _dropoffLng != null &&
      _dropoffAddress.isNotEmpty;

  bool get _valuesChangedSinceNavigation =>
      _pickupLat != _lastNavPickupLat ||
      _pickupLng != _lastNavPickupLng ||
      _pickupAddress != _lastNavPickupAddress ||
      _dropoffLat != _lastNavDropoffLat ||
      _dropoffLng != _lastNavDropoffLng ||
      _dropoffAddress != _lastNavDropoffAddress;

  void _saveNavigationValues() {
    _lastNavPickupLat = _pickupLat;
    _lastNavPickupLng = _pickupLng;
    _lastNavPickupAddress = _pickupAddress;
    _lastNavDropoffLat = _dropoffLat;
    _lastNavDropoffLng = _dropoffLng;
    _lastNavDropoffAddress = _dropoffAddress;
  }

  void _checkAndNavigate() {
    if (!_bothReady) return;
    if (_isNavigating) return;
    _isNavigating = true;
    _saveNavigationValues();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderDropoffLocationScreen(
          pickupLat: _pickupLat!,
          pickupLng: _pickupLng!,
          pickupAddress: _pickupAddress,
          dropoffLat: _dropoffLat!,
          dropoffLng: _dropoffLng!,
          dropoffAddress: _dropoffAddress,
        ),
      ),
    ).then((_) {
      _isNavigating = false;
      if (mounted && _bothReady && _valuesChangedSinceNavigation) {
        _checkAndNavigate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.requestANewRide,
          style: const TextStyle(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildPickupField(),
              const SizedBox(height: 8),
              _buildDropoffField(),
              const SizedBox(height: 12),
              _buildSearchResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickupField() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdRadius,
              ),
              child: TextField(
                controller: _pickupController,
                focusNode: _pickupFocus,
                decoration: InputDecoration(
                  hintText: l10n.pickupLocation,
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIcon: Icon(
                    _searchIcon(_pickupFocus.hasFocus),
                    size: 20,
                    color: AppColors.primary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pickupController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _pickupLat = null;
                              _pickupLng = null;
                              _pickupAddress = '';
                            });
                            _pickupController.clear();
                          },
                          color: AppColors.textTertiary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: InkWell(
                          borderRadius: AppRadius.mdRadius,
                          onTap: () => _onMapButton(_FieldType.pickup),
                          child: ClipRRect(
                            borderRadius: AppRadius.mdRadius,
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.mdRadius,
                              ),
                              child: Image.asset(_mapButtonAsset, width: 30, height: 30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildDropoffField() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.mdRadius,
              ),
              child: TextField(
                controller: _dropoffController,
                focusNode: _dropoffFocus,
                decoration: InputDecoration(
                  hintText: l10n.dropoffLocation,
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIcon: Icon(
                    _searchIcon(_dropoffFocus.hasFocus),
                    size: 20,
                    color: AppColors.error,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dropoffController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _dropoffLat = null;
                              _dropoffLng = null;
                              _dropoffAddress = '';
                            });
                            _dropoffController.clear();
                          },
                          color: AppColors.textTertiary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: InkWell(
                          borderRadius: AppRadius.mdRadius,
                          onTap: () => _onMapButton(_FieldType.dropoff),
                          child: ClipRRect(
                            borderRadius: AppRadius.mdRadius,
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.mdRadius,
                              ),
                              child: Image.asset(_mapButtonAsset, width: 30, height: 30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.dropoffMarker,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  IconData _searchIcon(bool isFocused) {
    return isFocused ? Icons.search_rounded : Icons.circle_outlined;
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context);
    if (_searchResults.isEmpty && !_isSearching) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Center(
          child: Text(
            _searchedOnce
                ? l10n.noLocationsFound
                : (_activeField != null
                    ? l10n.startTypingToSearchLocations
                    : ''),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _isSearching) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Stack(
        children: [
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 40),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  result.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _onSelectResult(result),
              );
            },
          ),
          if (_isSearching)
            const Positioned(
              top: 4,
              right: 28,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
