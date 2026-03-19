import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../models/models.dart';

class MapsService {
  MapsService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? DefaultFirebaseOptions.currentPlatform.apiKey;

  final http.Client _client;
  final String _apiKey;

  static const _placesSearchUrl =
      'https://places.googleapis.com/v1/places:searchText';
  static const _routesUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  Future<Position> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const MapsServiceException('location_services_disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const MapsServiceException('location_permission_denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const MapsServiceException('location_permission_denied_forever');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }

  Future<List<MedicalPlace>> searchNearbyPlaces({
    required String query,
    required LatLng origin,
    required String languageCode,
    int maxResults = 12,
    double radiusMeters = 6000,
  }) async {
    final response = await _client.post(
      Uri.parse(_placesSearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.currentOpeningHours.openNow,places.internationalPhoneNumber,places.websiteUri,places.types,places.businessStatus,places.photos.name,places.photos.authorAttributions',
      },
      body: jsonEncode({
        'textQuery': query,
        'languageCode': languageCode,
        'maxResultCount': maxResults,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
            'radius': radiusMeters,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapsServiceException('places_search_failed', response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (decoded['places'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) {
          final place = MedicalPlace.fromPlacesApi(
            Map<String, dynamic>.from(raw),
            distanceMeters: _computeDistanceFromOrigin(
              origin,
              Map<String, dynamic>.from(raw),
            ),
          );
          if ((place.photoName ?? '').isEmpty) {
            return place;
          }
          return place.copyWith(
            photoUrl: buildPhotoUrl(place.photoName!),
          );
        })
        .where((place) => place.name.isNotEmpty)
        .toList()
      ..sort((a, b) => (a.distanceMeters ?? double.infinity)
          .compareTo(b.distanceMeters ?? double.infinity));

    return places;
  }

  List<MedicalPlace> buildPreviewPlaces({
    required String query,
    required LatLng origin,
    required MedicalPlaceCategory category,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final categoryMatches = _previewPlaces
        .where(
          (place) => category == MedicalPlaceCategory.unknown
              ? true
              : place.category == category,
        )
        .map(
          (place) => place.copyWith(
            distanceMeters: Geolocator.distanceBetween(
              origin.latitude,
              origin.longitude,
              place.location.latitude,
              place.location.longitude,
            ),
          ),
        )
        .toList()
      ..sort(
        (a, b) => (a.distanceMeters ?? double.infinity)
            .compareTo(b.distanceMeters ?? double.infinity),
      );

    if (normalizedQuery.isEmpty) return categoryMatches;

    final tokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().length > 2)
        .toList();

    final filtered = categoryMatches.where((place) {
      final haystack =
          '${place.name} ${place.address} ${place.types.join(' ')} ${place.category.name}'
              .toLowerCase();
      return haystack.contains(normalizedQuery) ||
          tokens.any((token) => haystack.contains(token));
    }).toList();

    return filtered.isNotEmpty ? filtered : categoryMatches;
  }

  Future<PlaceRouteInfo?> computeRoute({
    required LatLng origin,
    required LatLng destination,
    required MapTransportMode mode,
    required String languageCode,
  }) async {
    try {
      return await _requestRoute(
        origin: origin,
        destination: destination,
        mode: mode,
        languageCode: languageCode,
      );
    } on MapsServiceException {
      if (mode == MapTransportMode.scooter) {
        final fallback = await _requestRoute(
          origin: origin,
          destination: destination,
          mode: MapTransportMode.driving,
          languageCode: languageCode,
        );
        return PlaceRouteInfo(
          mode: MapTransportMode.scooter,
          distanceMeters: fallback.distanceMeters,
          duration: fallback.duration,
          polylinePoints: fallback.polylinePoints,
          warning:
              'Scooter routing is unavailable in this region. Showing driving route as fallback.',
          isFallback: true,
        );
      }
      return null;
    }
  }

  PlaceRouteInfo buildPreviewRoute({
    required LatLng origin,
    required LatLng destination,
    required MapTransportMode mode,
  }) {
    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    ).round();

    final metersPerSecond = switch (mode) {
      MapTransportMode.driving => 11.5,
      MapTransportMode.walking => 1.45,
      MapTransportMode.transit => 7.0,
      MapTransportMode.scooter => 8.5,
    };

    final durationMinutes = (distanceMeters / (metersPerSecond * 60)).round();
    final curveOffset = switch (mode) {
      MapTransportMode.driving => 0.0024,
      MapTransportMode.walking => 0.0014,
      MapTransportMode.transit => 0.0018,
      MapTransportMode.scooter => 0.0021,
    };

    return PlaceRouteInfo(
      mode: mode,
      distanceMeters: distanceMeters,
      duration: Duration(minutes: durationMinutes < 1 ? 1 : durationMinutes),
      polylinePoints: [
        origin,
        LatLng(
          (origin.latitude + destination.latitude) / 2 + curveOffset,
          (origin.longitude + destination.longitude) / 2 - curveOffset,
        ),
        destination,
      ],
      warning: switch (mode) {
        MapTransportMode.transit =>
          'Preview route uses local sample timing for public transport.',
        MapTransportMode.scooter =>
          'Preview route is estimated from local sample data.',
        _ => 'Preview route uses local sample data.',
      },
      isFallback: true,
    );
  }

  Uri buildExternalDirectionsUri({
    required LatLng origin,
    required LatLng destination,
    required MapTransportMode mode,
  }) {
    final travelMode = switch (mode) {
      MapTransportMode.walking => 'walking',
      MapTransportMode.transit => 'transit',
      MapTransportMode.driving => 'driving',
      MapTransportMode.scooter => 'driving',
    };

    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=$travelMode',
    );
  }

  String buildPhotoUrl(String photoName, {int maxWidthPx = 900}) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?maxWidthPx=$maxWidthPx&key=$_apiKey';
  }

  Future<PlaceRouteInfo> _requestRoute({
    required LatLng origin,
    required LatLng destination,
    required MapTransportMode mode,
    required String languageCode,
  }) async {
    final response = await _client.post(
      Uri.parse(_routesUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.warnings',
      },
      body: jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'travelMode': _routeTravelMode(mode),
        'languageCode': languageCode,
        'units': 'METRIC',
        'computeAlternativeRoutes': false,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MapsServiceException('route_failed', response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'] as List? ?? const [];
    if (routes.isEmpty) {
      throw const MapsServiceException('route_not_found');
    }

    final firstRoute = Map<String, dynamic>.from(routes.first as Map);
    final polyline = (firstRoute['polyline'] as Map<String, dynamic>? ??
            const <String, dynamic>{})['encodedPolyline'] as String? ??
        '';

    return PlaceRouteInfo(
      mode: mode,
      distanceMeters: (firstRoute['distanceMeters'] as num?)?.toInt() ?? 0,
      duration: _parseDuration(firstRoute['duration'] as String? ?? '0s'),
      polylinePoints: _decodePolyline(polyline),
      warning: _routeWarning(mode),
      isFallback: false,
    );
  }

  double _computeDistanceFromOrigin(LatLng origin, Map<String, dynamic> raw) {
    final location = raw['location'] as Map<String, dynamic>? ?? const {};
    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      latitude,
      longitude,
    );
  }

  static const List<MedicalPlace> _previewPlaces = [
    MedicalPlace(
      id: 'preview_hospital_1',
      name: 'Central City Hospital',
      address: 'Dostyk Ave 210, Almaty',
      location: LatLng(43.2384, 76.9458),
      category: MedicalPlaceCategory.hospital,
      types: ['hospital', 'health'],
      rating: 4.8,
      userRatingCount: 420,
      openNow: true,
      phoneNumber: '+7 727 000 0001',
      websiteUri: 'https://mediguide.app/preview-hospital',
      businessStatus: 'OPERATIONAL',
    ),
    MedicalPlace(
      id: 'preview_clinic_1',
      name: 'Sunrise Family Clinic',
      address: 'Satpayev St 54, Almaty',
      location: LatLng(43.2407, 76.9092),
      category: MedicalPlaceCategory.clinic,
      types: ['clinic', 'doctor'],
      rating: 4.6,
      userRatingCount: 184,
      openNow: true,
      phoneNumber: '+7 727 000 0002',
      websiteUri: 'https://mediguide.app/preview-clinic',
      businessStatus: 'OPERATIONAL',
    ),
    MedicalPlace(
      id: 'preview_pharmacy_1',
      name: 'Green Cross Pharmacy',
      address: 'Abylai Khan Ave 96, Almaty',
      location: LatLng(43.2553, 76.9283),
      category: MedicalPlaceCategory.pharmacy,
      types: ['pharmacy', 'store'],
      rating: 4.7,
      userRatingCount: 136,
      openNow: true,
      phoneNumber: '+7 727 000 0003',
      websiteUri: 'https://mediguide.app/preview-pharmacy',
      businessStatus: 'OPERATIONAL',
    ),
    MedicalPlace(
      id: 'preview_emergency_1',
      name: 'Rapid Response ER',
      address: 'Tole Bi St 142, Almaty',
      location: LatLng(43.2515, 76.9064),
      category: MedicalPlaceCategory.emergency,
      types: ['hospital', 'emergency'],
      rating: 4.9,
      userRatingCount: 260,
      openNow: true,
      phoneNumber: '+7 727 000 0004',
      websiteUri: 'https://mediguide.app/preview-er',
      businessStatus: 'OPERATIONAL',
    ),
    MedicalPlace(
      id: 'preview_hospital_2',
      name: 'North Hills Medical Center',
      address: 'Al-Farabi Ave 71, Almaty',
      location: LatLng(43.2221, 76.9137),
      category: MedicalPlaceCategory.hospital,
      types: ['hospital', 'medical'],
      rating: 4.5,
      userRatingCount: 211,
      openNow: false,
      phoneNumber: '+7 727 000 0005',
      websiteUri: 'https://mediguide.app/preview-medical-center',
      businessStatus: 'OPERATIONAL',
    ),
  ];

  String _routeTravelMode(MapTransportMode mode) {
    switch (mode) {
      case MapTransportMode.driving:
        return 'DRIVE';
      case MapTransportMode.walking:
        return 'WALK';
      case MapTransportMode.transit:
        return 'TRANSIT';
      case MapTransportMode.scooter:
        return 'TWO_WHEELER';
    }
  }

  String? _routeWarning(MapTransportMode mode) {
    switch (mode) {
      case MapTransportMode.walking:
        return 'Walking directions may include paths with limited accessibility.';
      case MapTransportMode.scooter:
        return 'Scooter routing availability depends on region and may follow two-wheeler roads.';
      case MapTransportMode.transit:
      case MapTransportMode.driving:
        return null;
    }
  }

  Duration _parseDuration(String value) {
    final cleaned = value.replaceAll('s', '');
    final seconds = double.tryParse(cleaned)?.round() ?? 0;
    return Duration(seconds: seconds);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final latitudeChange = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      latitude += latitudeChange;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final longitudeChange =
          (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      longitude += longitudeChange;

      points.add(
        LatLng(latitude / 1e5, longitude / 1e5),
      );
    }

    return points;
  }
}

class MapsServiceException implements Exception {
  const MapsServiceException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'MapsServiceException(code: $code, message: $message)';
}
