import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models.dart';

enum HospitalCategory {
  all,
  hospital,
  clinic,
  pharmacy,
  emergency,
}

class HospitalModel {
  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.category,
    required this.types,
    this.rating,
    this.userRatingCount,
    this.openNow,
    this.phoneNumber,
    this.websiteUri,
    this.distanceMeters,
    this.photoName,
    this.photoUrl,
    this.businessStatus,
  });

  final String id;
  final String name;
  final String address;
  final LatLng location;
  final HospitalCategory category;
  final List<String> types;
  final double? rating;
  final int? userRatingCount;
  final bool? openNow;
  final String? phoneNumber;
  final String? websiteUri;
  final double? distanceMeters;
  final String? photoName;
  final String? photoUrl;
  final String? businessStatus;

  factory HospitalModel.fromPlacesApi(
    Map<String, dynamic> map, {
    double? distanceMeters,
    String? photoUrl,
  }) {
    final displayName = map['displayName'] as Map<String, dynamic>? ?? const {};
    final location = map['location'] as Map<String, dynamic>? ?? const {};
    final types = List<String>.from(map['types'] as List? ?? const []);
    final photos = map['photos'] as List? ?? const [];
    final firstPhoto = photos.isNotEmpty
        ? Map<String, dynamic>.from(photos.first as Map)
        : const <String, dynamic>{};

    return HospitalModel(
      id: (map['id'] as String? ?? '').trim(),
      name: (displayName['text'] as String? ?? '').trim(),
      address: (map['formattedAddress'] as String? ?? '').trim(),
      location: LatLng(
        (location['latitude'] as num?)?.toDouble() ?? 0,
        (location['longitude'] as num?)?.toDouble() ?? 0,
      ),
      category: hospitalCategoryFromPlacesTypes(
        primaryType: (map['primaryType'] as String?)?.trim(),
        types: types,
      ),
      types: types,
      rating: (map['rating'] as num?)?.toDouble(),
      userRatingCount: (map['userRatingCount'] as num?)?.toInt(),
      openNow: (map['currentOpeningHours'] as Map<String, dynamic>?)?['openNow']
          as bool?,
      phoneNumber:
          ((map['internationalPhoneNumber'] as String?)?.trim().isNotEmpty ==
                  true)
              ? (map['internationalPhoneNumber'] as String).trim()
              : (map['nationalPhoneNumber'] as String?)?.trim(),
      websiteUri: (map['websiteUri'] as String?)?.trim(),
      distanceMeters: distanceMeters,
      photoName: (firstPhoto['name'] as String?)?.trim(),
      photoUrl: photoUrl,
      businessStatus: (map['businessStatus'] as String?)?.trim(),
    );
  }

  factory HospitalModel.fromMedicalPlace(MedicalPlace place) {
    return HospitalModel(
      id: place.id,
      name: place.name,
      address: place.address,
      location: place.location,
      category: hospitalCategoryFromMedicalPlaceCategory(place.category),
      types: place.types,
      rating: place.rating,
      userRatingCount: place.userRatingCount,
      openNow: place.openNow,
      phoneNumber: place.phoneNumber,
      websiteUri: place.websiteUri,
      distanceMeters: place.distanceMeters,
      photoName: place.photoName,
      photoUrl: place.photoUrl,
      businessStatus: place.businessStatus,
    );
  }

  MedicalPlace toMedicalPlace() {
    return MedicalPlace(
      id: id,
      name: name,
      address: address,
      location: location,
      category: medicalPlaceCategoryFromHospitalCategory(category),
      types: List<String>.from(types),
      rating: rating,
      userRatingCount: userRatingCount,
      openNow: openNow,
      phoneNumber: phoneNumber,
      websiteUri: websiteUri,
      distanceMeters: distanceMeters,
      photoName: photoName,
      photoUrl: photoUrl,
      businessStatus: businessStatus,
    );
  }

  HospitalModel copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? location,
    HospitalCategory? category,
    List<String>? types,
    double? rating,
    int? userRatingCount,
    bool? openNow,
    String? phoneNumber,
    String? websiteUri,
    double? distanceMeters,
    String? photoName,
    String? photoUrl,
    String? businessStatus,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      category: category ?? this.category,
      types: types ?? this.types,
      rating: rating ?? this.rating,
      userRatingCount: userRatingCount ?? this.userRatingCount,
      openNow: openNow ?? this.openNow,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      websiteUri: websiteUri ?? this.websiteUri,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      photoName: photoName ?? this.photoName,
      photoUrl: photoUrl ?? this.photoUrl,
      businessStatus: businessStatus ?? this.businessStatus,
    );
  }

  String get displayCategory {
    switch (category) {
      case HospitalCategory.all:
        return 'Medical Place';
      case HospitalCategory.hospital:
        return 'Hospital';
      case HospitalCategory.clinic:
        return 'Clinic';
      case HospitalCategory.pharmacy:
        return 'Pharmacy';
      case HospitalCategory.emergency:
        return 'Emergency';
    }
  }
}

HospitalCategory hospitalCategoryFromPlacesTypes({
  String? primaryType,
  List<String> types = const [],
}) {
  final normalized = [
    if (primaryType != null && primaryType.isNotEmpty)
      primaryType.toLowerCase(),
    ...types.map((type) => type.toLowerCase()),
  ];

  if (normalized.any((type) => type.contains('pharmacy'))) {
    return HospitalCategory.pharmacy;
  }
  if (normalized.any((type) => type.contains('emergency'))) {
    return HospitalCategory.emergency;
  }
  if (normalized.any((type) => type.contains('hospital'))) {
    return HospitalCategory.hospital;
  }
  if (normalized.any(
    (type) =>
        type.contains('doctor') ||
        type.contains('clinic') ||
        type.contains('medical'),
  )) {
    return HospitalCategory.clinic;
  }

  return HospitalCategory.hospital;
}

MedicalPlaceCategory medicalPlaceCategoryFromHospitalCategory(
  HospitalCategory category,
) {
  switch (category) {
    case HospitalCategory.hospital:
      return MedicalPlaceCategory.hospital;
    case HospitalCategory.clinic:
      return MedicalPlaceCategory.clinic;
    case HospitalCategory.pharmacy:
      return MedicalPlaceCategory.pharmacy;
    case HospitalCategory.emergency:
      return MedicalPlaceCategory.emergency;
    case HospitalCategory.all:
      return MedicalPlaceCategory.unknown;
  }
}

HospitalCategory hospitalCategoryFromMedicalPlaceCategory(
  MedicalPlaceCategory category,
) {
  switch (category) {
    case MedicalPlaceCategory.hospital:
      return HospitalCategory.hospital;
    case MedicalPlaceCategory.clinic:
      return HospitalCategory.clinic;
    case MedicalPlaceCategory.pharmacy:
      return HospitalCategory.pharmacy;
    case MedicalPlaceCategory.emergency:
      return HospitalCategory.emergency;
    case MedicalPlaceCategory.unknown:
      return HospitalCategory.all;
  }
}
