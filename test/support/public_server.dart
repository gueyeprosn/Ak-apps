import 'dart:async';

import 'package:dio/dio.dart' show RequestOptions;

import 'fake_adapter.dart';
import 'pay_server.dart' show hostedUrl, waveUrl;

/// Faux serveur des endpoints PUBLICS du site (adhésion, don, SoftPay, statut),
/// avec compteurs pour vérifier ce qui a été appelé.
class PublicServer {
  PublicServer({
    this.createStatus = 200,
    this.createError,
    this.softpayBody = const {'ok': true, 'method': 'wave', 'url': waveUrl},
    List<String>? statuses,
    this.confirmedAmount = 14000,
    this.paymentsFeature = true,
    this.wavePhone,
  }) : statuses = statuses ?? ['pending', 'pending', 'completed'];

  int createStatus;
  Map<String, Object>? createError;
  Map<String, Object> softpayBody;
  List<String> statuses;

  /// Montant du paiement confirmé, côté « serveur » (≠ saisie : preuve que
  /// l'écran final affiche celui du serveur).
  int confirmedAmount;
  bool paymentsFeature;
  Map<String, Object>? wavePhone;

  int adhesions = 0;
  int donations = 0;
  int polled = 0;
  final adhesionBodies = <Object?>[];
  final donationBodies = <Object?>[];
  final softpayBodies = <Object?>[];
  int statusReplyCode = 200;
  Map<String, String> statusHeaders = const {};

  /// Si défini, le suivi reste « en vol » jusqu'à sa libération.
  Completer<void>? gate;

  int get created => adhesions + donations;
  String get currentId => 'pay-$created';

  Map<String, FakeHandler> routes() => {
        'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson(features: {'barkelu': true, 'payments': paymentsFeature}), {'etag': '"c"'}),
        'GET /api/store/products': (o) => const FakeReply(200, {'products': []}),
        'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson()}),
        'POST /api/adhesions': (o) {
          adhesionBodies.add(o.data);
          if (createStatus != 200) {
            return FakeReply(createStatus, createError ?? {'error': 'Erreur serveur'});
          }
          adhesions++;
          if (wavePhone != null) return FakeReply(200, {'ok': true, 'fallback': 'wave', 'wave': wavePhone!, 'preview': {}});
          return FakeReply(200, {'ok': true, 'paymentId': currentId, 'paymentUrl': hostedUrl, 'preview': {}});
        },
        'POST /api/contributions': (o) {
          donationBodies.add(o.data);
          if (createStatus != 200) {
            return FakeReply(createStatus, createError ?? {'error': 'Erreur contribution'});
          }
          donations++;
          return FakeReply(200, {'ok': true, 'contributionId': 'c-$donations', 'paymentId': currentId, 'url': hostedUrl, 'amount': 10000});
        },
        'POST /api/payments/softpay': (o) {
          softpayBodies.add(o.data);
          return FakeReply(200, softpayBody);
        },
        for (final id in ['pay-1', 'pay-2', 'pay-3']) 'GET /api/payments/$id/status': (o) => _status(id, o),
      };

  Future<FakeReply> _status(String id, RequestOptions o) async {
    if (gate != null) await gate!.future;
    if (statusReplyCode != 200) return FakeReply(statusReplyCode, {'error': 'Trop de demandes'}, statusHeaders);
    final s = statuses[polled < statuses.length ? polled : statuses.length - 1];
    polled++;
    return FakeReply(200, {
      'ok': true,
      'id': id,
      'status': s,
      'amount': confirmedAmount,
      'type': 'adhesion',
      'receiptUrl': s == 'completed' ? 'https://app.paydunya.com/receipt/r1' : null,
      'checkoutUrl': hostedUrl,
    });
  }
}
