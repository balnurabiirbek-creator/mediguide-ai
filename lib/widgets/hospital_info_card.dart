import 'package:flutter/material.dart';

import '../models/hospital_model.dart';
import '../services/app_localizations.dart';
import '../utils/app_constants.dart';
import 'common_widgets.dart';

class HospitalInfoCard extends StatelessWidget {
  const HospitalInfoCard({
    super.key,
    required this.hospital,
    required this.onTap,
    this.onDirectionsTap,
    this.onCallTap,
    this.isSelected = false,
    this.showActions = true,
    this.compact = false,
  });

  final HospitalModel hospital;
  final VoidCallback onTap;
  final VoidCallback? onDirectionsTap;
  final VoidCallback? onCallTap;
  final bool isSelected;
  final bool showActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderRadius: compact ? 20 : 24,
      padding: EdgeInsets.zero,
      color: isSelected ? const Color(0xFFF7FBFF) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: (hospital.photoUrl ?? '').isNotEmpty
                    ? Image.network(
                        hospital.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPhotoFallback(),
                      )
                    : _buildPhotoFallback(),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.dynamicText(hospital.name),
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.dynamicText(hospital.address),
                            style: AppTextStyles.bodySmall,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          context.tr('selectedLabel'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaPill(
                      icon: Icons.category_outlined,
                      label: context.dynamicText(hospital.displayCategory),
                    ),
                    if (hospital.distanceMeters != null)
                      _MetaPill(
                        icon: Icons.near_me_rounded,
                        label: _distanceLabel(hospital.distanceMeters),
                      ),
                    if (hospital.rating != null)
                      _MetaPill(
                        icon: Icons.star_rounded,
                        label: hospital.rating!.toStringAsFixed(1),
                      ),
                    if (hospital.openNow != null)
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        label: hospital.openNow!
                            ? context.tr('openNow')
                            : context.tr('closed'),
                        accent: hospital.openNow!
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDirectionsTap ?? onTap,
                          icon: const Icon(Icons.route_rounded),
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(context.tr('directions')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCallTap,
                          icon: const Icon(Icons.call_rounded),
                          label: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(context.tr('call')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 42,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
