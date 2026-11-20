import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import '../config/env.dart';

/// Marque une requête qui ne doit ni porter le jeton de session ni déclencher
/// un renouvellement (connexion, renouvellement, création du premier PIN).
const kNoAuth = 'noAuth';
const _kRetried = 'retried';

/// Informations envoyées à chaque requête (versions minimales côté serveur).
class ClientInfo {
  const ClientInfo({required this.platform, required this.appVersion});
  final String platform; // android | ios | other
  final String appVersion;
}

/// Annonce qu'une session ne peut plus être renouvelée (déconnexion forcée).
class SessionEvents {
  final _controller = StreamController<void>.broadcast();
  Stream<void> get expired => _controller.stream;
  void notifyExpired() => _controller.add(null);
  void dispose() => _controller.close();
}

enum RefreshOutcome { renewed, rejected, unreachable }

/// Renouvelle le jeton d'accès. Une seule requête de renouvellement est en vol
/// à la fois : le jeton de renouvellement est rotatif, deux appels simultanés
/// avec le même jeton révoqueraient la session.
class TokenRefresher {
  TokenRefresher(this._plain, this._store, this._events);

  final Dio _plain;
  final TokenStore _store;
  final SessionEvents _events;
  Future<RefreshOutcome>? _inflight;

  Future<RefreshOutcome> refresh() =>
      _inflight ??= _doRefresh().whenComplete(() => _inflight = null);

  Future<RefreshOutcome> _doRefresh() async {
    final current = await _store.read();
    if (current == null) return RefreshOutcome.rejected;
    try {
      final res = await _plain.post<Map<String, dynamic>>(
        '/api/mobile/v1/auth/refresh',
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: {kNoAuth: true}),
      );
      final data = res.data;
      final access = data?['accessToken'];
      final refresh = data?['refreshToken'];
      if (access is String && refresh is String) {
        await _store.write(AuthTokens(accessToken: access, refreshToken: refresh));
        return RefreshOutcome.renewed;
      }
      return RefreshOutcome.rejected;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Seul un refus explicite du serveur met fin à la session : une panne
      // réseau ne doit jamais déconnecter le membre.
      if (status == 401 || status == 400) {
        await _store.clear();
        _events.notifyExpired();
        return RefreshOutcome.rejected;
      }
      return RefreshOutcome.unreachable;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._store, this._refresher);

  final Dio _dio;
  final TokenStore _store;
  final TokenRefresher _refresher;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kNoAuth] != true) {
      final tokens = await _store.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401;
    if (!unauthorized || req.extra[kNoAuth] == true || req.extra[_kRetried] == true) {
      return handler.next(err);
    }
    final outcome = await _refresher.refresh();
    switch (outcome) {
      case RefreshOutcome.renewed:
        final tokens = await _store.read();
        if (tokens == null) return handler.next(err);
        req.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        req.extra[_kRetried] = true;
        try {
          return handler.resolve(await _dio.fetch<dynamic>(req));
        } on DioException catch (e) {
          return handler.next(e);
        }
      case RefreshOutcome.rejected:
        return handler.next(err);
      case RefreshOutcome.unreachable:
        return handler.reject(
          DioException(
            requestOptions: req,
            type: DioExceptionType.connectionError,
            error: 'Renouvellement impossible : réseau indisponible',
          ),
        );
    }
  }
}

class _HeadersInterceptor extends Interceptor {
  _HeadersInterceptor(this._info);
  final ClientInfo _info;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Platform'] = _info.platform;
    options.headers['X-App-Version'] = _info.appVersion;
    handler.next(options);
  }
}

/// Les deux clients HTTP de l'application.
class ApiClients {
  ApiClients({required this.authed, required this.plain, required this.refresher});

  /// Porte le jeton de session et le renouvelle automatiquement.
  final Dio authed;

  /// Sans authentification (configuration distante, catalogue public…).
  final Dio plain;
  final TokenRefresher refresher;
}

BaseOptions _baseOptions(AppEnv env) => BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      headers: const {'Accept': 'application/json'},
    );

/// Construit les clients HTTP. [adapter] permet d'injecter un faux serveur
/// dans les tests.
ApiClients createApiClients({
  required AppEnv env,
  required TokenStore store,
  required SessionEvents events,
  required ClientInfo info,
  HttpClientAdapter? adapter,
}) {
  env.assertSecure();
  final plain = Dio(_baseOptions(env))..interceptors.add(_HeadersInterceptor(info));
  final authed = Dio(_baseOptions(env))..interceptors.add(_HeadersInterceptor(info));
  if (adapter != null) {
    plain.httpClientAdapter = adapter;
    authed.httpClientAdapter = adapter;
  }
  final refresher = TokenRefresher(plain, store, events);
  authed.interceptors.add(_AuthInterceptor(authed, store, refresher));
  return ApiClients(authed: authed, plain: plain, refresher: refresher);
}
