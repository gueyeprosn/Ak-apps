import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/api_error.dart';
import 'auth/auth_repository.dart';
import 'auth/member.dart';
import 'auth/token_store.dart';
import 'config/config_repository.dart';
import 'storage/card_cache.dart';
import 'config/env.dart';

// ---------------------------------------------------------------- socle
final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromDefines);

/// Doit être surchargé au démarrage (`main`) avec l'instance réelle.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider non initialisé'),
);

/// Doit être surchargé au démarrage avec la plateforme et la version réelles.
final clientInfoProvider = Provider<ClientInfo>(
  (ref) => throw UnimplementedError('clientInfoProvider non initialisé'),
);

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

/// Surchargé dans les tests pour injecter un faux serveur.
final httpAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

final apiClientsProvider = Provider<ApiClients>((ref) {
  return createApiClients(
    env: ref.watch(appEnvProvider),
    store: ref.watch(tokenStoreProvider),
    events: ref.watch(sessionEventsProvider),
    info: ref.watch(clientInfoProvider),
    adapter: ref.watch(httpAdapterProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      ref.watch(apiClientsProvider),
      ref.watch(tokenStoreProvider),
      ref.watch(clientInfoProvider),
    ));

final configRepositoryProvider =
    Provider<ConfigRepository>((ref) => ConfigRepository(
          ref.watch(apiClientsProvider).plain,
          ref.watch(sharedPrefsProvider),
        ));

final installedVersionProvider =
    Provider<String>((ref) => ref.watch(clientInfoProvider).appVersion);

// ---------------------------------------------------------------- configuration distante
/// Ne lève jamais : retombe sur le cache puis sur la configuration embarquée.
final configProvider = FutureProvider<ConfigLoad>(
  (ref) => ref.watch(configRepositoryProvider).load(),
);

// ---------------------------------------------------------------- authentification
sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthLoggedIn extends AuthState {
  const AuthLoggedIn(this.member);
  final Member member;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final sub = ref.read(sessionEventsProvider).expired.listen((_) {
      state = const AuthLoggedOut();
      ref.read(cardCacheProvider).clear();
    });
    ref.onDispose(sub.cancel);
    return const AuthUnknown();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Reprend la session au lancement. Lève [ApiException] (`network`) si le
  /// serveur est injoignable : l'écran « hors ligne » propose de réessayer.
  Future<void> restore() async {
    if (!await _repo.hasSession()) {
      state = const AuthLoggedOut();
      return;
    }
    try {
      state = AuthLoggedIn(await _repo.me());
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        state = const AuthLoggedOut();
      } else {
        rethrow;
      }
    }
  }

  Future<LoginResult> login({required String tel, required String code}) async {
    final result = await _repo.login(tel: tel, code: code);
    if (result is LoginSuccess) state = AuthLoggedIn(result.member);
    return result;
  }

  Future<void> completePinSetup({
    required String setupToken,
    required String pin,
    required String pinConfirm,
  }) async {
    final member = await _repo.setupPin(
      setupToken: setupToken,
      pin: pin,
      pinConfirm: pinConfirm,
    );
    state = AuthLoggedIn(member);
  }

  Future<void> reloadProfile() async {
    state = AuthLoggedIn(await _repo.me());
  }

  Future<void> logout({String? pushToken}) async {
    await _repo.logout(pushToken: pushToken);
    // La copie locale de la carte contient des données personnelles.
    await ref.read(cardCacheProvider).clear();
    state = const AuthLoggedOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Jeton à usage unique de création du PIN, gardé **en mémoire seulement**.
class PinSetupSession extends Notifier<String?> {
  @override
  String? build() => null;
  void start(String token) => state = token;
  void clear() => state = null;
}

final pinSetupSessionProvider =
    NotifierProvider<PinSetupSession, String?>(PinSetupSession.new);

// ---------------------------------------------------------------- démarrage
/// Charge la configuration puis reprend la session. Une erreur réseau mène à
/// l'écran « hors ligne » (réessayer) ; jamais d'écran blanc.
final bootstrapProvider = FutureProvider<void>(
  (ref) async {
    await ref.watch(configProvider.future);
    await ref.read(authControllerProvider.notifier).restore();
  },
);

// ---------------------------------------------------------------- préférences
/// `null` = langue du téléphone ; sinon `fr` ou `ar`.
class LanguagePref extends Notifier<String?> {
  static const _key = 'pref.lang';

  @override
  String? build() {
    final v = ref.read(sharedPrefsProvider).getString(_key);
    return v == 'fr' || v == 'ar' ? v : null;
  }

  Future<void> set(String? code) async {
    state = code;
    final prefs = ref.read(sharedPrefsProvider);
    if (code == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, code);
    }
  }
}

final languagePrefProvider =
    NotifierProvider<LanguagePref, String?>(LanguagePref.new);

class ThemePref extends Notifier<ThemeMode> {
  static const _key = 'pref.theme';

  @override
  ThemeMode build() => switch (ref.read(sharedPrefsProvider).getString(_key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPrefsProvider);
    if (mode == ThemeMode.system) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, mode.name);
    }
  }
}

final themePrefProvider = NotifierProvider<ThemePref, ThemeMode>(ThemePref.new);

class OnboardingPref extends Notifier<bool> {
  static const _key = 'pref.onboarding.complete';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    final saved = await ref.read(sharedPrefsProvider).setBool(_key, true);
    if (!saved) throw StateError('Préférence de découverte non enregistrée');
    state = true;
  }
}

final onboardingPrefProvider =
    NotifierProvider<OnboardingPref, bool>(OnboardingPref.new);
