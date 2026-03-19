import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../models/hospital_model.dart';
import 'google_api_config.dart';

class PlacesService {
  PlacesService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ??
            GoogleApiConfig.resolveWebServiceApiKey(
              fallback: DefaultFirebaseOptions.currentPlatform.apiKey,
            );

  final http.Client _client;
  final String _apiKey;

  static const _searchNearbyUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const _searchTextUrl =
      'https://places.googleapis.com/v1/places:searchText';
  static const _fieldMask =
      'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types,places.rating,places.userRatingCount,places.currentOpeningHours.openNow,places.nationalPhoneNumber,places.internationalPhoneNumber,places.websiteUri,places.businessStatus,places.photos.name';

  Future<List<HospitalModel>> fetchNearbyMedicalPlaces({
    required LatLng origin,
    required HospitalCategory category,
    required String languageCode,
    double radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    try {
      if (category == HospitalCategory.emergency) {
        return _searchText(
          query: 'emergency hospital',
          origin: origin,
          languageCode: languageCode,
          maxResults: maxResults,
        );
      }

      if (category == HospitalCategory.all) {
        final nearby = await _searchNearby(
          includedTypes: const ['hospital', 'doctor', 'pharmacy'],
          origin: origin,
          languageCode: languageCode,
          radiusMeters: radiusMeters,
          maxResults: maxResults,
        );
        final emergency = await _searchText(
          query: 'emergency hospital',
          origin: origin,
          languageCode: languageCode,
          maxResults: 6,
        );
        return _mergeAndSort(origin, [...nearby, ...emergency]);
      }

      return _searchNearby(
        includedTypes: _includedTypesForCategory(category),
        origin: origin,
        languageCode: languageCode,
        radiusMeters: radiusMeters,
        maxResults: maxResults,
      );
    } on PlacesServiceException {
      rethrow;
    } catch (error) {
      throw PlacesServiceException(
        'places_search_failed',
        'Failed to fetch nearby medical places: $error',
      );
    }
  }

  Future<List<HospitalModel>> searchMedicalPlaces({
    required String query,
    required LatLng origin,
    required HospitalCategory category,
    required String languageCode,
    int maxResults = 10,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    try {
      return _searchText(
        query: category == HospitalCategory.emergency
            ? '$normalizedQuery emergency'
            : normalizedQuery,
        origin: origin,
        languageCode: languageCode,
        maxResults: maxResults,
        includedType: _includedTypeForTextSearch(category),
      );
    } on PlacesServiceException {
      rethrow;
    } catch (error) {
      throw PlacesServiceException(
        'places_search_failed',
        'Failed to search medical places: $error',
      );
    }
  }

  List<HospitalModel> demoMedicalPlaces({
    required LatLng origin,
    required HospitalCategory category,
  }) {
    final raw = [
      _demoPlace(
        id: 'demo_hospital_1',
        name: 'City Medical Center',
        address: '123 Health Blvd, Central District',
        origin: origin,
        latitudeOffset: 0.0068,
        longitudeOffset: 0.0042,
        category: HospitalCategory.hospital,
        rating: 4.8,
        userRatingCount: 420,
        openNow: true,
        phoneNumber: '+7 727 000 1001',
      ),
      _demoPlace(
        id: 'demo_clinic_1',
        name: 'Family Health Clinic',
        address: '78 Maple Avenue, East Side',
        origin: origin,
        latitudeOffset: -0.0044,
        longitudeOffset: 0.0061,
        category: HospitalCategory.clinic,
        rating: 4.6,
        userRatingCount: 182,
        openNow: true,
        phoneNumber: '+7 727 000 1002',
      ),
      _demoPlace(
        id: 'demo_pharmacy_1',
        name: 'MedCare Pharmacy',
        address: '45 Oak Street, Downtown',
        origin: origin,
        latitudeOffset: 0.0026,
        longitudeOffset: -0.0031,
        category: HospitalCategory.pharmacy,
        rating: 4.7,
        userRatingCount: 95,
        openNow: true,
        phoneNumber: '+7 727 000 1003',
      ),
      _demoPlace(
        id: 'demo_emergency_1',
        name: 'Downtown Emergency Center',
        address: '1 Emergency Lane, City Center',
        origin: origin,
        latitudeOffset: -0.0072,
        longitudeOffset: -0.0048,
        category: HospitalCategory.emergency,
        rating: 4.5,
        userRatingCount: 265,
        openNow: true,
        phoneNumber: '+7 727 000 1004',
      ),
      _demoPlace(
        id: 'demo_hospital_2',
        name: 'HealthPlus Hospital',
        address: '500 Medical Campus Dr, East District',
        origin: origin,
        latitudeOffset: 0.0095,
        longitudeOffset: -0.0018,
        category: HospitalCategory.hospital,
        rating: 4.4,
        userRatingCount: 310,
        openNow: false,
        phoneNumber: '+7 727 000 1005',
      ),
      _demoPlace(
        id: 'demo_clinic_2',
        name: 'Specialist Medical Clinic',
        address: '55 Wellness Drive, North Quarter',
        origin: origin,
        latitudeOffset: -0.0028,
        longitudeOffset: 0.0088,
        category: HospitalCategory.clinic,
        rating: 4.3,
        userRatingCount: 134,
        openNow: true,
        phoneNumber: '+7 727 000 1006',
      ),
    ];

    final filtered = raw.where((place) {
      if (category == HospitalCategory.all) return true;
      return place.category == category;
    }).toList()
      ..sort(
        (a, b) => (a.distanceMeters ?? double.infinity)
            .compareTo(b.distanceMeters ?? double.infinity),
      );

    return filtered;
  }

  String buildPhotoUrl(String photoName, {int maxWidthPx = 900}) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?maxWidthPx=$maxWidthPx&key=$_apiKey';
  }

  Future<List<HospitalModel>> _searchNearby({
    required List<String> includedTypes,
    required LatLng origin,
    required String languageCode,
    required double radiusMeters,
    required int maxResults,
  }) async {
    final response = await _client.post(
      Uri.parse(_searchNearbyUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode({
        'includedTypes': includedTypes,
        'maxResultCount': maxResults,
        'rankPreference': 'DISTANCE',
        'languageCode': languageCode,
        'locationRestriction': {
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
      throw PlacesServiceException('places_search_failed', response.body);
    }

    return _decodePlacesResponse(origin, response.body);
  }

  Future<List<HospitalModel>> _searchText({
    required String query,
    required LatLng origin,
    required String languageCode,
    required int maxResults,
    String? includedType,
  }) async {
    final payload = <String, dynamic>{
      'textQuery': query,
      'languageCode': languageCode,
      'maxResultCount': maxResults,
      'locationBias': {
        'circle': {
          'center': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
          'radius': 8000,
        },
      },
    };

    if (includedType != null) {
      payload['includedType'] = includedType;
    }

    final response = await _client.post(
      Uri.parse(_searchTextUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlacesServiceException('places_search_failed', response.body);
    }

    return _decodePlacesResponse(origin, response.body);
  }

  List<HospitalModel> _decodePlacesResponse(
    LatLng origin,
    String responseBody,
  ) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final places = (decoded['places'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) {
          final placeMap = Map<String, dynamic>.from(raw);
          final place = HospitalModel.fromPlacesApi(
            placeMap,
            distanceMeters: _computeDistanceFromOrigin(origin, placeMap),
          );
          return (place.photoName ?? '').isEmpty
              ? place
              : place.copyWith(photoUrl: buildPhotoUrl(place.photoName!));
        })
        .where((place) => place.name.isNotEmpty)
        .toList();

    return _mergeAndSort(origin, places);
  }

  List<HospitalModel> _mergeAndSort(
    LatLng origin,
    List<HospitalModel> places,
  ) {
    final deduped = <String, HospitalModel>{};
    for (final place in places) {
      final nextPlace = place.distanceMeters == null
          ? place.copyWith(
              distanceMeters: _computeDistance(
                origin: origin,
                destination: place.location,
              ),
            )
          : place;
      deduped[nextPlace.id] = nextPlace;
    }

    final list = deduped.values.toList()
      ..sort(
        (a, b) => (a.distanceMeters ?? double.infinity)
            .compareTo(b.distanceMeters ?? double.infinity),
      );
    return list;
  }

  List<String> _includedTypesForCategory(HospitalCategory category) {
    switch (category) {
      case HospitalCategory.hospital:
        return const ['hospital'];
      case HospitalCategory.clinic:
        return const ['doctor'];
      case HospitalCategory.pharmacy:
        return const ['pharmacy'];
      case HospitalCategory.emergency:
      case HospitalCategory.all:
        return const ['hospital', 'doctor', 'pharmacy'];
    }
  }

  String? _includedTypeForTextSearch(HospitalCategory category) {
    switch (category) {
      case HospitalCategory.hospital:
        return 'hospital';
      case HospitalCategory.clinic:
        return 'doctor';
      case HospitalCategory.pharmacy:
        return 'pharmacy';
      case HospitalCategory.emergency:
      case HospitalCategory.all:
        return null;
    }
  }

  double _computeDistanceFromOrigin(LatLng origin, Map<String, dynamic> raw) {
    final location = raw['location'] as Map<String, dynamic>? ?? const {};
    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return 0;

    return _computeDistance(
      origin: origin,
      destination: LatLng(latitude, longitude),
    );
  }

  double _computeDistance({
    required LatLng origin,
    required LatLng destination,
  }) {
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  HospitalModel _demoPlace({
    required String id,
    required String name,
    required String address,
    required LatLng origin,
    required double latitudeOffset,
    required double longitudeOffset,
    required HospitalCategory category,
    required double rating,
    required int userRatingCount,
    required bool openNow,
    required String phoneNumber,
  }) {
    final location = LatLng(
      origin.latitude + latitudeOffset,
      origin.longitude + longitudeOffset,
    );

    return HospitalModel(
      id: id,
      name: name,
      address: address,
      location: location,
      category: category,
      types: [category.name],
      rating: rating,
      userRatingCount: userRatingCount,
      openNow: openNow,
      phoneNumber: phoneNumber,
      distanceMeters: _computeDistance(
        origin: origin,
        destination: location,
      ),
      businessStatus: 'OPERATIONAL',
    );
  }
}

class PlacesServiceException implements Exception {
  const PlacesServiceException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'PlacesServiceException($code, $message)';
}
