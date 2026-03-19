const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

class GoogleApiConfig {
  const GoogleApiConfig._();

  static String resolveWebServiceApiKey({String? fallback}) {
    if (_googleMapsApiKey.isNotEmpty) {
      return _googleMapsApiKey;
    }

    if ((fallback ?? '').isNotEmpty) {
      return fallback!;
    }

    throw StateError(
      'Google Maps API key is not configured. Provide GOOGLE_MAPS_API_KEY '
      'with --dart-define for Places and Routes web service calls.',
    );
  }

  static bool get hasDartDefineKey => _googleMapsApiKey.isNotEmpty;
}
