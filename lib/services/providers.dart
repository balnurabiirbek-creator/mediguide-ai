import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/models.dart';

class AppPreferencesProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _localeCodeKey = 'locale_code';
  static const _onboardingKey = 'onboarding_complete';
  static const _demoModeKey = 'demo_mode_enabled';

  final SharedPreferences _prefs;

  AppPreferencesProvider(this._prefs)
      : _themeMode = _themeModeFromStorage(
          _prefs.getString(_themeModeKey) ?? 'system',
        ),
        _locale = Locale(_prefs.getString(_localeCodeKey) ?? 'en'),
        _hasCompletedOnboarding = _prefs.getBool(_onboardingKey) ?? false,
        _isDemoMode = _prefs.getBool(_demoModeKey) ?? false;

  ThemeMode _themeMode;
  Locale _locale;
  bool _hasCompletedOnboarding;
  bool _isDemoMode;

  static const supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('kk'),
    Locale('tr'),
  ];

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get localeCode => _locale.languageCode;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isDemoMode => _isDemoMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs.setString(_themeModeKey, _themeModeToStorage(mode));
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;

    _locale = Locale(locale.languageCode);
    await _prefs.setString(_localeCodeKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> applyRemotePreferences({
    String? localeCode,
    String? themeMode,
  }) async {
    var changed = false;

    if (localeCode != null &&
        localeCode.isNotEmpty &&
        localeCode != _locale.languageCode) {
      _locale = Locale(localeCode);
      await _prefs.setString(_localeCodeKey, localeCode);
      changed = true;
    }

    if (themeMode != null) {
      final nextThemeMode = _themeModeFromStorage(themeMode);
      if (_themeMode != nextThemeMode) {
        _themeMode = nextThemeMode;
        await _prefs.setString(_themeModeKey, _themeModeToStorage(_themeMode));
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    if (_hasCompletedOnboarding) return;

    _hasCompletedOnboarding = true;
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> enterDemoMode() async {
    if (_isDemoMode) return;

    _isDemoMode = true;
    await _prefs.setBool(_demoModeKey, true);
    notifyListeners();
  }

  Future<void> exitDemoMode() async {
    if (!_isDemoMode) return;

    _isDemoMode = false;
    await _prefs.setBool(_demoModeKey, false);
    notifyListeners();
  }

  static ThemeMode _themeModeFromStorage(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

enum AuthConfigurationStatus {
  checking,
  ready,
  unavailable,
  networkIssue,
}

enum _AuthAction {
  signIn,
  signUp,
  googleSignIn,
  verifyEmail,
  resetPassword,
  deleteAccount,
}

class AuthService extends ChangeNotifier {
  AuthService({
    fb_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']) {
    _subscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      _isInitialized = true;
      notifyListeners();
    });
    _configurationCheck = _probeConfiguration();
  }

  final fb_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  StreamSubscription<fb_auth.User?>? _subscription;
  Future<void>? _configurationCheck;
  fb_auth.User? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  AuthConfigurationStatus _configurationStatus =
      AuthConfigurationStatus.checking;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  fb_auth.User? get currentUser => _currentUser;
  AuthConfigurationStatus get configurationStatus => _configurationStatus;
  bool get isAuthConfigured =>
      _configurationStatus == AuthConfigurationStatus.ready;

  Future<bool> signIn(String email, String password) async {
    return _runAuthAction(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await refreshCurrentUser();
      return true;
    }, action: _AuthAction.signIn);
  }

  Future<bool> signUp(String name, String email, String password) async {
    return _runAuthAction(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final createdUser = credential.user;
      if (createdUser != null) {
        await createdUser.updateDisplayName(name.trim());
        if (!createdUser.emailVerified) {
          await createdUser.sendEmailVerification();
        }
      }

      await refreshCurrentUser();
      return true;
    }, action: _AuthAction.signUp);
  }

  Future<bool> signInWithGoogle() async {
    return _runAuthAction(() async {
      if (kIsWeb) {
        final provider = fb_auth.GoogleAuthProvider();
        await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _error = 'Google sign-in was cancelled.';
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final credential = fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }

      await refreshCurrentUser();
      return true;
    }, action: _AuthAction.googleSignIn);
  }

  Future<bool> sendEmailVerification() async {
    return _runAuthAction(() async {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'No signed-in user found.';
        return false;
      }

      await user.sendEmailVerification();
      return true;
    }, action: _AuthAction.verifyEmail);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return _runAuthAction(() async {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        _error = 'Enter your email address first.';
        return false;
      }

      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return true;
    }, action: _AuthAction.resetPassword);
  }

  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }

    _currentUser = _auth.currentUser;
    notifyListeners();
  }

  Future<void> refreshConfigurationStatus() async {
    _configurationCheck = _probeConfiguration(force: true);
    await _configurationCheck;
  }

  Future<void> signOut() async {
    _setLoading(true);
    _error = null;

    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (error) {
      _error = 'Failed to sign out. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCurrentAccount() async {
    return _runAuthAction(() async {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'No signed-in user found.';
        return false;
      }

      if (!kIsWeb) {
        try {
          await _googleSignIn.disconnect();
        } catch (_) {
          await _googleSignIn.signOut();
        }
      }

      await user.delete();
      _currentUser = _auth.currentUser;
      notifyListeners();
      return true;
    }, action: _AuthAction.deleteAccount);
  }

  Future<bool> _runAuthAction(
    Future<bool> Function() operation, {
    required _AuthAction action,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await (_configurationCheck ?? Future<void>.value());

      if (_configurationStatus == AuthConfigurationStatus.unavailable) {
        _error = _configurationMessageFor(action);
        return false;
      }

      return await operation();
    } on fb_auth.FirebaseAuthException catch (error) {
      _error = _mapAuthError(error);
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _probeConfiguration({bool force = false}) async {
    if (!force && _configurationStatus == AuthConfigurationStatus.ready) {
      return;
    }

    _configurationStatus = AuthConfigurationStatus.checking;
    notifyListeners();

    final apiKey = _resolveCurrentApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _configurationStatus = AuthConfigurationStatus.unavailable;
      notifyListeners();
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$apiKey',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
              const {
                'identifier': 'healthcheck@mediguide.app',
                'continueUri': 'https://mediguide.app',
              },
            ),
          )
          .timeout(const Duration(seconds: 8));

      final payload = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final errorPayload = payload['error'];
      final errorMessage = errorPayload is Map<String, dynamic>
          ? (errorPayload['message']?.toString() ?? '')
          : '';

      if (errorMessage.toUpperCase() == 'CONFIGURATION_NOT_FOUND') {
        _configurationStatus = AuthConfigurationStatus.unavailable;
      } else {
        _configurationStatus = AuthConfigurationStatus.ready;
      }
    } on TimeoutException {
      _configurationStatus = AuthConfigurationStatus.networkIssue;
    } on http.ClientException {
      _configurationStatus = AuthConfigurationStatus.networkIssue;
    } catch (_) {
      _configurationStatus = AuthConfigurationStatus.networkIssue;
    }

    notifyListeners();
  }

  String? _resolveCurrentApiKey() {
    try {
      return DefaultFirebaseOptions.currentPlatform.apiKey;
    } catch (_) {
      return null;
    }
  }

  String _configurationMessageFor(_AuthAction action) {
    switch (action) {
      case _AuthAction.googleSignIn:
        return 'Google Sign-In is not configured for this Firebase project yet. '
            'Enable Firebase Authentication, turn on Google as a provider, add '
            'Android SHA-1/SHA-256, and download the updated google-services.json.';
      case _AuthAction.verifyEmail:
        return 'Verification email cannot be sent yet because Firebase Authentication '
            'is not configured for this project.';
      case _AuthAction.resetPassword:
        return 'Password reset emails are unavailable until Firebase Authentication '
            'is configured for this project.';
      case _AuthAction.deleteAccount:
        return 'Account deletion is unavailable until Firebase Authentication '
            'is configured for this project.';
      case _AuthAction.signIn:
      case _AuthAction.signUp:
        return 'Firebase Authentication is not configured for this project yet. '
            'Enable Firebase Authentication and Email/Password in Firebase Console.';
    }
  }

  String _mapAuthError(fb_auth.FirebaseAuthException error) {
    final message = (error.message ?? '').toUpperCase();
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is disabled in Firebase Authentication.';
      case 'requires-recent-login':
        return 'Please sign in again before deleting your account.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        if (error.code == 'configuration-not-found' ||
            message.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase Authentication is not configured for this project yet. '
              'Please finish Firebase Auth setup and update google-services.json.';
        }
        return error.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class UserProvider extends ChangeNotifier {
  UserProvider({
    FirebaseFirestore? firestore,
    SharedPreferences? sharedPreferences,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sharedPreferences = sharedPreferences;

  static const _demoUserId = 'preview-user';
  static const _demoProfileKey = 'demo_profile';
  static const _demoSavedPlacesKey = 'demo_saved_places';
  static const _demoRecentSearchesKey = 'demo_recent_searches';
  static const _savedMedicineIdsPrefix = 'saved_medicine_ids';

  final FirebaseFirestore _firestore;
  final SharedPreferences? _sharedPreferences;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _savedPlacesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _recentSearchesSubscription;
  AppUserProfile? _profile;
  String? _activeUserId;
  bool _isLoading = false;
  String? _error;
  List<MedicalPlace> _savedPlaces = [];
  List<SavedSearchEntry> _recentSearches = [];
  List<String> _savedMedicineIds = [];
  int _bindGeneration = 0;
  Timer? _profileLoadTimeout;
  bool _isDemoMode = false;

  AppUserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isReady => _activeUserId == null || !_isLoading;
  String? get error => _error;
  bool get isDemoMode => _isDemoMode;

  String get uid => _profile?.uid ?? _activeUserId ?? '';
  String get name => _profile?.name ?? 'User';
  String get email => _profile?.email ?? '';
  String get avatarEmoji => _profile?.avatarEmoji ?? '🩺';
  List<String> get allergies =>
      List.unmodifiable(_profile?.allergies ?? const []);
  List<String> get conditions =>
      List.unmodifiable(_profile?.conditions ?? const []);
  String get bloodType => _profile?.bloodType ?? '';
  double get weight => _profile?.weight ?? 0;
  double get height => _profile?.height ?? 0;
  bool get profileCompleted => _profile?.profileCompleted ?? false;
  bool get emailVerified => _profile?.emailVerified ?? false;
  String get preferredLocale => _profile?.preferredLocale ?? 'en';
  String get preferredTheme => _profile?.preferredTheme ?? 'system';
  List<MedicalPlace> get savedPlaces => List.unmodifiable(_savedPlaces);
  List<SavedSearchEntry> get recentSearches =>
      List.unmodifiable(_recentSearches);
  List<String> get savedMedicineIds => List.unmodifiable(_savedMedicineIds);
  bool isPlaceSaved(String placeId) =>
      _savedPlaces.any((place) => place.id == placeId);
  bool isMedicineSaved(String medicineId) =>
      _savedMedicineIds.contains(medicineId);
  List<Map<String, dynamic>> get recentActivity => List.unmodifiable(
        (_profile?.recentActivity ?? const []).map(
          Map<String, dynamic>.unmodifiable,
        ),
      );

  Future<void> bindAuthUser(fb_auth.User? authUser) async {
    _isDemoMode = false;

    if (_activeUserId == authUser?.uid && _profileSubscription != null) {
      await _syncAuthMetadata(authUser);
      return;
    }

    final bindId = ++_bindGeneration;

    await _profileSubscription?.cancel();
    await _savedPlacesSubscription?.cancel();
    await _recentSearchesSubscription?.cancel();
    _profileLoadTimeout?.cancel();
    _profileSubscription = null;
    _savedPlacesSubscription = null;
    _recentSearchesSubscription = null;
    _error = null;

    if (authUser == null) {
      _activeUserId = null;
      _profile = null;
      _savedPlaces = [];
      _recentSearches = [];
      _savedMedicineIds = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _activeUserId = authUser.uid;
    _profile = null;
    _savedMedicineIds = _loadSavedMedicineIds(authUser.uid);
    _isLoading = true;
    notifyListeners();

    final docRef = _firestore.collection('users').doc(authUser.uid);
    _bindSavedPlaces(authUser.uid);
    _bindRecentSearches(authUser.uid);

    _profileLoadTimeout = Timer(const Duration(seconds: 8), () {
      if (bindId != _bindGeneration || !_isLoading) return;
      _profile = _fallbackProfileForAuthUser(authUser);
      _isLoading = false;
      _error = 'Profile loading took too long. Opening setup with basic data.';
      notifyListeners();
    });

    _profileSubscription = docRef.snapshots().listen(
      (profileSnapshot) {
        if (bindId != _bindGeneration) return;

        final data = profileSnapshot.data();
        _profile = data != null
            ? AppUserProfile.fromMap(authUser.uid, data)
            : _fallbackProfileForAuthUser(authUser);
        _isLoading = false;
        _error = null;
        _profileLoadTimeout?.cancel();
        notifyListeners();
      },
      onError: (error) {
        if (bindId != _bindGeneration) return;

        _profile = _fallbackProfileForAuthUser(authUser);
        _isLoading = false;
        _error = _mapFirestoreError(
          error,
          fallback: 'Failed to load your profile from Firestore.',
        );
        _profileLoadTimeout?.cancel();
        notifyListeners();
      },
    );

    try {
      final snapshot = await docRef.get().timeout(const Duration(seconds: 6));
      if (bindId != _bindGeneration) return;

      if (!snapshot.exists) {
        _profile = _fallbackProfileForAuthUser(authUser);
        _isLoading = false;
        _error = null;
        _profileLoadTimeout?.cancel();
        notifyListeners();
        await docRef.set(_buildUserDocument(authUser), SetOptions(merge: true));
      } else {
        _profile = AppUserProfile.fromMap(authUser.uid, snapshot.data()!);
        _isLoading = false;
        _error = null;
        _profileLoadTimeout?.cancel();
        notifyListeners();
        await _syncAuthMetadata(authUser);
      }
    } catch (error) {
      if (bindId != _bindGeneration) return;

      _profile ??= _fallbackProfileForAuthUser(authUser);
      _isLoading = false;
      _error ??= _mapFirestoreError(
        error,
        fallback: 'Failed to initialize your profile.',
      );
      _profileLoadTimeout?.cancel();
      notifyListeners();
    }
  }

  Future<void> bindDemoUser() async {
    ++_bindGeneration;

    await _profileSubscription?.cancel();
    await _savedPlacesSubscription?.cancel();
    await _recentSearchesSubscription?.cancel();
    _profileLoadTimeout?.cancel();
    _profileSubscription = null;
    _savedPlacesSubscription = null;
    _recentSearchesSubscription = null;
    _error = null;

    _activeUserId = _demoUserId;
    _isDemoMode = true;
    _isLoading = true;
    notifyListeners();

    _profile = _loadDemoProfile();
    _savedPlaces = _loadDemoSavedPlaces();
    _recentSearches = _loadDemoRecentSearches();
    _savedMedicineIds = _loadSavedMedicineIds(_demoUserId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUserData({
    String? name,
    String? email,
    List<String>? allergies,
    List<String>? conditions,
    String? bloodType,
    double? weight,
    double? height,
    bool? profileCompleted,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) payload['name'] = name.trim();
    if (email != null) payload['email'] = email.trim().toLowerCase();
    if (allergies != null) {
      payload['allergies'] = allergies
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (conditions != null) {
      payload['conditions'] = conditions
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (bloodType != null) payload['bloodType'] = bloodType;
    if (weight != null) payload['weight'] = weight;
    if (height != null) payload['height'] = height;
    if (profileCompleted != null) {
      payload['profileCompleted'] = profileCompleted;
    }

    await _mergeProfile(payload);
  }

  Future<void> setAvatarEmoji(String avatarEmoji) async {
    await _mergeProfile({
      'avatarEmoji': avatarEmoji,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePreferences({
    String? localeCode,
    ThemeMode? themeMode,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (localeCode != null) {
      payload['preferredLocale'] = localeCode;
    }
    if (themeMode != null) {
      payload['preferredTheme'] = _themeModeToStorage(themeMode);
    }

    await _mergeProfile(payload);
  }

  Future<void> addAllergy(String allergy) async {
    final normalized = allergy.trim();
    if (normalized.isEmpty) return;
    if (allergies
        .any((item) => item.toLowerCase() == normalized.toLowerCase())) {
      return;
    }

    await _mergeProfile({
      'allergies': [...allergies, normalized],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAllergy(String allergy) async {
    await _mergeProfile({
      'allergies': allergies.where((item) => item != allergy).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addCondition(String condition) async {
    final normalized = condition.trim();
    if (normalized.isEmpty) return;
    if (conditions
        .any((item) => item.toLowerCase() == normalized.toLowerCase())) {
      return;
    }

    await _mergeProfile({
      'conditions': [...conditions, normalized],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCondition(String condition) async {
    await _mergeProfile({
      'conditions': conditions.where((item) => item != condition).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addRecentActivity(Map<String, dynamic> activity) async {
    final updatedActivities = [
      {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        ...activity,
      },
      ...recentActivity,
    ].take(12).toList();

    await _mergeProfile({
      'recentActivity': updatedActivities,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeRecentActivity(String id) async {
    await _mergeProfile({
      'recentActivity':
          recentActivity.where((activity) => activity['id'] != id).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearRecentActivity() async {
    await _mergeProfile({
      'recentActivity': <Map<String, dynamic>>[],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearData() async {
    if (_activeUserId == null) return;

    if (_isDemoMode) {
      _applyLocalProfilePatch({
        'allergies': <String>[],
        'conditions': <String>[],
        'recentActivity': <Map<String, dynamic>>[],
        'bloodType': '',
        'weight': 0,
        'height': 0,
      });
      await _persistDemoProfile();
      return;
    }

    await _firestore.collection('users').doc(_activeUserId).set(
      {
        'allergies': <String>[],
        'conditions': <String>[],
        'recentActivity': <Map<String, dynamic>>[],
        'bloodType': '',
        'weight': 0,
        'height': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> upsertSavedPlace(MedicalPlace place) async {
    if (_activeUserId == null || place.id.isEmpty) return;

    if (_isDemoMode) {
      _savedPlaces = [
        place,
        ..._savedPlaces.where((entry) => entry.id != place.id),
      ];
      await _persistDemoSavedPlaces();
      notifyListeners();
      return;
    }

    await _savedPlacesCollection(_activeUserId!).doc(place.id).set(
      {
        ...place.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeSavedPlace(String placeId) async {
    if (_activeUserId == null || placeId.isEmpty) return;

    if (_isDemoMode) {
      _savedPlaces =
          _savedPlaces.where((place) => place.id != placeId).toList();
      await _persistDemoSavedPlaces();
      notifyListeners();
      return;
    }

    await _savedPlacesCollection(_activeUserId!).doc(placeId).delete();
  }

  Future<void> saveRecentSearch({
    required String query,
    required String category,
  }) async {
    if (_activeUserId == null) return;

    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;

    final docId = _recentSearchId(normalizedQuery, category);

    if (_isDemoMode) {
      final nextEntry = SavedSearchEntry(
        id: docId,
        query: normalizedQuery,
        category: category,
        updatedAt: DateTime.now(),
      );
      _recentSearches = [
        nextEntry,
        ..._recentSearches.where((entry) => entry.id != docId),
      ].take(12).toList();
      await _persistDemoRecentSearches();
      notifyListeners();
      return;
    }

    await _recentSearchesCollection(_activeUserId!).doc(docId).set(
      {
        'query': normalizedQuery,
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeRecentSearch(String id) async {
    if (_activeUserId == null || id.isEmpty) return;

    if (_isDemoMode) {
      _recentSearches =
          _recentSearches.where((entry) => entry.id != id).toList();
      await _persistDemoRecentSearches();
      notifyListeners();
      return;
    }

    await _recentSearchesCollection(_activeUserId!).doc(id).delete();
  }

  Future<void> clearRecentSearches() async {
    if (_activeUserId == null) return;

    if (_isDemoMode) {
      _recentSearches = [];
      await _persistDemoRecentSearches();
      notifyListeners();
      return;
    }

    final snapshot = await _recentSearchesCollection(_activeUserId!).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> saveMedicine(String medicineId) async {
    final normalizedId = medicineId.trim();
    if (normalizedId.isEmpty) return;

    _savedMedicineIds = [
      normalizedId,
      ..._savedMedicineIds.where((id) => id != normalizedId),
    ];
    await _persistSavedMedicineIds();
    notifyListeners();
  }

  Future<void> removeSavedMedicine(String medicineId) async {
    final normalizedId = medicineId.trim();
    if (normalizedId.isEmpty) return;

    _savedMedicineIds =
        _savedMedicineIds.where((id) => id != normalizedId).toList();
    await _persistSavedMedicineIds();
    notifyListeners();
  }

  Future<void> toggleSavedMedicine(String medicineId) async {
    if (isMedicineSaved(medicineId)) {
      await removeSavedMedicine(medicineId);
      return;
    }

    await saveMedicine(medicineId);
  }

  Future<void> _mergeProfile(Map<String, dynamic> payload) async {
    if (_activeUserId == null) return;

    final localPatch = _sanitizeProfilePayload(payload);

    if (_isDemoMode) {
      _applyLocalProfilePatch(localPatch);
      _error = null;
      await _persistDemoProfile();
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_activeUserId)
          .set(payload, SetOptions(merge: true));
      _applyLocalProfilePatch(localPatch);
      _error = null;
    } catch (error) {
      _error = _mapFirestoreError(
        error,
        fallback: 'Failed to save your profile changes.',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _syncAuthMetadata(fb_auth.User? authUser) async {
    if (authUser == null) return;

    final localPatch = <String, dynamic>{
      'uid': authUser.uid,
      'email': authUser.email?.trim().toLowerCase() ?? '',
      'name': _resolveDisplayName(authUser),
      'emailVerified': authUser.emailVerified,
    };

    try {
      await _firestore.collection('users').doc(authUser.uid).set(
        {
          ...localPatch,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _applyLocalProfilePatch(localPatch);
      _error = null;
    } catch (error) {
      _error = _mapFirestoreError(
        error,
        fallback: 'Failed to sync your account profile.',
      );
      notifyListeners();
      rethrow;
    }
  }

  static String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  List<Map<String, dynamic>> get healthTips => [
        {
          'id': '1',
          'title': 'Stay Hydrated',
          'content':
              'Drink at least 8 glasses of water daily to maintain optimal body function.',
          'icon': '💧',
          'color': '0xFF4A90E2',
          'category': 'Lifestyle',
        },
        {
          'id': '2',
          'title': 'Move More',
          'content':
              '30 minutes of moderate exercise daily can reduce cardiovascular disease risk by 35%.',
          'icon': '🏃',
          'color': '0xFF22C55E',
          'category': 'Exercise',
        },
        {
          'id': '3',
          'title': 'Quality Sleep',
          'content':
              'Adults need 7-9 hours of sleep. Poor sleep is linked to diabetes, obesity, and heart disease.',
          'icon': '😴',
          'color': '0xFF7B5EA7',
          'category': 'Sleep',
        },
        {
          'id': '4',
          'title': 'Eat the Rainbow',
          'content':
              'Include colorful fruits and vegetables in your diet for diverse nutrients and antioxidants.',
          'icon': '🥗',
          'color': '0xFFF59E0B',
          'category': 'Nutrition',
        },
        {
          'id': '5',
          'title': 'Manage Stress',
          'content':
              'Chronic stress weakens immunity. Try meditation, yoga, or deep breathing for 10 minutes daily.',
          'icon': '🧘',
          'color': '0xFF5EEAD4',
          'category': 'Mental Health',
        },
        {
          'id': '6',
          'title': 'Regular Checkups',
          'content':
              'Annual health screenings can detect issues early. Prevention is always better than treatment.',
          'icon': '🏥',
          'color': '0xFFEF4444',
          'category': 'Prevention',
        },
      ];

  void _bindSavedPlaces(String userId) {
    _savedPlacesSubscription?.cancel();
    _savedPlacesSubscription = _savedPlacesCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _savedPlaces = snapshot.docs
            .map((doc) => MedicalPlace.fromFirestore(doc.data()))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _savedPlaces = [];
        _error ??= _mapFirestoreError(
          error,
          fallback: 'Failed to load your saved places.',
        );
        notifyListeners();
      },
    );
  }

  void _bindRecentSearches(String userId) {
    _recentSearchesSubscription?.cancel();
    _recentSearchesSubscription = _recentSearchesCollection(userId)
        .orderBy('updatedAt', descending: true)
        .limit(12)
        .snapshots()
        .listen(
      (snapshot) {
        _recentSearches = snapshot.docs
            .map((doc) => SavedSearchEntry.fromFirestore(doc.id, doc.data()))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _recentSearches = [];
        _error ??= _mapFirestoreError(
          error,
          fallback: 'Failed to load your recent searches.',
        );
        notifyListeners();
      },
    );
  }

  CollectionReference<Map<String, dynamic>> _savedPlacesCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_places');
  }

  CollectionReference<Map<String, dynamic>> _recentSearchesCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recent_searches');
  }

  String _recentSearchId(String query, String category) {
    final runes = query.trim().toLowerCase().runes.join('-');
    return '${category.trim().toLowerCase()}_$runes';
  }

  AppUserProfile _fallbackProfileForAuthUser(fb_auth.User authUser) {
    return AppUserProfile.fromMap(
      authUser.uid,
      _buildUserDocument(authUser),
    );
  }

  AppUserProfile _loadDemoProfile() {
    final rawValue = _sharedPreferences?.getString(_demoProfileKey);
    if (rawValue != null && rawValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
        return AppUserProfile.fromMap(_demoUserId, decoded);
      } catch (_) {}
    }

    return AppUserProfile.fromMap(_demoUserId, _defaultDemoProfileData());
  }

  List<MedicalPlace> _loadDemoSavedPlaces() {
    final rawValue = _sharedPreferences?.getString(_demoSavedPlacesKey);
    if (rawValue != null && rawValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawValue) as List<dynamic>;
        return decoded
            .whereType<Map>()
            .map(
              (item) => MedicalPlace.fromFirestore(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } catch (_) {}
    }

    return _defaultDemoSavedPlaces();
  }

  List<SavedSearchEntry> _loadDemoRecentSearches() {
    final rawValue = _sharedPreferences?.getString(_demoRecentSearchesKey);
    if (rawValue != null && rawValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawValue) as List<dynamic>;
        return decoded.whereType<Map>().map((item) {
          final map = Map<String, dynamic>.from(item);
          return SavedSearchEntry.fromFirestore(
            (map['id'] as String? ?? '').trim(),
            map,
          );
        }).toList();
      } catch (_) {}
    }

    return _defaultDemoRecentSearches();
  }

  List<String> _loadSavedMedicineIds(String userId) {
    final rawValue =
        _sharedPreferences?.getStringList(_savedMedicineIdsStorageKey(userId));
    if (rawValue == null) return [];

    return rawValue
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _persistDemoProfile() async {
    final profile = _profile;
    if (profile == null) return;

    await _sharedPreferences?.setString(
      _demoProfileKey,
      jsonEncode(_profileToMap(profile)),
    );
  }

  Future<void> _persistDemoSavedPlaces() async {
    await _sharedPreferences?.setString(
      _demoSavedPlacesKey,
      jsonEncode(
        _savedPlaces.map((place) => place.toFirestore()).toList(),
      ),
    );
  }

  Future<void> _persistDemoRecentSearches() async {
    await _sharedPreferences?.setString(
      _demoRecentSearchesKey,
      jsonEncode(
        _recentSearches
            .map(
              (entry) => {
                'id': entry.id,
                ...entry.toFirestore(),
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> _persistSavedMedicineIds() async {
    final userId = _activeUserId;
    if (userId == null) return;

    await _sharedPreferences?.setStringList(
      _savedMedicineIdsStorageKey(userId),
      _savedMedicineIds,
    );
  }

  String _savedMedicineIdsStorageKey(String userId) {
    return '${_savedMedicineIdsPrefix}_$userId';
  }

  Map<String, dynamic> _defaultDemoProfileData() {
    final now = DateTime.now();
    return {
      'uid': _demoUserId,
      'name': 'Aibirbek Balnur',
      'email': 'preview@mediguide.ai',
      'avatarEmoji': '❤️',
      'allergies': ['Penicillin', 'Peanuts'],
      'conditions': ['Seasonal asthma', 'Vitamin D deficiency'],
      'bloodType': 'O+',
      'weight': 68,
      'height': 172,
      'recentActivity': [
        {
          'id': 'preview_activity_1',
          'createdAt':
              now.subtract(const Duration(minutes: 18)).toIso8601String(),
          'title': 'Nearby clinic opened',
          'subtitle': 'Preview map loaded with saved medical places',
          'icon': '🗺️',
        },
        {
          'id': 'preview_activity_2',
          'createdAt': now.subtract(const Duration(hours: 3)).toIso8601String(),
          'title': 'Profile refreshed',
          'subtitle': 'Card layout restored with local sample data',
          'icon': '✨',
        },
      ],
      'profileCompleted': true,
      'emailVerified': true,
      'preferredLocale': 'kk',
      'preferredTheme': 'system',
    };
  }

  List<MedicalPlace> _defaultDemoSavedPlaces() {
    return const [
      MedicalPlace(
        id: 'preview_hospital_1',
        name: 'Central City Hospital',
        address: 'Dostyk Ave 210, Almaty',
        location: LatLng(43.2384, 76.9458),
        category: MedicalPlaceCategory.hospital,
        types: ['hospital', 'health'],
        rating: 4.8,
        userRatingCount: 420,
        openNow: true,
        phoneNumber: '+7 727 000 0001',
        websiteUri: 'https://mediguide.app/preview-hospital',
        distanceMeters: 1800,
        businessStatus: 'OPERATIONAL',
      ),
      MedicalPlace(
        id: 'preview_clinic_1',
        name: 'Sunrise Family Clinic',
        address: 'Satpayev St 54, Almaty',
        location: LatLng(43.2407, 76.9092),
        category: MedicalPlaceCategory.clinic,
        types: ['clinic', 'doctor'],
        rating: 4.6,
        userRatingCount: 184,
        openNow: true,
        phoneNumber: '+7 727 000 0002',
        websiteUri: 'https://mediguide.app/preview-clinic',
        distanceMeters: 950,
        businessStatus: 'OPERATIONAL',
      ),
    ];
  }

  List<SavedSearchEntry> _defaultDemoRecentSearches() {
    final now = DateTime.now();
    return [
      SavedSearchEntry(
        id: _recentSearchId(
            'nearby hospitals', MedicalPlaceCategory.hospital.name),
        query: 'nearby hospitals',
        category: MedicalPlaceCategory.hospital.name,
        updatedAt: now.subtract(const Duration(minutes: 35)),
      ),
      SavedSearchEntry(
        id: _recentSearchId(
            'nearby pharmacies', MedicalPlaceCategory.pharmacy.name),
        query: 'nearby pharmacies',
        category: MedicalPlaceCategory.pharmacy.name,
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  Map<String, dynamic> _sanitizeProfilePayload(Map<String, dynamic> payload) {
    final sanitized = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (entry.value is! FieldValue) {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  void _applyLocalProfilePatch(Map<String, dynamic> patch) {
    if (_activeUserId == null || patch.isEmpty) return;

    final baseProfile = _profile != null
        ? _profileToMap(_profile!)
        : <String, dynamic>{
            'uid': _activeUserId,
            'name': name == 'User' ? '' : name,
            'email': email,
            'avatarEmoji': avatarEmoji,
            'allergies': allergies,
            'conditions': conditions,
            'bloodType': bloodType,
            'weight': weight,
            'height': height,
            'recentActivity': recentActivity,
            'profileCompleted': profileCompleted,
            'emailVerified': emailVerified,
            'preferredLocale': preferredLocale,
            'preferredTheme': preferredTheme,
          };

    baseProfile.addAll(patch);
    _profile = AppUserProfile.fromMap(_activeUserId!, baseProfile);
    notifyListeners();
  }

  String _mapFirestoreError(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString();
    if (message.contains('database (default) does not exist for project')) {
      return 'Cloud Firestore is not created for this Firebase project yet. '
          'Create the default Firestore database in Firebase Console, then reopen the app.';
    }
    return fallback;
  }

  @override
  void dispose() {
    _profileLoadTimeout?.cancel();
    _profileSubscription?.cancel();
    _savedPlacesSubscription?.cancel();
    _recentSearchesSubscription?.cancel();
    super.dispose();
  }
}

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarEmoji,
    required this.allergies,
    required this.conditions,
    required this.bloodType,
    required this.weight,
    required this.height,
    required this.recentActivity,
    required this.profileCompleted,
    required this.emailVerified,
    required this.preferredLocale,
    required this.preferredTheme,
  });

  final String uid;
  final String name;
  final String email;
  final String avatarEmoji;
  final List<String> allergies;
  final List<String> conditions;
  final String bloodType;
  final double weight;
  final double height;
  final List<Map<String, dynamic>> recentActivity;
  final bool profileCompleted;
  final bool emailVerified;
  final String preferredLocale;
  final String preferredTheme;

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserProfile(
      uid: uid,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : 'User',
      email: (map['email'] as String? ?? '').trim(),
      avatarEmoji: (map['avatarEmoji'] as String? ?? '🩺').trim(),
      allergies: List<String>.from(map['allergies'] as List? ?? const []),
      conditions: List<String>.from(map['conditions'] as List? ?? const []),
      bloodType: (map['bloodType'] as String? ?? '').trim(),
      weight: _parseDouble(map['weight']),
      height: _parseDouble(map['height']),
      recentActivity: (map['recentActivity'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      emailVerified: map['emailVerified'] as bool? ?? false,
      preferredLocale: (map['preferredLocale'] as String? ?? 'en').trim(),
      preferredTheme: (map['preferredTheme'] as String? ?? 'system').trim(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

Map<String, dynamic> _buildUserDocument(fb_auth.User authUser) {
  return {
    'uid': authUser.uid,
    'email': authUser.email?.trim().toLowerCase() ?? '',
    'name': _resolveDisplayName(authUser),
    'avatarEmoji': '🩺',
    'allergies': <String>[],
    'conditions': <String>[],
    'bloodType': '',
    'weight': 0,
    'height': 0,
    'recentActivity': <Map<String, dynamic>>[],
    'profileCompleted': false,
    'emailVerified': authUser.emailVerified,
    'preferredLocale': 'en',
    'preferredTheme': 'system',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

Map<String, dynamic> _profileToMap(AppUserProfile profile) {
  return {
    'uid': profile.uid,
    'name': profile.name,
    'email': profile.email,
    'avatarEmoji': profile.avatarEmoji,
    'allergies': List<String>.from(profile.allergies),
    'conditions': List<String>.from(profile.conditions),
    'bloodType': profile.bloodType,
    'weight': profile.weight,
    'height': profile.height,
    'recentActivity': profile.recentActivity
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
    'profileCompleted': profile.profileCompleted,
    'emailVerified': profile.emailVerified,
    'preferredLocale': profile.preferredLocale,
    'preferredTheme': profile.preferredTheme,
  };
}

String _resolveDisplayName(fb_auth.User user) {
  final displayName = user.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final email = user.email?.trim().toLowerCase() ?? 'user@example.com';
  final prefix = email.split('@').first;
  if (prefix.isEmpty) return 'User';
  return prefix[0].toUpperCase() + prefix.substring(1);
}
