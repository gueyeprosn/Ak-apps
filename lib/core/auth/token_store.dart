import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Couple de jetons de session mobile. Le jeton d'accès est court (15 min) ;
/// le jeton de renouvellement est rotatif et n'est jamais journalisé.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  Map<String, String> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };

  static AuthTokens? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map &&
          map['accessToken'] is String &&
          map['refreshToken'] is String) {
        return AuthTokens(
          accessToken: map['accessToken'] as String,
          refreshToken: map['refreshToken'] as String,
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  String toString() => 'AuthTokens(<masqués>)';
}

abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// Stockage chiffré par le système (Keychain iOS / Keystore Android).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'ak.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async => AuthTokens.tryParse(await _storage.read(key: _key));

  @override
  Future<void> write(AuthTokens tokens) =>
      _storage.write(key: _key, value: jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Pour les tests uniquement.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._tokens]);
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
