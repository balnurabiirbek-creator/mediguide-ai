import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../widgets/common_widgets.dart';
import 'hospital_detail_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final emergencyPlaces = _resolveEmergencyPlaces(userProvider.savedPlaces);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.dynamicText('Emergency Center')),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              colors: const [AppColors.danger, Color(0xFFF97316)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.dynamicText('Emergency help, instantly'),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              context.dynamicText(
                                'Call an ambulance, open the nearest emergency hospital, and review critical first actions.',
                              ),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: context.dynamicText('Call ambulance 112'),
                    onTap: () => _launchUri(Uri(scheme: 'tel', path: '112')),
                    icon: Icons.call_rounded,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Triage advice'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _EmergencyStep(
                    icon: Icons.warning_amber_rounded,
                    title: context.dynamicText('Call emergency help first'),
                    subtitle: context.dynamicText(
                      'If there is chest pain, breathing trouble, severe bleeding, or loss of consciousness, call 112 immediately.',
                    ),
                    accent: AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _EmergencyStep(
                    icon: Icons.location_on_rounded,
                    title: context.dynamicText('Open nearby emergency care'),
                    subtitle: context.dynamicText(
                      'Use the closest hospital below if you need urgent in-person treatment.',
                    ),
                    accent: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _EmergencyStep(
                    icon: Icons.description_outlined,
                    title: context.dynamicText('Keep essential info ready'),
                    subtitle: context.dynamicText(
                      'Prepare allergy notes, medicine list, and emergency contact details.',
                    ),
                    accent: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('nearbyMedicalHelp'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: emergencyPlaces.map((place) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EmergencyPlaceTile(place: place),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Emergency checklist'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Share your exact location.',
                    'Do not drive yourself if symptoms are severe.',
                    'Keep the phone line open after calling emergency services.',
                    'Bring ID, medicine list, and known allergy details.',
                  ].map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.dynamicText(item),
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MedicalPlace> _resolveEmergencyPlaces(List<MedicalPlace> savedPlaces) {
    final filtered = savedPlaces
        .where(
          (place) =>
              place.category == MedicalPlaceCategory.emergency ||
              place.category == MedicalPlaceCategory.hospital,
        )
        .take(3)
        .toList();
    if (filtered.isNotEmpty) return filtered;

    return const [
      MedicalPlace(
        id: 'emergency_preview_1',
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
        distanceMeters: 1200,
        businessStatus: 'OPERATIONAL',
      ),
      MedicalPlace(
        id: 'emergency_preview_2',
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
        distanceMeters: 1800,
        businessStatus: 'OPERATIONAL',
      ),
    ];
  }

  Future<void> _launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _EmergencyPlaceTile extends StatelessWidget {
  const _EmergencyPlaceTile({
    required this.place,
  });

  final MedicalPlace place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HospitalDetailScreen(place: place),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    place.address,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        place.openNow == false ? 'Closed' : 'Open now',
                        style: AppTextStyles.caption.copyWith(
                          color: place.openNow == false
                              ? AppColors.danger
                              : AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (place.distanceMeters != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${(place.distanceMeters! / 1000).toStringAsFixed(1)} km',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/dir/?api=1'
                  '&destination=${place.location.latitude},${place.location.longitude}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.route_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyStep extends StatelessWidget {
  const _EmergencyStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
