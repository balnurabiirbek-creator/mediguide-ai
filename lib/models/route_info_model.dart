import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TransportMode {
  walking,
  driving,
  transit,
}

class RouteInfoModel {
  const RouteInfoModel({
    required this.mode,
    required this.distanceMeters,
    required this.duration,
    required this.polylinePoints,
    this.warning,
    this.errorMessage,
    this.isAvailable = true,
    this.isFallback = false,
  });

  const RouteInfoModel.unavailable({
    required this.mode,
    required this.errorMessage,
  })  : distanceMeters = 0,
        duration = Duration.zero,
        polylinePoints = const [],
        warning = null,
        isAvailable = false,
        isFallback = false;

  final TransportMode mode;
  final int distanceMeters;
  final Duration duration;
  final List<LatLng> polylinePoints;
  final String? warning;
  final String? errorMessage;
  final bool isAvailable;
  final bool isFallback;

  String get formattedDistance {
    if (!isAvailable) return '--';
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (!isAvailable) return 'Unavailable';
    if (duration.inMinutes < 1) return '< 1 min';
    if (duration.inHours < 1) return '${duration.inMinutes} min';
    final minutes = duration.inMinutes.remainder(60);
    return '${duration.inHours} h ${minutes.toString().padLeft(2, '0')} min';
  }
}
