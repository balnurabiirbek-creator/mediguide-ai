import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../widgets/common_widgets.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.embeddedInShell = false,
  });

  final bool embeddedInShell;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();

  final _bloodTypes = const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final _avatars = const ['🩺', '💊', '❤️', '🧠', '🌿', '⚕️', '🏥', '🫀'];

  late String _selectedBloodType;
  late String _selectedAvatar;
  final List<String> _allergies = [];
  final List<String> _conditions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameController.text = user.name == 'User' ? '' : user.name;
    _weightController.text = user.weight > 0 ? user.weight.toString() : '';
    _heightController.text = user.height > 0 ? user.height.toString() : '';
    _selectedBloodType = user.bloodType;
    _selectedAvatar = user.avatarEmoji;
    _allergies.addAll(user.allergies);
    _conditions.addAll(user.conditions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final userProvider = context.read<UserProvider>();
    final appPrefs = context.read<AppPreferencesProvider>();

    setState(() => _isSaving = true);

    try {
      await userProvider.setAvatarEmoji(_selectedAvatar);
      await userProvider.setUserData(
        name: _nameController.text.trim().isEmpty
            ? userProvider.name
            : _nameController.text.trim(),
        allergies: _allergies,
        conditions: _conditions,
        bloodType: _selectedBloodType,
        weight: double.tryParse(_weightController.text.trim()) ?? 0,
        height: double.tryParse(_heightController.text.trim()) ?? 0,
        profileCompleted: true,
      );
      await userProvider.updatePreferences(
        localeCode: appPrefs.localeCode,
        themeMode: appPrefs.themeMode,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? context.tr('authFailed')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _addListValue(TextEditingController controller, List<String> target) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    if (target.any((item) => item.toLowerCase() == value.toLowerCase())) {
      controller.clear();
      return;
    }

    setState(() {
      target.add(value);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final content = SafeArea(
      top: !widget.embeddedInShell,
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.paddingL,
          widget.embeddedInShell
              ? AppDimensions.paddingL
              : AppDimensions.paddingL,
          AppDimensions.paddingL,
          widget.embeddedInShell
              ? AppDimensions.paddingXL
              : AppDimensions.paddingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embeddedInShell) ...[
              Text(
                context.tr('profile'),
                style: AppTextStyles.headlineLarge.copyWith(
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('completeProfileSubtitle'),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
            ],
            if (userProvider.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  userProvider.error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('completeProfileTitle'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('completeProfileSubtitle'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('profileSetupHint'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('chooseAvatar'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _avatars.map((avatar) {
                      final isSelected = avatar == _selectedAvatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = avatar),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.divider,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
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
                    context.tr('personalInformation'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('fullName'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr('weightKg'),
                            prefixIcon:
                                const Icon(Icons.fitness_center_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr('heightCm'),
                            prefixIcon: const Icon(Icons.height_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('bloodType'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bloodTypes.map((bloodType) {
                      final isSelected = bloodType == _selectedBloodType;
                      return TagChip(
                        label: bloodType,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedBloodType = isSelected ? '' : bloodType;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileListEditor(
              title: context.tr('myAllergies'),
              hint: context.tr('addAllergy'),
              controller: _allergyController,
              values: _allergies,
              onAdd: () => _addListValue(_allergyController, _allergies),
              onRemove: (value) => setState(() => _allergies.remove(value)),
            ),
            const SizedBox(height: 16),
            _ProfileListEditor(
              title: context.tr('myConditions'),
              hint: context.tr('addCondition'),
              controller: _conditionController,
              values: _conditions,
              onAdd: () => _addListValue(_conditionController, _conditions),
              onRemove: (value) => setState(() => _conditions.remove(value)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.tr('continueToApp'),
              onTap: userProvider.isLoading || _isSaving ? null : _saveProfile,
              isLoading: userProvider.isLoading || _isSaving,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );

    if (widget.embeddedInShell) {
      return ColoredBox(
        color: AppColors.background,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
    );
  }
}

class _ProfileListEditor extends StatelessWidget {
  const _ProfileListEditor({
    required this.title,
    required this.hint,
    required this.controller,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: hint,
                    prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  onFieldSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 54,
                height: 54,
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          if (values.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((value) {
                return TagChip(
                  label: value,
                  isSelected: true,
                  onRemove: () => onRemove(value),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
