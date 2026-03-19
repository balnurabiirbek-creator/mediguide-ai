import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_localizations.dart';
import '../services/health_services.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../widgets/common_widgets.dart';
import '../widgets/medicine_card.dart';
import 'medicine_detail_screen.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<MedicineModel> _medicines = MedicineService.getAllMedicines();
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Analgesic',
    'Antibiotic',
    'Antihistamine',
    'NSAID',
    'Antidiabetic',
    'Proton Pump',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    var next = MedicineService.searchMedicines(query);

    if (_selectedCategory != 'All') {
      next = next
          .where(
            (medicine) => medicine.category
                .toLowerCase()
                .contains(_selectedCategory.toLowerCase()),
          )
          .toList();
    }

    setState(() => _medicines = next);
  }

  void _search(String query) {
    _applyFilters();
  }

  void _filterByCategory(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _openMedicineDetail(MedicineModel medicine) {
    context.read<UserProvider>().addRecentActivity({
      'icon': '💊',
      'title': context.tr('medicineViewed'),
      'subtitle': medicine.name,
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: MedicineDetailScreen(medicine: medicine),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  List<MedicineModel> _savedMedicines(UserProvider userProvider) {
    return userProvider.savedMedicineIds
        .map(MedicineService.getMedicineById)
        .whereType<MedicineModel>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final savedMedicines = _savedMedicines(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('medicineGuide')),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingL,
              0,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientCard(
                  colors: const [Color(0xFF3B82F6), Color(0xFF14B8A6)],
                  borderRadius: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.medication_liquid_rounded,
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
                              context.tr('medicineHeroTitle'),
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('medicineHeroSubtitle'),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.tr('searchMedicines'),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                    ),
                  ),
                  onChanged: _search,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;

                      return GestureDetector(
                        onTap: () => _filterByCategory(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category == 'All'
                                  ? context.tr('all')
                                  : context.dynamicText(category),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (savedMedicines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingL,
                0,
                AppDimensions.paddingL,
                AppDimensions.paddingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('savedMedicines'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedMedicines.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final medicine = savedMedicines[index];
                        return _SavedMedicineTile(
                          medicine: medicine,
                          onTap: () => _openMedicineDetail(medicine),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _medicines.isEmpty
                ? EmptyState(
                    emoji: '🔍',
                    title: context.tr('noMedicinesFound'),
                    subtitle: context.tr('noMedicinesFoundSubtitle'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL,
                    ),
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _medicines[index];
                      return AnimatedListItem(
                        index: index,
                        child: MedicineCard(
                          medicine: medicine,
                          isSaved: userProvider.isMedicineSaved(medicine.id),
                          onTap: () => _openMedicineDetail(medicine),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SavedMedicineTile extends StatelessWidget {
  const _SavedMedicineTile({
    required this.medicine,
    required this.onTap,
  });

  final MedicineModel medicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 228,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'medicine-${medicine.id}',
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            Text(
              medicine.name,
              style: AppTextStyles.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              medicine.genericName,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
