import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remote_config.dart';

enum ConfigSource { network, cache, embedded }

class ConfigLoad {
  const ConfigLoad(this.config, this.source);
  final MobileConfig config;
  final ConfigSource source;
}

/// Récupère la configuration distante avec un cache à validation `ETag`.
///
/// Ordre de repli, sans jamais lever d'erreur vers l'interface :
/// 1. réseau (200) → mis en cache ; 304 → cache ;
/// 2. dernière configuration valide en cache ;
/// 3. configuration embarquée dans l'application.
class ConfigRepository {
  ConfigRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  static const _kJson = 'cfg.v1.json';
  static const _kEtag = 'cfg.v1.etag';

  MobileConfig? _readCache() {
    final raw = _prefs.getString(_kJson);
    if (raw == null) return null;
    try {
      return MobileConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // cache corrompu : on l'ignore
    }
  }

  Future<ConfigLoad> load() async {
    final cached = _readCache();
    try {
      final etag = cached == null ? null : _prefs.getString(_kEtag);
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/mobile/v1/config',
        options: Options(
          headers: {if (etag != null) 'If-None-Match': etag},
          // 304 n'est pas une erreur ici.
          validateStatus: (s) => s != null && (s == 200 || s == 304),
        ),
      );
      if (res.statusCode == 304 && cached != null) {
        return ConfigLoad(cached, ConfigSource.cache);
      }
      final data = res.data;
      if (data != null) {
        final fresh = MobileConfig.fromJson(data); // peut lever FormatException
        await _prefs.setString(_kJson, jsonEncode(data));
        final newEtag = res.headers.value('etag');
        if (newEtag != null) {
          await _prefs.setString(_kEtag, newEtag);
        } else {
          await _prefs.remove(_kEtag);
        }
        return ConfigLoad(fresh, ConfigSource.network);
      }
    } on DioException {
      // hors ligne ou serveur indisponible : repli ci-dessous
    } on FormatException {
      // configuration reçue invalide : on garde la dernière valide
    }
    if (cached != null) return ConfigLoad(cached, ConfigSource.cache);
    return const ConfigLoad(MobileConfig.embedded, ConfigSource.embedded);
  }
}
