import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

class HospitalDetailScreen extends StatelessWidget {
  const HospitalDetailScreen({
    super.key,
    required this.place,
  });

  final MedicalPlace place;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isSaved = userProvider.isPlaceSaved(place.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('hospitalDetails')),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: (place.photoUrl ?? '').isNotEmpty
                    ? Image.network(
                        place.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackBanner(),
                      )
                    : _buildFallbackBanner(),
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
                        context.dynamicText(place.name),
                        style: AppTextStyles.displayMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.dynamicText(place.address),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => _toggleSaved(context, isSaved),
                  icon: Icon(
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isSaved ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagChip(label: _categoryLabel(context), isSelected: true),
                if (place.rating != null)
                  TagChip(
                    label:
                        '⭐ ${place.rating!.toStringAsFixed(1)} (${place.userRatingCount ?? 0})',
                  ),
                if (place.openNow != null)
                  TagChip(
                    label: place.openNow!
                        ? context.tr('openNow')
                        : context.tr('closed'),
                  ),
                if (place.distanceMeters != null)
                  TagChip(
                    label:
                        '${context.tr('distance')}: ${_distanceLabel(place.distanceMeters)}',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Quick actions'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: context.tr('openInMaps'),
                          onTap: () => _launchUri(_mapsUri()),
                          icon: Icons.route_rounded,
                        ),
                      ),
                    ],
                  ),
                  if ((place.phoneNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _launchUri(_phoneUri()),
                      icon: const Icon(Icons.phone_outlined),
                      label: Text(context.tr('call')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                            double.infinity, AppDimensions.buttonHeight),
                      ),
                    ),
                  ],
                  if ((place.websiteUri ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _launchUri(Uri.parse(place.websiteUri!)),
                      icon: const Icon(Icons.language_rounded),
                      label: Text(context.tr('openWebsite')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                            double.infinity, AppDimensions.buttonHeight),
                      ),
                    ),
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
                    icon: Icons.local_hospital_rounded,
                    label: context.dynamicText('Category'),
                    value: _categoryLabel(context),
                  ),
                  InfoRow(
                    icon: Icons.place_outlined,
                    label: context.tr('coordinates'),
                    value:
                        '${place.location.latitude.toStringAsFixed(5)}, ${place.location.longitude.toStringAsFixed(5)}',
                  ),
                  if ((place.phoneNumber ?? '').isNotEmpty)
                    InfoRow(
                      icon: Icons.phone_outlined,
                      label: context.tr('call'),
                      value: place.phoneNumber!,
                    ),
                  if ((place.websiteUri ?? '').isNotEmpty)
                    InfoRow(
                      icon: Icons.language_rounded,
                      label: context.tr('openWebsite'),
                      value: place.websiteUri!,
                    ),
                  if ((place.businessStatus ?? '').isNotEmpty)
                    InfoRow(
                      icon: Icons.verified_rounded,
                      label: context.dynamicText('Status'),
                      value: context.dynamicText(place.businessStatus!),
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
                    context.dynamicText('Patient reviews'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const _ReviewTile(
                    author: 'Aru',
                    rating: '4.8',
                    review:
                        'Fast registration, clear directions, and polite staff at the front desk.',
                  ),
                  const SizedBox(height: 12),
                  const _ReviewTile(
                    author: 'Miras',
                    rating: '4.6',
                    review:
                        'Helpful emergency response and easy to locate from the app map.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandBlue, AppTheme.brandMint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 44,
            ),
            const SizedBox(height: 10),
            Text(
              place.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(BuildContext context) {
    switch (place.category) {
      case MedicalPlaceCategory.hospital:
        return context.tr('hospital');
      case MedicalPlaceCategory.clinic:
        return context.tr('clinic');
      case MedicalPlaceCategory.pharmacy:
        return context.tr('pharmacy');
      case MedicalPlaceCategory.emergency:
        return context.tr('emergency');
      case MedicalPlaceCategory.unknown:
        return context.tr('all');
    }
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Uri _mapsUri() {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${place.location.latitude},${place.location.longitude}',
    );
  }

  Uri _phoneUri() {
    return Uri(
      scheme: 'tel',
      path: (place.phoneNumber ?? '').replaceAll(RegExp(r'[^0-9+]'), ''),
    );
  }

  Future<void> _toggleSaved(BuildContext context, bool isSaved) async {
    final userProvider = context.read<UserProvider>();
    if (isSaved) {
      await userProvider.removeSavedPlace(place.id);
    } else {
      await userProvider.upsertSavedPlace(place);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(isSaved ? 'placeRemoved' : 'placeSaved')),
        backgroundColor: isSaved ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) return;
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.author,
    required this.rating,
    required this.review,
  });

  final String author;
  final String rating;
  final String review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(author, style: AppTextStyles.headlineSmall),
              const Spacer(),
              Text('⭐ $rating', style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(review, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
