import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'emergency_screen.dart';
import 'health_tracker_screen.dart';
import 'hospital_detail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();

  final _avatars = const ['🩺', '💊', '❤️', '🧠', '🌿', '⚕️', '🏥', '🫀'];
  final _bloodTypes = const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  bool _initialized = false;
  String _selectedAvatar = '🩺';
  String _selectedBloodType = '';
  final List<String> _allergies = [];
  final List<String> _conditions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _hydrate(UserProvider userProvider) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = userProvider.name == 'User' ? '' : userProvider.name;
    _weightController.text =
        userProvider.weight > 0 ? userProvider.weight.toString() : '';
    _heightController.text =
        userProvider.height > 0 ? userProvider.height.toString() : '';
    _selectedAvatar = userProvider.avatarEmoji;
    _selectedBloodType = userProvider.bloodType;
    _allergies
      ..clear()
      ..addAll(userProvider.allergies);
    _conditions
      ..clear()
      ..addAll(userProvider.conditions);
  }

  Future<void> _saveProfile() async {
    final userProvider = context.read<UserProvider>();

    await userProvider.setAvatarEmoji(_selectedAvatar);
    await userProvider.setUserData(
      name: _nameController.text.trim().isEmpty
          ? userProvider.name
          : _nameController.text.trim(),
      bloodType: _selectedBloodType,
      weight: double.tryParse(_weightController.text.trim()) ?? 0,
      height: double.tryParse(_heightController.text.trim()) ?? 0,
      allergies: _allergies,
      conditions: _conditions,
      profileCompleted: true,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('profileSaved')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _clearHealthData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('clearHealthData')),
          content: Text(context.tr('clearHealthDataSubtitle')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: Text(context.tr('confirm')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await context.read<UserProvider>().clearData();

    if (!mounted) return;

    setState(() {
      _weightController.clear();
      _heightController.clear();
      _selectedBloodType = '';
      _allergies.clear();
      _conditions.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('healthDataCleared')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _addValue(TextEditingController controller, List<String> target) {
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

  Future<void> _resendVerification() async {
    final success = await context.read<AuthService>().sendEmailVerification();
    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('verificationEmailSent')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthService>();
    final appPrefs = context.watch<AppPreferencesProvider>();
    final firebaseUser = auth.currentUser;

    _hydrate(userProvider);

    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : userProvider.name;
    final email = firebaseUser?.email ?? userProvider.email;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('profile')),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              colors: const [AppTheme.brandBlue, AppTheme.brandMint],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _selectedAvatar,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _ProfileStat(
                              label: context.tr('allergies'),
                              value: '${_allergies.length}',
                            ),
                            _ProfileStat(
                              label: context.tr('conditions'),
                              value: '${_conditions.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!(firebaseUser?.emailVerified ?? true))
              _VerificationBanner(
                email: email,
                onResend: _resendVerification,
              ),
            if (!(firebaseUser?.emailVerified ?? true))
              const SizedBox(height: 18),
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
                      return TagChip(
                        label: bloodType,
                        isSelected: bloodType == _selectedBloodType,
                        onTap: () {
                          setState(() {
                            _selectedBloodType = _selectedBloodType == bloodType
                                ? ''
                                : bloodType;
                          });
                        },
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brandBlue
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.brandNavy
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
            _ProfileListEditor(
              title: context.tr('myAllergies'),
              hint: context.tr('addAllergy'),
              emptyText: context.tr('noAllergies'),
              controller: _allergyController,
              values: _allergies,
              onAdd: () => _addValue(_allergyController, _allergies),
              onRemove: (value) => setState(() => _allergies.remove(value)),
            ),
            const SizedBox(height: 16),
            _ProfileListEditor(
              title: context.tr('myConditions'),
              hint: context.tr('addCondition'),
              emptyText: context.tr('noConditions'),
              controller: _conditionController,
              values: _conditions,
              onAdd: () => _addValue(_conditionController, _conditions),
              onRemove: (value) => setState(() => _conditions.remove(value)),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Care pages'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.monitor_heart_rounded),
                    title: Text(context.dynamicText('Health Tracker')),
                    subtitle: Text(
                      context.dynamicText(
                        'Symptoms history, previous checks, and stats',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openPage(const HealthTrackerScreen()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.emergency_rounded,
                      color: AppColors.danger,
                    ),
                    title: Text(context.dynamicText('Emergency Center')),
                    subtitle: Text(
                      context.dynamicText(
                        'Ambulance call, nearby urgent hospitals, and first actions',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openPage(const EmergencyScreen()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_rounded),
                    title: Text(context.tr('settings')),
                    subtitle: Text(
                      context.dynamicText(
                        'Language, theme, notifications, and privacy',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openPage(const SettingsScreen()),
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
                    context.tr('settings'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(context.tr('theme')),
                    subtitle: Text(_themeLabel(context, appPrefs.themeMode)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showThemePicker(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_rounded),
                    title: Text(context.tr('language')),
                    subtitle:
                        Text(_languageLabel(context, appPrefs.localeCode)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showLanguagePicker(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SavedPlacesSection(
              places: userProvider.savedPlaces,
              onRemove: userProvider.removeSavedPlace,
              onOpenPlace: (place) =>
                  _openPage(HospitalDetailScreen(place: place)),
            ),
            const SizedBox(height: 16),
            _RecentSearchesSection(
              entries: userProvider.recentSearches,
              onRemove: userProvider.removeRecentSearch,
              onClearAll: userProvider.clearRecentSearches,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.tr('saveChanges'),
              onTap: _saveProfile,
              isLoading: userProvider.isLoading,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: userProvider.isLoading ? null : _clearHealthData,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(context.tr('clearHealthData')),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize:
                    const Size(double.infinity, AppDimensions.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: appPrefs.isDemoMode
                  ? context.tr('exitPreview')
                  : context.tr('signOut'),
              onTap: appPrefs.isDemoMode
                  ? appPrefs.exitDemoMode
                  : (auth.isLoading ? null : auth.signOut),
              isLoading: appPrefs.isDemoMode ? false : auth.isLoading,
              icon: appPrefs.isDemoMode
                  ? Icons.visibility_off_rounded
                  : Icons.logout_rounded,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPlacesSection extends StatelessWidget {
  const _SavedPlacesSection({
    required this.places,
    required this.onRemove,
    required this.onOpenPlace,
  });

  final List<MedicalPlace> places;
  final Future<void> Function(String placeId) onRemove;
  final ValueChanged<MedicalPlace> onOpenPlace;

  String _distanceLabel(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('savedPlaces'),
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (places.isEmpty)
            Text(
              context.tr('noSavedPlacesSubtitle'),
              style: AppTextStyles.bodyMedium,
            )
          else
            Column(
              children: places.take(6).map((place) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onOpenPlace(place),
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.dynamicText(place.name),
                                style: AppTextStyles.headlineSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.dynamicText(place.address),
                                style: AppTextStyles.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${context.tr('distance')}: ${_distanceLabel(place.distanceMeters)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('removeSavedPlace'),
                          onPressed: () => onRemove(place.id),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _RecentSearchesSection extends StatelessWidget {
  const _RecentSearchesSection({
    required this.entries,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<SavedSearchEntry> entries;
  final Future<void> Function(String id) onRemove;
  final Future<void> Function() onClearAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('recentSearches'),
                style: AppTextStyles.headlineSmall,
              ),
              if (entries.isNotEmpty)
                TextButton(
                  onPressed: () => onClearAll(),
                  child: Text(context.tr('clearRecentSearches')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              context.tr('noRecentSearches'),
              style: AppTextStyles.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries.map((entry) {
                return TagChip(
                  label: context.dynamicText(entry.query),
                  onRemove: () => onRemove(entry.id),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({
    required this.email,
    required this.onResend,
  });

  final String email;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('emailNotVerified'),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onResend,
            icon: const Icon(Icons.send_rounded),
            label: Text(context.tr('resendVerification')),
          ),
        ],
      ),
    );
  }
}

class _ProfileListEditor extends StatelessWidget {
  const _ProfileListEditor({
    required this.title,
    required this.hint,
    required this.emptyText,
    required this.controller,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String hint;
  final String emptyText;
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
          const SizedBox(height: 12),
          if (values.isEmpty)
            Text(emptyText, style: AppTextStyles.bodyMedium)
          else
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
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

String _languageLabel(BuildContext context, String localeCode) {
  switch (localeCode) {
    case 'ru':
      return context.tr('russian');
    case 'kk':
      return context.tr('kazakh');
    case 'tr':
      return context.tr('turkish');
    default:
      return context.tr('english');
  }
}

String _themeLabel(BuildContext context, ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.light:
      return context.tr('light');
    case ThemeMode.dark:
      return context.tr('dark');
    case ThemeMode.system:
      return context.tr('system');
  }
}

void _showLanguagePicker(BuildContext context) {
  final appPreferences = context.read<AppPreferencesProvider>();

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final items = [
        ('en', context.tr('english')),
        ('ru', context.tr('russian')),
        ('kk', context.tr('kazakh')),
        ('tr', context.tr('turkish')),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              return ListTile(
                title: Text(item.$2),
                trailing: appPreferences.localeCode == item.$1
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                    : null,
                onTap: () async {
                  await appPreferences.setLocale(Locale(item.$1));
                  if (context.mounted) {
                    await context
                        .read<UserProvider>()
                        .updatePreferences(localeCode: item.$1);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}

void _showThemePicker(BuildContext context) {
  final appPreferences = context.read<AppPreferencesProvider>();

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final items = [
        (ThemeMode.light, context.tr('light')),
        (ThemeMode.dark, context.tr('dark')),
        (ThemeMode.system, context.tr('system')),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              return ListTile(
                title: Text(item.$2),
                trailing: appPreferences.themeMode == item.$1
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                    : null,
                onTap: () async {
                  await appPreferences.setThemeMode(item.$1);
                  if (context.mounted) {
                    await context
                        .read<UserProvider>()
                        .updatePreferences(themeMode: item.$1);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}
