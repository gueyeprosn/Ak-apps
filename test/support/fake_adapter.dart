import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeReply {
  const FakeReply(this.status, [this.body = const {}, this.headers = const {}]);
  final int status;
  final Object body;
  final Map<String, String> headers;
}

typedef FakeHandler = FutureOr<FakeReply> Function(RequestOptions options);

/// Faux serveur HTTP pour les tests : aucune requête réseau ne part.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);

  /// Clé : `METHODE /chemin`.
  final Map<String, FakeHandler> routes;
  final List<RequestOptions> requests = [];

  int count(String key) => requests.where((r) => '${r.method} ${r.path}' == key).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler = routes['${options.method} ${options.path}'];
    if (handler == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Pas de route simulée pour ${options.method} ${options.path}',
      );
    }
    final reply = await handler(options);
    if (reply.body is List<int>) {
      return ResponseBody.fromBytes(
        reply.body as List<int>,
        reply.status,
        headers: {
          Headers.contentTypeHeader: ['image/webp'],
          for (final e in reply.headers.entries) e.key: [e.value],
        },
      );
    }
    final text = reply.body is String ? reply.body as String : jsonEncode(reply.body);
    return ResponseBody.fromString(
      text,
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final e in reply.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Simule une panne réseau.
FakeReply Function(RequestOptions) networkDown() =>
    (o) => throw DioException(requestOptions: o, type: DioExceptionType.connectionError);

Map<String, dynamic> memberJson({
  String name = 'Awa Diop',
  List<Map<String, dynamic>> versements = const [],
}) =>
    {
      'id': 'AK-TEST-1',
      'name': name,
      'prenoms': 'Awa',
      'nom': 'Diop',
      'status': 'actif',
      'hasPin': true,
      'memberNumber': 42,
      'tel': '+221770000001',
      'email': '',
      'whatsapp': '',
      'cotisationPrevue': '1 400 FCFA',
      'versements': versements,
    };

Map<String, dynamic> configJson({
  int version = 3,
  bool maintenance = false,
  String minApp = '1.0.0',
  List<Map<String, dynamic>>? tabs,
  Map<String, bool> features = const {'barkelu': true, 'payments': true},
}) =>
    {
      'configVersion': version,
      'minAppVersion': minApp,
      'recommendedVersion': minApp,
      'maintenance': {
        'enabled': maintenance,
        'message': maintenance ? {'fr': 'Retour à 18 h.', 'ar': 'نعود في السادسة.'} : null,
      },
      'features': features,
      'tabs': tabs ??
          [
            {'id': 'home', 'label': {'fr': 'Accueil', 'ar': 'الرئيسية'}, 'type': 'native', 'screen': 'home', 'icon': 'home'},
            {'id': 'cotisations', 'label': {'fr': 'Cotisations', 'ar': 'الاشتراكات'}, 'type': 'native', 'screen': 'cotisations', 'icon': 'wallet', 'requiresAuth': true, 'feature': 'payments'},
            {'id': 'barkelu', 'label': {'fr': 'Barkelu'}, 'type': 'native', 'screen': 'barkelu', 'icon': 'shop', 'feature': 'barkelu'},
            {'id': 'account', 'label': {'fr': 'Mon compte', 'ar': 'حسابي'}, 'type': 'native', 'screen': 'account', 'icon': 'person', 'requiresAuth': true},
          ],
      'webAllowlist': ['www.ahloulkhidmah.org'],
      'messages': [],
    };

DioException networkDownError(RequestOptions o) =>
    DioException(requestOptions: o, type: DioExceptionType.connectionError);
