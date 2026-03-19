import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignIn = true;
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode(bool signIn) {
    if (_isSignIn == signIn) return;
    _animController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _isSignIn = signIn);
      _animController.forward();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = _isSignIn
        ? await auth.signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          )
        : await auth.signUp(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? context.tr('authFailed')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!_isSignIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('verificationEmailSent')),
          backgroundColor: AppColors.success,
        ),
      );
    }

    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthService>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? context.tr('googleSignInFailed')),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final auth = context.read<AuthService>();
    final success = await auth.sendPasswordResetEmail(_emailController.text);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password reset email sent. Please check your inbox.'
              : (auth.error ?? context.tr('authFailed')),
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final authBlocked =
        auth.configurationStatus == AuthConfigurationStatus.unavailable;
    final showPreviewAccess =
        auth.configurationStatus != AuthConfigurationStatus.ready;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.authBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('appName'),
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppTheme.brandNavy,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('appTagline'),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _QuickSettingsButtons(),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXXL),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandBlue.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _AuthConfigurationBanner(auth: auth),
                if (auth.configurationStatus != AuthConfigurationStatus.ready)
                  const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  borderRadius: 28,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusL,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _AuthTabButton(
                                  label: context.tr('signIn'),
                                  isSelected: _isSignIn,
                                  onTap: () => _toggleMode(true),
                                ),
                                _AuthTabButton(
                                  label: context.tr('signUp'),
                                  isSelected: !_isSignIn,
                                  onTap: () => _toggleMode(false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isSignIn
                                ? context.tr('welcomeBack')
                                : context.tr('createAccount'),
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSignIn
                                ? context.tr('signInSubtitle')
                                : context.tr('signUpSubtitle'),
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          if (!_isSignIn) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: context.tr('fullName'),
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) {
                                if (!_isSignIn &&
                                    (value == null || value.trim().isEmpty)) {
                                  return context.tr('fullName');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: context.tr('email'),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final normalized = value?.trim() ?? '';
                              if (normalized.isEmpty) {
                                return context.tr('email');
                              }
                              if (!normalized.contains('@')) {
                                return auth.error ??
                                    context.tr('invalidEmailAddress');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: context.tr('password'),
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().length < 6) {
                                return context.tr('minimumPasswordLength');
                              }
                              return null;
                            },
                          ),
                          if (_isSignIn) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: auth.isLoading || authBlocked
                                    ? null
                                    : _sendPasswordReset,
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: _isSignIn
                                ? context.tr('signIn')
                                : context.tr('signUp'),
                            onTap: authBlocked ? null : _submit,
                            isLoading: auth.isLoading,
                            icon: _isSignIn
                                ? Icons.login_rounded
                                : Icons.person_add_alt_rounded,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  context.tr('orContinueWith'),
                                  style: AppTextStyles.caption,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: auth.isLoading || authBlocked
                                ? null
                                : _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata_rounded),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(context.tr('signInWithGoogle')),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                AppDimensions.buttonHeight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusXL,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showPreviewAccess) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    borderRadius: 28,
                    color: Colors.white.withValues(alpha: 0.92),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.visibility_rounded,
                                color: AppTheme.brandBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('previewModeTitle'),
                                    style: AppTextStyles.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('previewModeSubtitle'),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<AppPreferencesProvider>()
                              .enterDemoMode(),
                          icon: const Icon(Icons.rocket_launch_rounded),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(context.tr('continueInPreview')),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              AppDimensions.buttonHeight,
                            ),
                            foregroundColor: AppTheme.brandBlue,
                            side: BorderSide(
                              color: AppTheme.brandBlue.withValues(alpha: 0.25),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL,
                              ),
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
        ),
      ),
    );
  }
}

class _AuthConfigurationBanner extends StatelessWidget {
  const _AuthConfigurationBanner({
    required this.auth,
  });

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    if (auth.configurationStatus == AuthConfigurationStatus.ready) {
      return const SizedBox.shrink();
    }

    late final IconData icon;
    late final Color accent;
    late final String title;
    late final String subtitle;

    switch (auth.configurationStatus) {
      case AuthConfigurationStatus.checking:
        icon = Icons.sync_rounded;
        accent = AppTheme.brandBlue;
        title = context.tr('checkingFirebaseSetup');
        subtitle = context.tr('checkingFirebaseSetupSubtitle');
        break;
      case AuthConfigurationStatus.networkIssue:
        icon = Icons.wifi_off_rounded;
        accent = AppColors.warning;
        title = context.tr('firebaseSetupNetworkIssue');
        subtitle = context.tr('firebaseSetupNetworkIssueSubtitle');
        break;
      case AuthConfigurationStatus.unavailable:
        icon = Icons.warning_amber_rounded;
        accent = AppColors.danger;
        title = context.tr('firebaseSetupRequired');
        subtitle = context.tr('firebaseSetupRequiredSubtitle');
        break;
      case AuthConfigurationStatus.ready:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppTheme.brandNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (auth.configurationStatus != AuthConfigurationStatus.checking) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: auth.isLoading
                    ? null
                    : () => context
                        .read<AuthService>()
                        .refreshConfigurationStatus(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('retryConfigurationCheck')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSettingsButtons extends StatelessWidget {
  const _QuickSettingsButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickActionButton(
          icon: Icons.language_rounded,
          onTap: () => _showLanguagePicker(context),
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Icons.palette_outlined,
          onTap: () => _showThemePicker(context),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppTheme.brandNavy),
        ),
      ),
    );
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              final isSelected = appPreferences.localeCode == item.$1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.$2),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                    : null,
                onTap: () async {
                  await appPreferences.setLocale(Locale(item.$1));
                  if (context.mounted) {
                    final userProvider = context.read<UserProvider>();
                    await userProvider.updatePreferences(localeCode: item.$1);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              final isSelected = appPreferences.themeMode == item.$1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.$2),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                    : null,
                onTap: () async {
                  await appPreferences.setThemeMode(item.$1);
                  if (context.mounted) {
                    final userProvider = context.read<UserProvider>();
                    await userProvider.updatePreferences(themeMode: item.$1);
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
