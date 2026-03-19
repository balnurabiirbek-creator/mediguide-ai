import 'package:flutter/material.dart';

import '../models/route_info_model.dart';
import '../services/app_localizations.dart';
import '../utils/app_constants.dart';

class TransportModeSelector extends StatelessWidget {
  const TransportModeSelector({
    super.key,
    required this.selectedMode,
    required this.routeOptions,
    required this.onChanged,
  });

  final TransportMode selectedMode;
  final Map<TransportMode, RouteInfoModel> routeOptions;
  final ValueChanged<TransportMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransportMode.values.map((mode) {
        final route = routeOptions[mode];
        final isSelected = mode == selectedMode;

        return InkWell(
          onTap: () => onChanged(mode),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(mode),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr(_label(mode)),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  route == null
                      ? context.tr('loading')
                      : (route.isAvailable
                          ? '${route.formattedDuration} • ${route.formattedDistance}'
                          : context.tr('routeUnavailableLabel')),
                  style: AppTextStyles.caption.copyWith(
                    color:
                        isSelected ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _icon(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return Icons.directions_walk_rounded;
      case TransportMode.driving:
        return Icons.directions_car_rounded;
      case TransportMode.transit:
        return Icons.directions_bus_rounded;
    }
  }

  String _label(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return 'walking';
      case TransportMode.driving:
        return 'driving';
      case TransportMode.transit:
        return 'publicTransport';
    }
  }
}
