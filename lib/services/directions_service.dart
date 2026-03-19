import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../models/route_info_model.dart';
import 'google_api_config.dart';

class DirectionsService {
  DirectionsService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ??
            GoogleApiConfig.resolveWebServiceApiKey(
              fallback: DefaultFirebaseOptions.currentPlatform.apiKey,
            );

  final http.Client _client;
  final String _apiKey;

  static const _routesUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';
  static const _fieldMask =
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.warnings';

  Future<RouteInfoModel> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required TransportMode mode,
    required String languageCode,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(_routesUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': _fieldMask,
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
          'travelMode': _travelMode(mode),
          'languageCode': languageCode,
          'units': 'METRIC',
          'computeAlternativeRoutes': false,
          'departureTime': DateTime.now().toUtc().toIso8601String(),
          if (mode == TransportMode.driving)
            'routingPreference': 'TRAFFIC_AWARE',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackRoute(
          origin: origin,
          destination: destination,
          mode: mode,
          rawMessage: response.body,
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List? ?? const [];
      if (routes.isEmpty) {
        return _fallbackRoute(
          origin: origin,
          destination: destination,
          mode: mode,
          rawMessage: null,
        );
      }

      final firstRoute = Map<String, dynamic>.from(routes.first as Map);
      final polyline = (firstRoute['polyline'] as Map<String, dynamic>? ??
              const <String, dynamic>{})['encodedPolyline'] as String? ??
          '';
      final warnings = (firstRoute['warnings'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .join(' ');

      return RouteInfoModel(
        mode: mode,
        distanceMeters: (firstRoute['distanceMeters'] as num?)?.toInt() ?? 0,
        duration: _parseDuration(firstRoute['duration'] as String? ?? '0s'),
        polylinePoints: _decodePolyline(polyline),
        warning: warnings.isEmpty ? _defaultWarning(mode) : warnings,
      );
    } catch (error) {
      return _fallbackRoute(
        origin: origin,
        destination: destination,
        mode: mode,
        rawMessage: error.toString(),
      );
    }
  }

  Future<Map<TransportMode, RouteInfoModel>> fetchRouteOptions({
    required LatLng origin,
    required LatLng destination,
    required String languageCode,
  }) async {
    final entries = await Future.wait(
      TransportMode.values.map((mode) async {
        final route = await fetchRoute(
          origin: origin,
          destination: destination,
          mode: mode,
          languageCode: languageCode,
        );
        return MapEntry(mode, route);
      }),
    );

    return Map<TransportMode, RouteInfoModel>.fromEntries(entries);
  }

  Uri buildExternalDirectionsUri({
    required LatLng origin,
    required LatLng destination,
    required TransportMode mode,
  }) {
    final travelMode = switch (mode) {
      TransportMode.walking => 'walking',
      TransportMode.driving => 'driving',
      TransportMode.transit => 'transit',
    };

    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=$travelMode',
    );
  }

  String _travelMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return 'DRIVE';
      case TransportMode.walking:
        return 'WALK';
      case TransportMode.transit:
        return 'TRANSIT';
    }
  }

  String? _defaultWarning(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return 'Walking directions may include paths with limited accessibility.';
      case TransportMode.transit:
        return null;
      case TransportMode.driving:
        return null;
    }
  }

  String _routeFailureMessage(TransportMode mode, String? rawMessage) {
    if (mode == TransportMode.transit) {
      return 'Transit directions are currently unavailable for this area.';
    }
    if ((rawMessage ?? '').contains('API key')) {
      return 'Directions API key is unavailable.';
    }
    return 'Route directions are currently unavailable. Please try again.';
  }

  RouteInfoModel _fallbackRoute({
    required LatLng origin,
    required LatLng destination,
    required TransportMode mode,
    required String? rawMessage,
  }) {
    if (mode == TransportMode.transit) {
      return RouteInfoModel.unavailable(
        mode: mode,
        errorMessage: _routeFailureMessage(mode, rawMessage),
      );
    }

    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    ).round();
    final adjustedDistance = distanceMeters < 250 ? 250 : distanceMeters;
    final speedMetersPerMinute = mode == TransportMode.walking ? 78 : 520;
    final durationMinutes =
        (adjustedDistance / speedMetersPerMinute).ceil().clamp(1, 240);
    final midpoint = LatLng(
      (origin.latitude + destination.latitude) / 2 +
          (mode == TransportMode.walking ? 0.0007 : 0.0003),
      (origin.longitude + destination.longitude) / 2 -
          (mode == TransportMode.walking ? 0.0005 : 0.0002),
    );

    return RouteInfoModel(
      mode: mode,
      distanceMeters: adjustedDistance,
      duration: Duration(minutes: durationMinutes),
      polylinePoints: [origin, midpoint, destination],
      warning: mode == TransportMode.walking
          ? 'Showing a demo walking route until live directions are available.'
          : 'Showing a demo driving route until live directions are available.',
      isFallback: true,
    );
  }

  Duration _parseDuration(String value) {
    final cleaned = value.replaceAll('s', '');
    final seconds = double.tryParse(cleaned)?.round() ?? 0;
    return Duration(seconds: seconds);
  }

  List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];

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
      final latChange = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      latitude += latChange;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final lngChange = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      longitude += lngChange;

      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }

    return points;
  }
}
