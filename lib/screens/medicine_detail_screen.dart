import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_localizations.dart';
import '../services/health_services.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../widgets/common_widgets.dart';
import '../widgets/medicine_detail_section.dart';

class MedicineDetailScreen extends StatelessWidget {
  const MedicineDetailScreen({
    super.key,
    required this.medicine,
  });

  final MedicineModel medicine;

  Future<void> _toggleSaved(BuildContext context, bool isSaved) async {
    await context.read<UserProvider>().toggleSavedMedicine(medicine.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? context.tr('medicineRemovedFromSaved')
              : context.tr('medicineSavedForLater'),
        ),
        backgroundColor: isSaved ? AppColors.warning : AppColors.success,
      ),
    );
  }

  Future<void> _shareMedicine(BuildContext context) async {
    final shareText = '''
${medicine.name} (${medicine.genericName})

${medicine.description}

${context.tr('usageIndication')}: ${medicine.usage}
${context.tr('dosage')}: ${medicine.dosage}
${context.tr('howToUse')}: ${medicine.howToTake}

${context.tr('medicalEducationDisclaimer')}
''';

    // Clipboard fallback keeps sharing available without extra platform setup.
    await Clipboard.setData(ClipboardData(text: shareText.trim()));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('medicineCopiedForSharing')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isSaved = userProvider.isMedicineSaved(medicine.id);
    final allergyCheck = MedicineService.checkAllergyRisk(
      medicine,
      userProvider.allergies,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(medicine.name),
        actions: [
          IconButton(
            tooltip: context.tr('shareMedicine'),
            onPressed: () => _shareMedicine(context),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: isSaved
                ? context.tr('removeSavedMedicineCta')
                : context.tr('saveMedicine'),
            onPressed: () => _toggleSaved(context, isSaved),
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareMedicine(context),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(context.tr('shareMedicine')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: isSaved
                      ? context.tr('removeSavedMedicineCta')
                      : context.tr('saveMedicine'),
                  onTap: () => _toggleSaved(context, isSaved),
                  icon: isSaved
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_add_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientCard(
                    borderRadius: 28,
                    colors: const [Color(0xFF3B82F6), Color(0xFF14B8A6)],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'medicine-${medicine.id}',
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine.name,
                                    style: AppTextStyles.displayMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    medicine.genericName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              label: context.dynamicText(medicine.category),
                            ),
                            _InfoPill(
                              label: medicine.requiresPrescription
                                  ? context.tr('prescriptionRequired')
                                  : context.tr('nonPrescription'),
                            ),
                            _InfoPill(
                              label: medicine.manufacturer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.dynamicText(medicine.description),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (allergyCheck.isRisky) ...[
                    MedicineDetailSection(
                      title: context.tr('allergyWarning'),
                      icon: Icons.warning_amber_rounded,
                      accent: AppColors.danger,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MedicineDetailText(
                            text: context.tr('allergyWarningSubtitle'),
                          ),
                          const SizedBox(height: 10),
                          MedicineDetailBulletList(
                            items: allergyCheck.risks,
                            accent: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                  ],
                  MedicineDetailSection(
                    title: context.tr('usageIndication'),
                    icon: Icons.health_and_safety_outlined,
                    child: MedicineDetailText(
                      text: context.dynamicText(medicine.usage),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('dosage'),
                    icon: Icons.straighten_rounded,
                    child: MedicineDetailText(
                      text: context.dynamicText(medicine.dosage),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('howToUse'),
                    icon: Icons.schedule_rounded,
                    child: MedicineDetailText(
                      text: context.dynamicText(medicine.howToTake),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('warnings'),
                    icon: Icons.warning_rounded,
                    accent: AppColors.warning,
                    child: MedicineDetailBulletList(
                      items:
                          medicine.warnings.map(context.dynamicText).toList(),
                      accent: AppColors.warning,
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('sideEffects'),
                    icon: Icons.sick_outlined,
                    accent: AppColors.warning,
                    child: MedicineDetailBulletList(
                      items: medicine.sideEffects
                          .map(context.dynamicText)
                          .toList(),
                      accent: AppColors.warning,
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('contraindications'),
                    icon: Icons.block_rounded,
                    accent: AppColors.danger,
                    child: MedicineDetailBulletList(
                      items: medicine.contraindications
                          .map(context.dynamicText)
                          .toList(),
                      accent: AppColors.danger,
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('interactions'),
                    icon: Icons.compare_arrows_rounded,
                    child: MedicineDetailBulletList(
                      items: medicine.interactions
                          .map(context.dynamicText)
                          .toList(),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('storageInstructions'),
                    icon: Icons.inventory_2_outlined,
                    child: MedicineDetailText(
                      text: context.dynamicText(medicine.storageInstructions),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('pregnancyBreastfeeding'),
                    icon: Icons.family_restroom_rounded,
                    child: MedicineDetailText(
                      text:
                          context.dynamicText(medicine.pregnancyBreastfeeding),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('whenToSeeDoctor'),
                    icon: Icons.medical_services_outlined,
                    child: MedicineDetailText(
                      text: context.dynamicText(medicine.whenToSeeDoctor),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('emergencyWarning'),
                    icon: Icons.emergency_rounded,
                    accent: AppColors.danger,
                    backgroundColor: AppColors.danger.withValues(alpha: 0.06),
                    child: MedicineDetailText(
                      text: context.dynamicText(medicine.emergencyWarning),
                    ),
                  ),
                  MedicineDetailSection(
                    title: context.tr('ingredients'),
                    icon: Icons.science_outlined,
                    child: MedicineDetailBulletList(
                      items: medicine.ingredients
                          .map(context.dynamicText)
                          .toList(),
                    ),
                  ),
                  if (medicine.allergens.isNotEmpty)
                    MedicineDetailSection(
                      title: context.tr('knownAllergens'),
                      icon: Icons.shield_outlined,
                      accent: AppColors.danger,
                      child: MedicineDetailBulletList(
                        items: medicine.allergens
                            .map(context.dynamicText)
                            .toList(),
                        accent: AppColors.danger,
                      ),
                    ),
                  AppCard(
                    borderRadius: 24,
                    color: AppColors.primaryLight,
                    child: Text(
                      context.tr('medicalEducationDisclaimer'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
