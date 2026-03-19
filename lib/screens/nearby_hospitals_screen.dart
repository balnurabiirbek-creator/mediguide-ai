import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hospital_model.dart';
import '../models/route_info_model.dart';
import '../services/app_localizations.dart';
import '../services/directions_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/hospital_info_card.dart';
import '../widgets/hospital_search_bar.dart';
import '../widgets/transport_mode_selector.dart';

enum _NearbyViewMode {
  map,
  list,
}

enum _NearbySortOption {
  nearest,
  topRated,
  openNow,
}

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  static const LatLng _fallbackCenter = LatLng(43.238949, 76.889709);

  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;
  StreamSubscription<LatLng>? _locationSubscription;
  Timer? _searchDebounce;

  LatLng? _currentLocation;
  List<HospitalModel> _nearbyPlaces = const [];
  List<HospitalModel> _searchResults = const [];
  HospitalModel? _selectedHospital;
  RouteInfoModel? _activeRoute;
  Map<TransportMode, RouteInfoModel> _routeOptions = const {};

  HospitalCategory _selectedCategory = HospitalCategory.all;
  TransportMode _selectedTransportMode = TransportMode.driving;
  _NearbyViewMode _viewMode = _NearbyViewMode.list;
  _NearbySortOption _selectedSortOption = _NearbySortOption.nearest;

  bool _isLoadingLocation = true;
  bool _isLoadingPlaces = false;
  bool _isSearching = false;
  bool _isLoadingRoute = false;
  String? _locationError;
  String? _placesError;
  String? _routeError;

  List<HospitalModel> get _displayedHospitals {
    final source = _searchController.text.trim().isNotEmpty
        ? _searchResults
        : _nearbyPlaces;
    return _sortHospitals(source);
  }

  @override
  void initState() {
    super.initState();
    _initializeNearbyExperience();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSubscription?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeNearbyExperience() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final currentLocation = await _locationService.determineCurrentLocation();
      if (!mounted) return;

      setState(() {
        _currentLocation = currentLocation;
        _isLoadingLocation = false;
      });

      _bindLocationUpdates();
      await _loadNearbyHospitals();
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = error.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'location_permission_denied';
      });
    }
  }

  void _bindLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription =
        _locationService.locationStream().listen((location) {
      if (!mounted) return;
      setState(() => _currentLocation = location);
    });
  }

  Future<void> _loadNearbyHospitals() async {
    final origin = _currentLocation;
    if (origin == null) return;

    final localeCode = context.read<AppPreferencesProvider>().localeCode;
    final userProvider = context.read<UserProvider>();

    setState(() {
      _isLoadingPlaces = true;
      _placesError = null;
    });

    try {
      final hospitals = await _placesService.fetchNearbyMedicalPlaces(
        origin: origin,
        category: _selectedCategory,
        languageCode: localeCode,
      );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = hospitals;
        _isLoadingPlaces = false;
      });

      if (hospitals.isNotEmpty) {
        await _fitCameraToPlaces(hospitals.take(5).toList(), includeUser: true);
      } else {
        final fallback = _buildOfflineFallback(userProvider);
        if (!mounted) return;
        setState(() {
          _nearbyPlaces = fallback;
          _placesError = fallback.isEmpty ? 'no_places_found' : null;
        });
        if (fallback.isNotEmpty) {
          await _fitCameraToPlaces(fallback.take(5).toList(),
              includeUser: true);
        }
      }
    } on PlacesServiceException {
      final fallback = _buildOfflineFallback(userProvider);
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = fallback;
        _isLoadingPlaces = false;
        _placesError = fallback.isEmpty
            ? 'api_failure'
            : 'live_data_unavailable_saved_places_shown';
      });
      if (fallback.isNotEmpty) {
        await _fitCameraToPlaces(fallback.take(5).toList(), includeUser: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = const [];
        _isLoadingPlaces = false;
        _placesError = 'api_failure';
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    final origin = _currentLocation;
    if (origin == null) return;

    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      setState(() {
        _searchResults = const [];
        _placesError = null;
      });
      return;
    }

    final localeCode = context.read<AppPreferencesProvider>().localeCode;

    setState(() {
      _isSearching = true;
      _placesError = null;
    });

    try {
      final results = await _placesService.searchMedicalPlaces(
        query: normalizedQuery,
        origin: origin,
        category: _selectedCategory,
        languageCode: localeCode,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results.isNotEmpty
            ? results
            : _buildOfflineFallback(context.read<UserProvider>())
                .where(
                  (place) =>
                      place.name.toLowerCase().contains(
                            normalizedQuery.toLowerCase(),
                          ) ||
                      place.address.toLowerCase().contains(
                            normalizedQuery.toLowerCase(),
                          ),
                )
                .toList();
        _isSearching = false;
        if (_searchResults.isEmpty) {
          _placesError = 'search_empty';
        }
      });
    } on PlacesServiceException {
      final fallback = _buildOfflineFallback(context.read<UserProvider>())
          .where(
            (place) =>
                place.name.toLowerCase().contains(
                      normalizedQuery.toLowerCase(),
                    ) ||
                place.address.toLowerCase().contains(
                      normalizedQuery.toLowerCase(),
                    ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _searchResults = fallback;
        _isSearching = false;
        _placesError = fallback.isEmpty ? 'search_failed' : null;
      });
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      if (value.trim().isEmpty) {
        setState(() {
          _searchResults = const [];
          _placesError = null;
        });
        return;
      }
      await _searchPlaces(value);
    });
  }

  Future<void> _handleSearchSubmitted(String value) async {
    await _searchPlaces(value);
    if (!mounted) return;
    if (_searchResults.isNotEmpty) {
      await _selectHospital(_searchResults.first, openDetails: true);
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchResults = const [];
      _placesError = null;
    });
  }

  List<HospitalModel> _sortHospitals(List<HospitalModel> hospitals) {
    final sorted = List<HospitalModel>.from(hospitals);

    switch (_selectedSortOption) {
      case _NearbySortOption.nearest:
        sorted.sort(
          (a, b) => (a.distanceMeters ?? double.infinity)
              .compareTo(b.distanceMeters ?? double.infinity),
        );
        break;
      case _NearbySortOption.topRated:
        sorted.sort((a, b) {
          final ratingCompare = (b.rating ?? -1).compareTo(a.rating ?? -1);
          if (ratingCompare != 0) return ratingCompare;
          return (a.distanceMeters ?? double.infinity)
              .compareTo(b.distanceMeters ?? double.infinity);
        });
        break;
      case _NearbySortOption.openNow:
        sorted.sort((a, b) {
          final openCompare =
              (b.openNow == true ? 1 : 0).compareTo(a.openNow == true ? 1 : 0);
          if (openCompare != 0) return openCompare;
          return (a.distanceMeters ?? double.infinity)
              .compareTo(b.distanceMeters ?? double.infinity);
        });
        break;
    }

    return sorted;
  }

  Future<void> _switchViewMode(_NearbyViewMode nextMode) async {
    if (_viewMode == nextMode) return;

    setState(() => _viewMode = nextMode);

    if (nextMode != _NearbyViewMode.map) return;

    if (_activeRoute != null && _selectedHospital != null) {
      await _fitCameraToRoute(_activeRoute!, _selectedHospital!);
      return;
    }

    if (_selectedHospital != null) {
      await _animateToHospital(_selectedHospital!);
      return;
    }

    if (_displayedHospitals.isNotEmpty) {
      await _fitCameraToPlaces(
        _displayedHospitals.take(6).toList(),
        includeUser: true,
      );
    }
  }

  Future<void> _selectHospital(
    HospitalModel hospital, {
    bool openDetails = false,
  }) async {
    final selectedAnotherHospital = _selectedHospital?.id != hospital.id;

    setState(() {
      _selectedHospital = hospital;
      _routeError = null;
      if (selectedAnotherHospital) {
        _activeRoute = null;
        _routeOptions = const {};
      }
    });

    await _animateToHospital(hospital);

    if (openDetails && mounted) {
      await _openHospitalDetails(hospital);
    }
  }

  Future<void> _animateToHospital(HospitalModel hospital) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(hospital.location, 15.2),
    );
  }

  Future<Map<TransportMode, RouteInfoModel>> _loadRouteOptions(
    HospitalModel hospital,
  ) async {
    final origin = _currentLocation;
    if (origin == null) return const {};

    if (_selectedHospital?.id == hospital.id && _routeOptions.isNotEmpty) {
      return _routeOptions;
    }

    final localeCode = context.read<AppPreferencesProvider>().localeCode;
    final options = await _directionsService.fetchRouteOptions(
      origin: origin,
      destination: hospital.location,
      languageCode: localeCode,
    );

    if (!mounted || _selectedHospital?.id != hospital.id) {
      return options;
    }

    setState(() => _routeOptions = options);
    return options;
  }

  Future<void> _activateRoute(
    HospitalModel hospital,
    TransportMode mode,
  ) async {
    final origin = _currentLocation;
    if (origin == null) return;
    final userProvider = context.read<UserProvider>();

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
      _selectedTransportMode = mode;
      _selectedHospital = hospital;
    });

    final options = await _loadRouteOptions(hospital);
    final selectedRoute = options[mode];

    if (!mounted) return;

    if (selectedRoute == null || !selectedRoute.isAvailable) {
      setState(() {
        _isLoadingRoute = false;
        _activeRoute = null;
        _routeError = selectedRoute?.errorMessage ??
            context.tr('routeDirectionsUnavailable');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.dynamicText(_routeError!)),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = false;
      _activeRoute = selectedRoute;
      _viewMode = _NearbyViewMode.map;
    });

    final routeStartedTitle = context.tr('hospitalRouteStarted');
    await _fitCameraToRoute(selectedRoute, hospital);
    if (!mounted) return;

    userProvider.addRecentActivity({
      'icon': '🗺️',
      'title': routeStartedTitle,
      'subtitle': '${hospital.name} • ${selectedRoute.formattedDuration}',
    });
  }

  Future<void> _fitCameraToRoute(
    RouteInfoModel route,
    HospitalModel hospital,
  ) async {
    final controller = _mapController;
    final origin = _currentLocation;
    if (controller == null || origin == null) return;

    final points = [
      origin,
      ...route.polylinePoints,
      hospital.location,
    ];

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        88,
      ),
    );
  }

  Future<void> _fitCameraToPlaces(
    List<HospitalModel> hospitals, {
    required bool includeUser,
  }) async {
    final controller = _mapController;
    if (controller == null || hospitals.isEmpty) return;

    final points = <LatLng>[
      if (includeUser && _currentLocation != null) _currentLocation!,
      ...hospitals.map((place) => place.location),
    ];

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14.2),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  Future<void> _recenterToCurrentLocation() async {
    final controller = _mapController;
    final currentLocation = _currentLocation;
    if (controller == null || currentLocation == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation, 14.8),
    );
  }

  Future<void> _openHospitalDetails(HospitalModel hospital) async {
    final userProvider = context.read<UserProvider>();
    final isSaved = userProvider.isPlaceSaved(hospital.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _HospitalDetailsSheet(
          hospital: hospital,
          currentLocation: _currentLocation,
          initialMode: _selectedTransportMode,
          initialRouteOptions:
              _selectedHospital?.id == hospital.id ? _routeOptions : const {},
          initialSavedState: isSaved,
          routeOptionsLoader: () => _loadRouteOptions(hospital),
          onDirections: (mode) => _activateRoute(hospital, mode),
          onCall: hospital.phoneNumber == null
              ? null
              : () => _launchUri(
                    Uri(
                      scheme: 'tel',
                      path: hospital.phoneNumber!
                          .replaceAll(RegExp(r'[^0-9+]'), ''),
                    ),
                  ),
          onOpenExternalMaps: () async {
            final origin = _currentLocation ?? _fallbackCenter;
            final uri = _directionsService.buildExternalDirectionsUri(
              origin: origin,
              destination: hospital.location,
              mode: _selectedTransportMode,
            );
            await _launchUri(uri);
          },
          onToggleSaved: () async {
            if (userProvider.isPlaceSaved(hospital.id)) {
              await userProvider.removeSavedPlace(hospital.id);
            } else {
              await userProvider.upsertSavedPlace(hospital.toMedicalPlace());
            }
          },
        );
      },
    );
  }

  Future<void> _launchUri(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('unableToOpenLink')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  List<HospitalModel> _buildOfflineFallback(UserProvider userProvider) {
    final savedPlaces = userProvider.savedPlaces
        .map(HospitalModel.fromMedicalPlace)
        .where((place) {
      if (_selectedCategory == HospitalCategory.all) return true;
      return place.category == _selectedCategory;
    }).toList();

    final demoPlaces = _currentLocation == null
        ? const <HospitalModel>[]
        : _placesService.demoMedicalPlaces(
            origin: _currentLocation!,
            category: _selectedCategory,
          );

    final merged = <String, HospitalModel>{
      for (final place in demoPlaces) place.id: place,
      for (final place in savedPlaces) place.id: place,
    }.values.toList()
      ..sort(
        (a, b) => (a.distanceMeters ?? double.infinity)
            .compareTo(b.distanceMeters ?? double.infinity),
      );

    return merged;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: context.tr('currentLocation')),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          zIndexInt: 2,
        ),
      );
    }

    for (final hospital in _displayedHospitals) {
      final isSelected = hospital.id == _selectedHospital?.id;
      markers.add(
        Marker(
          markerId: MarkerId(hospital.id),
          position: hospital.location,
          infoWindow: InfoWindow(
            title: context.dynamicText(hospital.name),
            snippet: context.dynamicText(hospital.address),
          ),
          zIndexInt: isSelected ? 3 : 1,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueBlue
                : _markerHue(hospital.category),
          ),
          onTap: () => _selectHospital(hospital, openDetails: true),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final route = _activeRoute;
    if (route == null || !route.isAvailable || route.polylinePoints.isEmpty) {
      return const <Polyline>{};
    }

    return {
      Polyline(
        polylineId: const PolylineId('hospital_route'),
        points: route.polylinePoints,
        width: 6,
        color: AppTheme.brandBlue,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  double _markerHue(HospitalCategory category) {
    switch (category) {
      case HospitalCategory.hospital:
        return BitmapDescriptor.hueRed;
      case HospitalCategory.clinic:
        return BitmapDescriptor.hueViolet;
      case HospitalCategory.pharmacy:
        return BitmapDescriptor.hueGreen;
      case HospitalCategory.emergency:
        return BitmapDescriptor.hueOrange;
      case HospitalCategory.all:
        return BitmapDescriptor.hueRose;
    }
  }

  String _placesMessage() {
    switch (_placesError) {
      case 'no_places_found':
        return context.tr('nearbyNoPlacesAround');
      case 'search_empty':
        return context.tr('nearbySearchEmpty');
      case 'search_failed':
        return context.tr('nearbySearchFailed');
      case 'api_failure':
        return context.tr('nearbyApiFailure');
      case 'live_data_unavailable_saved_places_shown':
        return context.tr('nearbyFallbackShown');
      default:
        return context.tr('noPlacesFoundSubtitle');
    }
  }

  Widget _buildTopOverlay() {
    final isMapView = _viewMode == _NearbyViewMode.map;
    final placeCount = _displayedHospitals.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brandBlue.withValues(alpha: 0.92),
                      const Color(0xFF8E7AE6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMapView
                                    ? context.tr('medicalMapTitle')
                                    : context.tr('medicalPlacesNearYou'),
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLoadingPlaces && placeCount == 0
                                    ? context.tr('loadingNearbyPlacesSubtitle')
                                    : context.tr(
                                        'nearbyPlacesReady',
                                        params: {'count': '$placeCount'},
                                      ),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.brandBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _switchViewMode(
                            isMapView
                                ? _NearbyViewMode.list
                                : _NearbyViewMode.map,
                          ),
                          icon: Icon(
                            isMapView
                                ? Icons.view_list_rounded
                                : Icons.map_rounded,
                          ),
                          label: Text(
                            isMapView
                                ? context.tr('listView')
                                : context.tr('mapView'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickStatPill(
                          icon: Icons.place_rounded,
                          label: context.tr(
                            'resultsCount',
                            params: {'count': '$placeCount'},
                          ),
                        ),
                        _QuickStatPill(
                          icon: Icons.tune_rounded,
                          label: _categoryLabel(_selectedCategory),
                        ),
                        _QuickStatPill(
                          icon: Icons.sort_rounded,
                          label: _sortLabel(_selectedSortOption),
                        ),
                        _QuickStatPill(
                          icon: Icons.route_rounded,
                          label: _activeRoute == null
                              ? context.tr('routeOff')
                              : context.tr('routeActive'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HospitalSearchBar(
                controller: _searchController,
                isLoading: _isSearching,
                suggestions: _searchResults.take(5).toList(),
                onChanged: _handleSearchChanged,
                onSubmitted: _handleSearchSubmitted,
                onSuggestionTap: (hospital) async {
                  _searchController.text = hospital.name;
                  _searchController.selection = TextSelection.collapsed(
                    offset: _searchController.text.length,
                  );
                  await _selectHospital(hospital, openDetails: true);
                },
                onClear: _clearSearch,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: HospitalCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_categoryLabel(category)),
                              selected: isSelected,
                              onSelected: (_) async {
                                if (_selectedCategory == category) return;
                                setState(() {
                                  _selectedCategory = category;
                                  _selectedHospital = null;
                                  _activeRoute = null;
                                  _routeOptions = const {};
                                });
                                if (_searchController.text.trim().isEmpty) {
                                  await _loadNearbyHospitals();
                                } else {
                                  await _searchPlaces(_searchController.text);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _displayedHospitals.isEmpty
                        ? null
                        : () => _selectHospital(
                              _displayedHospitals.first,
                              openDetails: true,
                            ),
                    icon: const Icon(Icons.local_hospital_rounded),
                    label: Text(context.tr('nearest')),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<_NearbySortOption>(
                    tooltip: context.tr('sortPlaces'),
                    onSelected: (value) {
                      setState(() => _selectedSortOption = value);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _NearbySortOption.nearest,
                        child: Text(context.tr('sortByNearest')),
                      ),
                      PopupMenuItem(
                        value: _NearbySortOption.topRated,
                        child: Text(context.tr('sortByRating')),
                      ),
                      PopupMenuItem(
                        value: _NearbySortOption.openNow,
                        child: Text(context.tr('sortByOpenNow')),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _sortShortLabel(_selectedSortOption),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? _fallbackCenter,
            zoom: 13.5,
          ),
          myLocationEnabled: _currentLocation != null,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          onTap: (_) => setState(() => _searchResults = const []),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_currentLocation != null) {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(_currentLocation!, 13.8),
              );
            }
          },
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _buildTopOverlay(),
        ),
        if (_selectedHospital != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _activeRoute != null
                ? _RouteSummaryCard(
                    hospital: _selectedHospital!,
                    route: _activeRoute!,
                    isLoading: _isLoadingRoute,
                    onClear: () => setState(() {
                      _activeRoute = null;
                      _routeError = null;
                    }),
                    onTap: () => _openHospitalDetails(_selectedHospital!),
                  )
                : HospitalInfoCard(
                    hospital: _selectedHospital!,
                    isSelected: true,
                    compact: true,
                    onTap: () => _openHospitalDetails(_selectedHospital!),
                    onDirectionsTap: () =>
                        _openHospitalDetails(_selectedHospital!),
                    onCallTap: _selectedHospital!.phoneNumber == null
                        ? null
                        : () => _launchUri(
                              Uri(
                                scheme: 'tel',
                                path: _selectedHospital!.phoneNumber!
                                    .replaceAll(RegExp(r'[^0-9+]'), ''),
                              ),
                            ),
                  ),
          ),
        Positioned(
          right: 16,
          bottom: _selectedHospital != null ? 192 : 24,
          child: FloatingActionButton.small(
            heroTag: 'recenter_location',
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.brandBlue,
            onPressed: _recenterToCurrentLocation,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final hospitals = _displayedHospitals;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandBlue.withValues(alpha: 0.08),
            AppTheme.brandMint.withValues(alpha: 0.08),
            AppColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingL,
              12,
              AppDimensions.paddingL,
              12,
            ),
            child: _buildTopOverlay(),
          ),
          Expanded(
            child: hospitals.isEmpty && (_isLoadingPlaces || _isSearching)
                ? const Center(child: CircularProgressIndicator())
                : hospitals.isEmpty
                    ? EmptyState(
                        emoji: '🏥',
                        title: context.tr('noPlacesFound'),
                        subtitle: _placesMessage(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.paddingL,
                          0,
                          AppDimensions.paddingL,
                          AppDimensions.paddingL,
                        ),
                        itemCount: hospitals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final hospital = hospitals[index];
                          return HospitalInfoCard(
                            hospital: hospital,
                            isSelected: hospital.id == _selectedHospital?.id,
                            onTap: () => _selectHospital(
                              hospital,
                              openDetails: true,
                            ),
                            onDirectionsTap: () => _activateRoute(
                              hospital,
                              _selectedTransportMode,
                            ),
                            onCallTap: hospital.phoneNumber == null
                                ? null
                                : () => _launchUri(
                                      Uri(
                                        scheme: 'tel',
                                        path: hospital.phoneNumber!
                                            .replaceAll(RegExp(r'[^0-9+]'), ''),
                                      ),
                                    ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStateCard() {
    if (_isLoadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationError == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.danger,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  _locationMessage(_locationError!),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _locationService.openLocationSettings,
                      icon: const Icon(Icons.my_location_rounded),
                      label: Text(context.tr('enableLocation')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _locationService.openAppSettings,
                      icon: const Icon(Icons.settings_rounded),
                      label: Text(context.tr('openSettings')),
                    ),
                    FilledButton.icon(
                      onPressed: _initializeNearbyExperience,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('retry')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _locationMessage(String code) {
    switch (code) {
      case 'location_services_disabled':
        return context.tr('locationServicesDisabled');
      case 'location_permission_denied_forever':
        return context.tr('locationPermissionDeniedForever');
      default:
        return context.tr('locationPermissionDenied');
    }
  }

  String _categoryLabel(HospitalCategory category) {
    switch (category) {
      case HospitalCategory.all:
        return context.tr('all');
      case HospitalCategory.hospital:
        return context.tr('hospital');
      case HospitalCategory.clinic:
        return context.tr('clinic');
      case HospitalCategory.pharmacy:
        return context.tr('pharmacy');
      case HospitalCategory.emergency:
        return context.tr('emergency');
    }
  }

  String _sortLabel(_NearbySortOption option) {
    switch (option) {
      case _NearbySortOption.nearest:
        return context.tr('sortNearestLabel');
      case _NearbySortOption.topRated:
        return context.tr('topRated');
      case _NearbySortOption.openNow:
        return context.tr('openNow');
    }
  }

  String _sortShortLabel(_NearbySortOption option) {
    switch (option) {
      case _NearbySortOption.nearest:
        return context.tr('nearest');
      case _NearbySortOption.topRated:
        return context.tr('ratingLabel');
      case _NearbySortOption.openNow:
        return context.tr('openShort');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _currentLocation != null && _locationError == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: hasLocation
                  ? (_viewMode == _NearbyViewMode.map
                      ? _buildMapView()
                      : _buildListView())
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.authBackgroundGradient,
                      ),
                    ),
            ),
            if (!hasLocation) Positioned.fill(child: _buildLocationStateCard()),
            if (hasLocation &&
                _placesError != null &&
                _displayedHospitals.isEmpty &&
                !_isLoadingPlaces &&
                _viewMode == _NearbyViewMode.map)
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: AppCard(
                  child: Text(
                    _placesMessage(),
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (_routeError != null && hasLocation)
              Positioned(
                left: 24,
                right: 24,
                bottom: _selectedHospital != null ? 220 : 28,
                child: AppCard(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  child: Text(
                    context.dynamicText(_routeError!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatPill extends StatelessWidget {
  const _QuickStatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.hospital,
    required this.route,
    required this.isLoading,
    required this.onClear,
    required this.onTap,
  });

  final HospitalModel hospital;
  final RouteInfoModel route;
  final bool isLoading;
  final VoidCallback onClear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.dynamicText(hospital.name),
                      style: AppTextStyles.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.formattedDuration} • ${route.formattedDistance}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ] else if ((route.warning ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.dynamicText(route.warning!),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HospitalDetailsSheet extends StatefulWidget {
  const _HospitalDetailsSheet({
    required this.hospital,
    required this.currentLocation,
    required this.initialMode,
    required this.initialRouteOptions,
    required this.initialSavedState,
    required this.routeOptionsLoader,
    required this.onDirections,
    required this.onToggleSaved,
    required this.onOpenExternalMaps,
    this.onCall,
  });

  final HospitalModel hospital;
  final LatLng? currentLocation;
  final TransportMode initialMode;
  final Map<TransportMode, RouteInfoModel> initialRouteOptions;
  final bool initialSavedState;
  final Future<Map<TransportMode, RouteInfoModel>> Function()
      routeOptionsLoader;
  final Future<void> Function(TransportMode mode) onDirections;
  final Future<void> Function() onToggleSaved;
  final Future<void> Function() onOpenExternalMaps;
  final Future<void> Function()? onCall;

  @override
  State<_HospitalDetailsSheet> createState() => _HospitalDetailsSheetState();
}

class _HospitalDetailsSheetState extends State<_HospitalDetailsSheet> {
  late TransportMode _selectedMode;
  late bool _isSaved;
  late Future<Map<TransportMode, RouteInfoModel>> _routeOptionsFuture;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _isSaved = widget.initialSavedState;
    _routeOptionsFuture = widget.initialRouteOptions.isNotEmpty
        ? Future.value(widget.initialRouteOptions)
        : widget.routeOptionsLoader();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.56,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXXL),
            ),
          ),
          child: FutureBuilder<Map<TransportMode, RouteInfoModel>>(
            future: _routeOptionsFuture,
            builder: (context, snapshot) {
              final routeOptions = snapshot.data ?? widget.initialRouteOptions;
              final selectedRoute = routeOptions[_selectedMode];

              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXXL),
                      child: SizedBox(
                        height: 210,
                        width: double.infinity,
                        child: (widget.hospital.photoUrl ?? '').isNotEmpty
                            ? Image.network(
                                widget.hospital.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildBanner(),
                              )
                            : _buildBanner(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.dynamicText(widget.hospital.name),
                                style: AppTextStyles.displayMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.dynamicText(widget.hospital.address),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () async {
                            await widget.onToggleSaved();
                            if (!mounted) return;
                            setState(() => _isSaved = !_isSaved);
                          },
                          icon: Icon(
                            _isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color:
                                _isSaved ? AppColors.danger : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(
                          label: context.dynamicText(
                            widget.hospital.displayCategory,
                          ),
                          isSelected: true,
                        ),
                        if (widget.hospital.rating != null)
                          TagChip(
                            label:
                                '⭐ ${widget.hospital.rating!.toStringAsFixed(1)} (${widget.hospital.userRatingCount ?? 0})',
                          ),
                        if (widget.hospital.openNow != null)
                          TagChip(
                            label: widget.hospital.openNow!
                                ? context.tr('openNow')
                                : context.tr('closed'),
                          ),
                        if (widget.hospital.distanceMeters != null)
                          TagChip(
                            label:
                                '${context.tr('distance')}: ${_distanceLabel(widget.hospital.distanceMeters)}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('transportModes'),
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              routeOptions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            TransportModeSelector(
                              selectedMode: _selectedMode,
                              routeOptions: routeOptions,
                              onChanged: (mode) {
                                setState(() => _selectedMode = mode);
                              },
                            ),
                          const SizedBox(height: 14),
                          if (selectedRoute != null) ...[
                            Text(
                              selectedRoute.isAvailable
                                  ? '${selectedRoute.formattedDuration} • ${selectedRoute.formattedDistance}'
                                  : context.dynamicText(
                                      selectedRoute.errorMessage ??
                                          context.tr('routeUnavailableLabel'),
                                    ),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: selectedRoute.isAvailable
                                    ? AppColors.textPrimary
                                    : AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((selectedRoute.warning ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                context.dynamicText(selectedRoute.warning!),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('hospitalDetails'),
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.location_on_outlined,
                            label: context.tr('addressLabel'),
                            value: context.dynamicText(widget.hospital.address),
                          ),
                          InfoRow(
                            icon: Icons.place_outlined,
                            label: context.tr('coordinates'),
                            value:
                                '${widget.hospital.location.latitude.toStringAsFixed(5)}, ${widget.hospital.location.longitude.toStringAsFixed(5)}',
                          ),
                          if ((widget.hospital.phoneNumber ?? '').isNotEmpty)
                            InfoRow(
                              icon: Icons.phone_outlined,
                              label: context.tr('phoneLabel'),
                              value: widget.hospital.phoneNumber!,
                            ),
                          if ((widget.hospital.websiteUri ?? '').isNotEmpty)
                            InfoRow(
                              icon: Icons.language_rounded,
                              label: context.tr('websiteLabel'),
                              value: widget.hospital.websiteUri!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: context.tr('directions'),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await widget.onDirections(_selectedMode);
                        if (mounted) navigator.pop();
                      },
                      icon: Icons.route_rounded,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: widget.onCall,
                      icon: const Icon(Icons.call_rounded),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(context.tr('call')),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                            double.infinity, AppDimensions.buttonHeight),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: widget.onOpenExternalMaps,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(context.tr('openInMaps')),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                            double.infinity, AppDimensions.buttonHeight),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandBlue, AppTheme.brandMint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
