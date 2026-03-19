import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _privacyLockKey = 'settings_privacy_lock_enabled';
  static const _offlineBriefsKey = 'settings_offline_briefs_enabled';

  bool _notificationsEnabled = true;
  bool _privacyLockEnabled = true;
  bool _offlineBriefsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _privacyLockEnabled = prefs.getBool(_privacyLockKey) ?? true;
      _offlineBriefsEnabled = prefs.getBool(_offlineBriefsKey) ?? false;
    });
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openOnboardingPreview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          onFinish: () async {},
          returnToRootOnFinish: false,
        ),
      ),
    );
  }

  Future<void> _resendVerification() async {
    final auth = context.read<AuthService>();
    final success = await auth.sendEmailVerification();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.tr('verificationEmailSent')
              : (auth.error ?? context.tr('authFailed')),
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthService>();
    final appPrefs = context.read<AppPreferencesProvider>();

    if (appPrefs.isDemoMode) {
      await appPrefs.exitDemoMode();
    } else {
      await auth.signOut();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.dynamicText('Signed out successfully.')),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _confirmDeleteAccount() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.dynamicText('Delete account')),
          content: Text(
            context.dynamicText(
              'This will remove your sign-in account from MediGuide AI on this device. Firebase may ask you to sign in again before deletion.',
            ),
          ),
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
              child: Text(context.tr('delete')),
            ),
          ],
        );
      },
    );

    if (approved != true || !mounted) return;

    final auth = context.read<AuthService>();
    final success = await auth.deleteCurrentAccount();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.dynamicText('Account deleted successfully.')
              : (auth.error ?? context.tr('authFailed')),
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );

    if (!success) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _activityTimeLabel(BuildContext context, String? rawValue) {
    final parsed = rawValue == null ? null : DateTime.tryParse(rawValue);
    if (parsed == null) return context.tr('now');

    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return context.dynamicText('Just now');
    if (diff.inMinutes < 60) {
      return context.tr('minutesAgo', params: {'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return context.tr('hoursAgo', params: {'count': '${diff.inHours}'});
    }
    return context.tr('daysAgo', params: {'count': '${diff.inDays}'});
  }

  @override
  Widget build(BuildContext context) {
    final appPrefs = context.watch<AppPreferencesProvider>();
    final auth = context.watch<AuthService>();
    final userProvider = context.watch<UserProvider>();
    final firebaseUser = auth.currentUser;
    final signedInEmail = firebaseUser?.email ?? userProvider.email;
    final showVerificationAction =
        firebaseUser != null && !(firebaseUser.emailVerified);
    final activities = userProvider.recentActivity.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('settings')),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              colors: const [AppTheme.brandNavy, AppTheme.brandBlue],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.dynamicText('Control your app experience'),
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
                                'Language, appearance, privacy, and quick health preferences in one place.',
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
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Appearance'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 8),
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                      child: Text(
                          context.dynamicText('Notification history'),
                          style: AppTextStyles.headlineSmall,
                        ),
                      ),
                      if (activities.isNotEmpty)
                        TextButton(
                          onPressed: userProvider.clearRecentActivity,
                          child: const Text('Clear all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (activities.isEmpty)
                    Text(
                      context.dynamicText(
                        'Important health actions and reminders will appear here.',
                      ),
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    ...activities.map((activity) {
                      final title = (activity['title'] as String? ?? '').trim();
                      final subtitle =
                          (activity['subtitle'] as String? ?? '').trim();
                      final icon = (activity['icon'] as String? ?? '🔔').trim();
                      final activityId =
                          (activity['id'] as String? ?? '').trim();

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.dynamicText(
                                        title.isEmpty ? 'Health update' : title,
                                      ),
                                      style: AppTextStyles.headlineSmall,
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        context.dynamicText(subtitle),
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      _activityTimeLabel(
                                        context,
                                        activity['createdAt'] as String?,
                                      ),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              if (activityId.isNotEmpty)
                                IconButton(
                                  onPressed: () => userProvider
                                      .removeRecentActivity(activityId),
                                  icon: const Icon(Icons.close_rounded),
                                  color: AppColors.textHint,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Smart toggles'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      _saveToggle(_notificationsKey, value);
                    },
                    title: Text(context.dynamicText('Notifications')),
                    subtitle: Text(
                      context.dynamicText(
                        'Medicine reminders and urgent health nudges',
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _privacyLockEnabled,
                    onChanged: (value) {
                      setState(() => _privacyLockEnabled = value);
                      _saveToggle(_privacyLockKey, value);
                    },
                    title: Text(context.dynamicText('Privacy lock')),
                    subtitle: Text(
                      context.dynamicText(
                        'Require an extra confirmation for sensitive changes',
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _offlineBriefsEnabled,
                    onChanged: (value) {
                      setState(() => _offlineBriefsEnabled = value);
                      _saveToggle(_offlineBriefsKey, value);
                    },
                    title: Text(context.dynamicText('Offline summaries')),
                    subtitle: Text(
                      context.dynamicText(
                        'Keep essential care notes available when the network is weak',
                      ),
                    ),
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
                    context.dynamicText('Security and account'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _SettingsInfoRow(
                    icon: Icons.verified_user_rounded,
                    title: context.dynamicText('Session mode'),
                    subtitle: appPrefs.isDemoMode
                        ? context.dynamicText('Preview mode is currently active')
                        : context.dynamicText('Signed account mode is active'),
                    accent: appPrefs.isDemoMode
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const SizedBox(height: 10),
                  _SettingsInfoRow(
                    icon: Icons.shield_outlined,
                    title: context.dynamicText('Privacy'),
                    subtitle: context.dynamicText(
                      'Health profile details stay separated from temporary preview content.',
                    ),
                    accent: AppTheme.brandBlue,
                  ),
                  if (signedInEmail.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SettingsInfoRow(
                      icon: Icons.alternate_email_rounded,
                      title: context.dynamicText('Signed in as'),
                      subtitle: signedInEmail,
                      accent: AppColors.primary,
                    ),
                  ],
                  if (showVerificationAction) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _resendVerification,
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(context.tr('resendVerification')),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          AppDimensions.buttonHeight,
                        ),
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
                    context.dynamicText('Guided actions'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.slideshow_rounded),
                    title: Text(context.dynamicText('Open onboarding')),
                    subtitle: Text(
                      context.dynamicText(
                        'Replay the welcome slides and app feature walkthrough',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _openOnboardingPreview,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(
                      appPrefs.isDemoMode
                          ? context.dynamicText('Exit preview mode')
                          : context.dynamicText('Log out'),
                    ),
                    subtitle: Text(
                      appPrefs.isDemoMode
                          ? context.dynamicText(
                              'Return to the normal sign-in flow',
                            )
                          : context.dynamicText(
                              'Sign out and return to onboarding or auth',
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: auth.isLoading ? null : _signOut,
                  ),
                ],
              ),
            ),
            if (!appPrefs.isDemoMode && firebaseUser != null) ...[
              const SizedBox(height: 16),
              AppCard(
                color: const Color(0xFFFFFBFB),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.dynamicText('Danger zone'),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.dynamicText(
                        'Use this only if you want to remove your signed-in MediGuide account from this device.',
                      ),
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _confirmDeleteAccount,
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(context.dynamicText('Delete account')),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size(
                          double.infinity,
                          AppDimensions.buttonHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
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
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      )
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
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      )
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
