import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_localizations.dart';
import 'services/providers.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  SharedPreferences? _sharedPreferences;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final sharedPreferences = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _sharedPreferences = sharedPreferences;
      });
    } on UnsupportedError {
      if (!mounted) return;

      setState(() {
        _bootstrapError =
            'This build is configured for Android and Web Firebase targets only. '
            'Please run MediGuide AI on Android or Chrome.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _bootstrapError =
            'Firebase failed to initialize. Please verify firebase_options.dart '
            'and android/app/google-services.json.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sharedPreferences != null) {
      return MediGuideApp(sharedPreferences: _sharedPreferences!);
    }

    if (_bootstrapError != null) {
      return BootstrapErrorApp(message: _bootstrapError!);
    }

    return const _BootstrapLoadingApp();
  }
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediGuide AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.authBackgroundGradient,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'MediGuide AI',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediGuide AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.authBackgroundGradient,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandBlue.withValues(alpha: 0.24),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'MediGuide AI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Starting your health workspace...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MediGuideApp extends StatefulWidget {
  const MediGuideApp({
    super.key,
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;

  @override
  State<MediGuideApp> createState() => _MediGuideAppState();
}

class _MediGuideAppState extends State<MediGuideApp> {
  late final AppPreferencesProvider _appPreferences;
  late final AuthService _authService;
  late final UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _appPreferences = AppPreferencesProvider(widget.sharedPreferences);
    _authService = AuthService();
    _userProvider = UserProvider(
      sharedPreferences: widget.sharedPreferences,
    );

    _authService.addListener(_syncUserState);
    _userProvider.addListener(_syncRemotePreferences);
    _syncUserState();
  }

  @override
  void dispose() {
    _authService.removeListener(_syncUserState);
    _userProvider.removeListener(_syncRemotePreferences);
    _authService.dispose();
    _userProvider.dispose();
    _appPreferences.dispose();
    super.dispose();
  }

  void _syncUserState() {
    unawaited(_bindUserState());
  }

  Future<void> _bindUserState() async {
    try {
      await _userProvider.bindAuthUser(_authService.currentUser);
    } catch (error, stackTrace) {
      debugPrint('Failed to bind authenticated user: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _syncRemotePreferences() {
    final profile = _userProvider.profile;
    if (profile == null) return;

    _appPreferences.applyRemotePreferences(
      localeCode: profile.preferredLocale,
      themeMode: profile.preferredTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppPreferencesProvider>.value(
          value: _appPreferences,
        ),
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
      ],
      child: Consumer<AppPreferencesProvider>(
        builder: (context, appPreferences, _) {
          return MaterialApp(
            title: 'MediGuide AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appPreferences.themeMode,
            locale: appPreferences.locale,
            supportedLocales: AppPreferencesProvider.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (_) => const AppRouter(),
            },
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userProvider = context.watch<UserProvider>();

    if (!auth.isInitialized) {
      return const _SplashScreen();
    }

    if (auth.isLoggedIn) {
      if (userProvider.isLoading) {
        return const _SplashScreen();
      }

      if (userProvider.profileCompleted) {
        return const MainShell();
      }

      if (userProvider.error != null && userProvider.profile == null) {
        return _ProfileRecoveryScreen(
          message: userProvider.error!,
        );
      }

      return const MainShell(
        initialIndex: 4,
        showProfileSetup: true,
      );
    }

    return const RootNavigator();
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final appPreferences = context.watch<AppPreferencesProvider>();

    if (!appPreferences.hasCompletedOnboarding) {
      return OnboardingScreen(
        onFinish: appPreferences.completeOnboarding,
      );
    }

    return const AuthScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.authBackgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandBlue.withValues(alpha: 0.32),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('appName'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('loadingProfile'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRecoveryScreen extends StatelessWidget {
  const _ProfileRecoveryScreen({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.authBackgroundGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 52,
                      color: AppTheme.brandBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('profile'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        userProvider.bindAuthUser(auth.currentUser);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('retry')),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: auth.signOut,
                      child: Text(context.tr('signOut')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
