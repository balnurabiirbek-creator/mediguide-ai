import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? dateOfBirth;
  final String? bloodType;
  final double? weight;
  final double? height;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> medications;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.dateOfBirth,
    this.bloodType,
    this.weight,
    this.height,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      dateOfBirth: map['dateOfBirth'],
      bloodType: map['bloodType'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      allergies: List<String>.from(map['allergies'] ?? []),
      conditions: List<String>.from(map['conditions'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'bloodType': bloodType,
      'weight': weight,
      'height': height,
      'allergies': allergies,
      'conditions': conditions,
      'medications': medications,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? phone,
    String? dateOfBirth,
    String? bloodType,
    double? weight,
    double? height,
    List<String>? allergies,
    List<String>? conditions,
    List<String>? medications,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      createdAt: createdAt,
    );
  }
}

// lib/models/symptom_model.dart
enum SeverityLevel { low, medium, high }

class SymptomAnalysisResult {
  final List<String> symptoms;
  final List<DiagnosisItem> possibleConditions;
  final SeverityLevel severity;
  final String recommendation;
  final List<String> suggestedActions;
  final List<String> warningSignals;
  final bool shouldSeeDoctor;
  final DateTime analyzedAt;

  SymptomAnalysisResult({
    required this.symptoms,
    required this.possibleConditions,
    required this.severity,
    required this.recommendation,
    required this.suggestedActions,
    required this.warningSignals,
    required this.shouldSeeDoctor,
    required this.analyzedAt,
  });
}

class DiagnosisItem {
  final String condition;
  final String description;
  final double confidence;
  final List<String> matchedSymptoms;

  DiagnosisItem({
    required this.condition,
    required this.description,
    required this.confidence,
    required this.matchedSymptoms,
  });
}

// lib/models/medicine_model.dart
class MedicineModel {
  final String id;
  final String name;
  final String genericName;
  final String category;
  final String description;
  final String usage;
  final String dosage;
  final String howToTake;
  final List<String> warnings;
  final List<String> sideEffects;
  final List<String> ingredients;
  final List<String> allergens;
  final List<String> contraindications;
  final List<String> interactions;
  final String storageInstructions;
  final String pregnancyBreastfeeding;
  final String whenToSeeDoctor;
  final String emergencyWarning;
  final String manufacturer;
  final bool requiresPrescription;
  final String? imageUrl;

  MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.category,
    required this.description,
    required this.usage,
    required this.dosage,
    required this.howToTake,
    required this.warnings,
    required this.sideEffects,
    required this.ingredients,
    required this.allergens,
    required this.contraindications,
    required this.interactions,
    required this.storageInstructions,
    required this.pregnancyBreastfeeding,
    required this.whenToSeeDoctor,
    required this.emergencyWarning,
    required this.manufacturer,
    required this.requiresPrescription,
    this.imageUrl,
  });
}

// lib/models/health_tip_model.dart
class HealthTip {
  final String id;
  final String title;
  final String content;
  final String category;
  final String icon;
  final String color;

  HealthTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.icon,
    required this.color,
  });
}

enum MedicalPlaceCategory { hospital, clinic, pharmacy, emergency, unknown }

enum MapTransportMode { driving, walking, transit, scooter }

class MedicalPlace {
  const MedicalPlace({
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
    this.photoAttribution,
    this.businessStatus,
  });

  final String id;
  final String name;
  final String address;
  final LatLng location;
  final MedicalPlaceCategory category;
  final List<String> types;
  final double? rating;
  final int? userRatingCount;
  final bool? openNow;
  final String? phoneNumber;
  final String? websiteUri;
  final double? distanceMeters;
  final String? photoName;
  final String? photoUrl;
  final String? photoAttribution;
  final String? businessStatus;

  String get categoryKey {
    switch (category) {
      case MedicalPlaceCategory.hospital:
        return 'hospital';
      case MedicalPlaceCategory.clinic:
        return 'clinic';
      case MedicalPlaceCategory.pharmacy:
        return 'pharmacy';
      case MedicalPlaceCategory.emergency:
        return 'emergency';
      case MedicalPlaceCategory.unknown:
        return 'all';
    }
  }

  factory MedicalPlace.fromPlacesApi(
    Map<String, dynamic> map, {
    double? distanceMeters,
    String? photoUrl,
  }) {
    final displayName = map['displayName'] as Map<String, dynamic>? ?? const {};
    final location = map['location'] as Map<String, dynamic>? ?? const {};
    final photos = map['photos'] as List? ?? const [];
    final firstPhoto = photos.isNotEmpty
        ? Map<String, dynamic>.from(photos.first as Map)
        : const <String, dynamic>{};
    final authorAttributions =
        firstPhoto['authorAttributions'] as List? ?? const [];
    final firstAttribution = authorAttributions.isNotEmpty
        ? Map<String, dynamic>.from(authorAttributions.first as Map)
        : const <String, dynamic>{};

    return MedicalPlace(
      id: (map['id'] as String? ?? '').trim(),
      name: (displayName['text'] as String? ?? '').trim(),
      address: (map['formattedAddress'] as String? ?? '').trim(),
      location: LatLng(
        (location['latitude'] as num?)?.toDouble() ?? 0,
        (location['longitude'] as num?)?.toDouble() ?? 0,
      ),
      category: medicalPlaceCategoryFromTypes(
        List<String>.from(map['types'] as List? ?? const []),
      ),
      types: List<String>.from(map['types'] as List? ?? const []),
      rating: (map['rating'] as num?)?.toDouble(),
      userRatingCount: (map['userRatingCount'] as num?)?.toInt(),
      openNow: (map['currentOpeningHours'] as Map<String, dynamic>?)?['openNow']
          as bool?,
      phoneNumber: (map['internationalPhoneNumber'] as String?)?.trim(),
      websiteUri: (map['websiteUri'] as String?)?.trim(),
      distanceMeters: distanceMeters,
      photoName: (firstPhoto['name'] as String?)?.trim(),
      photoUrl: photoUrl,
      photoAttribution: (firstAttribution['displayName'] as String?)?.trim(),
      businessStatus: (map['businessStatus'] as String?)?.trim(),
    );
  }

  factory MedicalPlace.fromFirestore(Map<String, dynamic> map) {
    return MedicalPlace(
      id: (map['id'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      address: (map['address'] as String? ?? '').trim(),
      location: LatLng(
        (map['latitude'] as num?)?.toDouble() ?? 0,
        (map['longitude'] as num?)?.toDouble() ?? 0,
      ),
      category: medicalPlaceCategoryFromString(map['category'] as String?),
      types: List<String>.from(map['types'] as List? ?? const []),
      rating: (map['rating'] as num?)?.toDouble(),
      userRatingCount: (map['userRatingCount'] as num?)?.toInt(),
      openNow: map['openNow'] as bool?,
      phoneNumber: (map['phoneNumber'] as String?)?.trim(),
      websiteUri: (map['websiteUri'] as String?)?.trim(),
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble(),
      photoName: (map['photoName'] as String?)?.trim(),
      photoUrl: (map['photoUrl'] as String?)?.trim(),
      photoAttribution: (map['photoAttribution'] as String?)?.trim(),
      businessStatus: (map['businessStatus'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': category.name,
      'types': types,
      'rating': rating,
      'userRatingCount': userRatingCount,
      'openNow': openNow,
      'phoneNumber': phoneNumber,
      'websiteUri': websiteUri,
      'distanceMeters': distanceMeters,
      'photoName': photoName,
      'photoUrl': photoUrl,
      'photoAttribution': photoAttribution,
      'businessStatus': businessStatus,
    };
  }

  MedicalPlace copyWith({
    String? name,
    String? address,
    LatLng? location,
    MedicalPlaceCategory? category,
    List<String>? types,
    double? rating,
    int? userRatingCount,
    bool? openNow,
    String? phoneNumber,
    String? websiteUri,
    double? distanceMeters,
    String? photoName,
    String? photoUrl,
    String? photoAttribution,
    String? businessStatus,
  }) {
    return MedicalPlace(
      id: id,
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
      photoAttribution: photoAttribution ?? this.photoAttribution,
      businessStatus: businessStatus ?? this.businessStatus,
    );
  }
}

class SavedSearchEntry {
  const SavedSearchEntry({
    required this.id,
    required this.query,
    required this.category,
    required this.updatedAt,
  });

  final String id;
  final String query;
  final String category;
  final DateTime updatedAt;

  factory SavedSearchEntry.fromFirestore(String id, Map<String, dynamic> map) {
    return SavedSearchEntry(
      id: id,
      query: (map['query'] as String? ?? '').trim(),
      category: (map['category'] as String? ?? 'all').trim(),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'query': query,
      'category': category,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PlaceRouteInfo {
  const PlaceRouteInfo({
    required this.mode,
    required this.distanceMeters,
    required this.duration,
    required this.polylinePoints,
    this.warning,
    this.isFallback = false,
  });

  final MapTransportMode mode;
  final int distanceMeters;
  final Duration duration;
  final List<LatLng> polylinePoints;
  final String? warning;
  final bool isFallback;
}

MedicalPlaceCategory medicalPlaceCategoryFromTypes(List<String> types) {
  final normalized = types.map((type) => type.toLowerCase()).toList();
  if (normalized.any((type) => type.contains('pharmacy'))) {
    return MedicalPlaceCategory.pharmacy;
  }
  if (normalized.any((type) => type.contains('hospital'))) {
    return MedicalPlaceCategory.hospital;
  }
  if (normalized.any((type) =>
      type.contains('doctor') ||
      type.contains('clinic') ||
      type.contains('medical'))) {
    return MedicalPlaceCategory.clinic;
  }
  if (normalized.any((type) => type.contains('emergency'))) {
    return MedicalPlaceCategory.emergency;
  }
  return MedicalPlaceCategory.unknown;
}

MedicalPlaceCategory medicalPlaceCategoryFromString(String? value) {
  switch ((value ?? '').trim()) {
    case 'hospital':
      return MedicalPlaceCategory.hospital;
    case 'clinic':
      return MedicalPlaceCategory.clinic;
    case 'pharmacy':
      return MedicalPlaceCategory.pharmacy;
    case 'emergency':
      return MedicalPlaceCategory.emergency;
    default:
      return MedicalPlaceCategory.unknown;
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is Map<String, dynamic> && value['_seconds'] is int) {
    return DateTime.fromMillisecondsSinceEpoch(
      (value['_seconds'] as int) * 1000,
    );
  }
  return DateTime.now();
}
