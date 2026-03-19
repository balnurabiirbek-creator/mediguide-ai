import 'package:flutter/material.dart';

import '../models/hospital_model.dart';
import '../services/app_localizations.dart';
import '../utils/app_constants.dart';
import 'common_widgets.dart';

class HospitalSearchBar extends StatelessWidget {
  const HospitalSearchBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.suggestions,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSuggestionTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isLoading;
  final List<HospitalModel> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<HospitalModel> onSuggestionTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: context.tr('searchNearbyHint'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = suggestions[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      context.dynamicText(place.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      context.dynamicText(place.address),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSuggestionTap(place),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
