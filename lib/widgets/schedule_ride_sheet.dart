import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../services/storage_service.dart';
import '../services/scheduled_ride_service.dart';
import '../services/place_search_service.dart';
import '../screens/debug_screen.dart';
import '../screens/map_picker_screen.dart';

enum _FieldType { pickup, dropoff }

class ScheduleRideSheet extends StatefulWidget {
  final DateTime selectedDate;
  const ScheduleRideSheet({super.key, required this.selectedDate});

  @override
  State<ScheduleRideSheet> createState() => _ScheduleRideSheetState();
}

class _ScheduleRideSheetState extends State<ScheduleRideSheet> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _pickupFocus = FocusNode();
  final _dropoffFocus = FocusNode();

  bool _isScheduling = false;
  bool _isSearching = false;
  bool _searchedOnce = false;
  List<PlaceSearchResult> _searchResults = [];
  Timer? _debounce;

  String? _pickupPlaceId;
  String? _dropoffPlaceId;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  _FieldType? _activeField;
  _FieldType? _lastActiveField;
  int _searchSequence = 0;
  bool _isProgrammaticChange = false;

  static const String _mapButtonAsset = 'assets/images/map_button.png';
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _userLat;
  double? _userLng;
  String _userLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay(
      hour: (TimeOfDay.now().hour + 1) % 24,
      minute: 0,
    );
    _pickupController.addListener(_onPickupChanged);
    _dropoffController.addListener(_onDropoffChanged);
    _pickupFocus.addListener(_onFocusChanged);
    _dropoffFocus.addListener(_onFocusChanged);
    _initUserContext();
  }

  Future<void> _initUserContext() async {
    try {
      final lang = Platform.localeName.split('_').firstOrNull ?? 'en';
      if (mounted) setState(() => _userLanguage = lang);

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (mounted && pos != null) {
        final p = pos;
        setState(() {
          _userLat = p.latitude;
          _userLng = p.longitude;
        });
      }
    } catch (_) {}
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
      });
      return;
    }
    _debounce = Timer(_debounceDuration, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    _searchSequence++;
    final int seq = _searchSequence;
    setState(() => _isSearching = true);
    addDebugMessage('[SCHEDULE SEARCH] Query="$query" Sequence=$seq');
    try {
      final language = _searchLanguage(query);
      addDebugMessage('[SCHEDULE SEARCH] Language=$language UserLanguage=$_userLanguage');
      final results = await PlaceSearchService.search(
        query.trim(),
        lat: _userLat,
        lng: _userLng,
        language: language,
      );
      if (mounted && seq == _searchSequence) {
        final currentText = _activeControllerText;
        if (query.trim() != currentText.trim()) return;
        addDebugMessage('[SCHEDULE SEARCH] Received ${results.length} results');
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _searchedOnce = true;
        });
      }
    } catch (e) {
      addDebugMessage('[SCHEDULE SEARCH] Exception: $e');
      if (mounted && seq == _searchSequence) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchedOnce = true;
        });
      }
    }
  }

  Future<void> _onSelectResult(PlaceSearchResult result) async {
    final field = _activeField;
    final expectedDescription = result.description;

    PlaceDetails? details;
    try {
      details = await PlaceSearchService.getPlaceDetails(result.placeId, language: _userLanguage);
    } catch (_) {
      details = null;
    }

    if (!mounted) return;

    if (_activeField != field) {
      return;
    }

    final lat = details?.lat;
    final lng = details?.lng;

    _isProgrammaticChange = true;
    try {
      if (field == _FieldType.pickup) {
        _pickupController.text = expectedDescription;
        _pickupPlaceId = result.placeId;
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupFocus.unfocus();
      } else if (field == _FieldType.dropoff) {
        _dropoffController.text = expectedDescription;
        _dropoffPlaceId = result.placeId;
        _dropoffLat = lat;
        _dropoffLng = lng;
        _dropoffFocus.unfocus();
      }
    } finally {
      _isProgrammaticChange = false;
    }
    setState(() => _searchResults = []);
  }

  void _onReverse() {
    _isProgrammaticChange = true;
    try {
      final tempText = _pickupController.text;
      final tempPlaceId = _pickupPlaceId;
      final tempLat = _pickupLat;
      final tempLng = _pickupLng;

      _pickupController.text = _dropoffController.text;
      _dropoffController.text = tempText;

      setState(() {
        _pickupPlaceId = _dropoffPlaceId;
        _pickupLat = _dropoffLat;
        _pickupLng = _dropoffLng;
        _dropoffPlaceId = tempPlaceId;
        _dropoffLat = tempLat;
        _dropoffLng = tempLng;
      });
    } finally {
      _isProgrammaticChange = false;
    }
  }

  Future<void> _onMapButton(_FieldType field) async {
    final initialLat = field == _FieldType.pickup ? _pickupLat : _dropoffLat;
    final initialLng = field == _FieldType.pickup ? _pickupLng : _dropoffLng;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialLat: initialLat, initialLng: initialLng),
      ),
    );

    if (result != null && mounted) {
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      final address = result['address'] as String? ?? 'Selected Location';

      _isProgrammaticChange = true;
      try {
        if (field == _FieldType.pickup) {
          _pickupController.text = address;
        } else {
          _dropoffController.text = address;
        }
      } finally {
        _isProgrammaticChange = false;
      }

      setState(() {
        if (field == _FieldType.pickup) {
          _pickupLat = lat;
          _pickupLng = lng;
          _pickupPlaceId = null;
        } else {
          _dropoffLat = lat;
          _dropoffLng = lng;
          _dropoffPlaceId = null;
        }
      });
    }
  }

  Future<void> _onSchedule() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) return;

    final scheduledDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (!scheduledDateTime.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future date and time')),
        );
      }
      return;
    }

    setState(() => _isScheduling = true);
    try {
      final token = StorageService.getToken();
      if (token == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final result = await ScheduledRideService.create(
        pickupLat: _pickupLat ?? 0.0,
        pickupLng: _pickupLng ?? 0.0,
        pickupAddress: _pickupController.text,
        dropoffLat: _dropoffLat ?? 0.0,
        dropoffLng: _dropoffLng ?? 0.0,
        dropoffAddress: _dropoffController.text,
        scheduledAt: scheduledDateTime,
        token: token,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(result != null);
        messenger.showSnackBar(
          SnackBar(
            content: Text(result != null ? 'Ride scheduled successfully!' : 'Failed to schedule ride'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

bool get _canSchedule =>
    _pickupController.text.isNotEmpty &&
    _dropoffController.text.isNotEmpty &&
    _pickupLat != null && _pickupLng != null &&
    _dropoffLat != null && _dropoffLng != null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildPickupField(),
            const SizedBox(height: 8),
            _buildDropoffField(),
            const SizedBox(height: 12),
            _buildSearchResults(),
            const SizedBox(height: 8),
            _buildTimePicker(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSchedule && !_isScheduling ? _onSchedule : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isScheduling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : Text(
                          'Schedule Ride — ${_formatDate(widget.selectedDate)} at ${_selectedTime.format(context)}',
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48),
        const Text(
          'Schedule your later ride',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  IconData _searchIcon(bool isFocused) {
    return isFocused ? Icons.search_rounded : Icons.circle_outlined;
  }

  String _searchLanguage(String query) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(query) ? 'ar' : _userLanguage;
  }

  String get _activeControllerText {
    if (_activeField == _FieldType.pickup) return _pickupController.text;
    if (_activeField == _FieldType.dropoff) return _dropoffController.text;
    return '';
  }

  Widget _buildPickupField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _pickupController,
                focusNode: _pickupFocus,
                decoration: InputDecoration(
                  hintText: 'Pickup location',
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
                            _pickupPlaceId = null;
                            _pickupLat = null;
                            _pickupLng = null;
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
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _onMapButton(_FieldType.pickup),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _dropoffController,
                focusNode: _dropoffFocus,
                decoration: InputDecoration(
                  hintText: 'Dropoff location',
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
                            _dropoffPlaceId = null;
                            _dropoffLat = null;
                            _dropoffLng = null;
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
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _onMapButton(_FieldType.dropoff),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
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
          GestureDetector(
            onTap: _onReverse,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.keyboard_arrow_up, size: 16, color: AppColors.textSecondary),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              );
            },
          );
          if (picked != null && mounted) {
            setState(() => _selectedTime = picked);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isSearching) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Center(
          child: Text(
            _searchedOnce
                ? 'No locations found'
                : (_activeField != null
                    ? 'Start typing to search locations'
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
