import 'dart:convert';

import 'package:dio/dio.dart';

/// Erreur normalisée de l'API mobile (`{ "error": { "code", "message" } }`).
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status,
    this.retryAfter,
  });

  /// Code stable côté serveur (`invalid_credentials`, `rate_limited`, …) ou
  /// `network` / `unknown` côté client.
  final String code;
  final String message;
  final int? status;
  final Duration? retryAfter;

  bool get isNetwork => code == 'network';
  bool get isUnauthorized => status == 401;
  bool get isRateLimited => code == 'rate_limited' || status == 429;

  @override
  String toString() => 'ApiException($code, status: $status)';
}

extension DioExceptionMapping on DioException {
  ApiException toApiException() {
    final res = response;
    if (res != null) {
      var data = res.data;
      // Requête en octets (image) : le corps d'erreur JSON n'est pas décodé par
      // Dio ; on le décode ici pour ne pas perdre le code d'erreur du serveur.
      if (data is List<int>) {
        try {
          data = jsonDecode(utf8.decode(data));
        } on Object {
          data = null;
        }
      }
      String code = 'unknown';
      String message = 'Erreur ${res.statusCode}';
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        code = (err['code'] ?? code).toString();
        message = (err['message'] ?? message).toString();
      } else if (data is Map && data['error'] is String) {
        message = data['error'] as String;
      }
      Duration? retry;
      final header = res.headers.value('retry-after');
      final seconds = header == null ? null : int.tryParse(header);
      if (seconds != null) retry = Duration(seconds: seconds);
      return ApiException(
        code: code,
        message: message,
        status: res.statusCode,
        retryAfter: retry,
      );
    }
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(code: 'network', message: 'Réseau indisponible');
      default:
        return ApiException(code: 'unknown', message: message ?? 'Erreur inconnue');
    }
  }
}

/// Exécute une requête et convertit toute erreur Dio en [ApiException].
Future<T> guardApi<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    throw e.toApiException();
  }
}
