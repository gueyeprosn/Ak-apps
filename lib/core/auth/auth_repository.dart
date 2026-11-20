import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_error.dart';
import 'member.dart';
import 'token_store.dart';

sealed class LoginResult {
  const LoginResult();
}

/// Connexion réussie : une session mobile est ouverte.
class LoginSuccess extends LoginResult {
  const LoginSuccess(this.member);
  final Member member;
}

/// Premier accès : le serveur n'ouvre **pas** de session. Le membre doit créer
/// son code PIN avec ce jeton à usage unique (décision D2).
class PinSetupRequired extends LoginResult {
  const PinSetupRequired(this.setupToken);
  final String setupToken;
}

/// Accès à `/api/mobile/v1/auth/*` et `/me`.
class AuthRepository {
  AuthRepository(this._clients, this._store, this._info);

  final ApiClients _clients;
  final TokenStore _store;
  final ClientInfo _info;

  Map<String, Object?>? get _device => _info.platform == 'android' || _info.platform == 'ios'
      ? {'platform': _info.platform, 'appVersion': _info.appVersion}
      : null;

  Future<LoginResult> login({required String tel, required String code}) => guardApi(() async {
        final res = await _clients.plain.post<Map<String, dynamic>>(
          '/api/mobile/v1/auth/login',
          // Le champ s'appelle `suffix` dans le contrat serveur : il porte le
          // PIN (ou, au premier accès, le suffixe du badge).
          data: {'tel': tel, 'suffix': code, if (_device != null) 'device': _device},
          options: Options(extra: {kNoAuth: true}),
        );
        final data = res.data ?? const {};
        if (data['status'] == 'pin_setup_required' && data['setupToken'] is String) {
          return PinSetupRequired(data['setupToken'] as String);
        }
        return LoginSuccess(await _openSession(data));
      });

  /// Crée le premier PIN avec le jeton à usage unique, puis ouvre la session.
  Future<Member> setupPin({
    required String setupToken,
    required String pin,
    required String pinConfirm,
  }) =>
      guardApi(() async {
        final res = await _clients.plain.post<Map<String, dynamic>>(
          '/api/mobile/v1/auth/pin-setup',
          data: {'pin': pin, 'pinConfirm': pinConfirm, if (_device != null) 'device': _device},
          options: Options(
            headers: {'Authorization': 'Bearer $setupToken'},
            extra: {kNoAuth: true},
          ),
        );
        return _openSession(res.data ?? const {});
      });

  Future<Member> _openSession(Map<String, dynamic> data) async {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    final member = data['member'];
    if (access is! String || refresh is! String || member is! Map<String, dynamic>) {
      throw const ApiException(code: 'bad_response', message: 'Réponse inattendue du serveur');
    }
    await _store.write(AuthTokens(accessToken: access, refreshToken: refresh));
    return Member.fromJson(member);
  }

  /// Profil du membre connecté. Le renouvellement du jeton est transparent.
  Future<Member> me() => guardApi(() async {
        final res = await _clients.authed.get<Map<String, dynamic>>('/api/mobile/v1/me');
        final member = res.data?['member'];
        if (member is! Map<String, dynamic>) {
          throw const ApiException(code: 'bad_response', message: 'Réponse inattendue du serveur');
        }
        return Member.fromJson(member);
      });

  Future<bool> hasSession() async => (await _store.read()) != null;

  /// Déconnexion : le serveur révoque la session, puis les jetons locaux sont
  /// effacés **dans tous les cas** (même hors ligne).
  Future<void> logout({String? pushToken}) async {
    final tokens = await _store.read();
    try {
      if (tokens != null) {
        await _clients.plain.post<dynamic>(
          '/api/mobile/v1/auth/logout',
          data: {'refreshToken': tokens.refreshToken, if (pushToken != null) 'pushToken': pushToken},
          options: Options(extra: {kNoAuth: true}),
        );
      }
    } on DioException {
      // Hors ligne : la session serveur expirera seule ; on déconnecte quand même.
    } finally {
      await _store.clear();
    }
  }
}
