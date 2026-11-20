import 'dart:async';

import 'package:ahloulkhidmah_mobile/core/format.dart';
import 'package:dio/dio.dart' show RequestOptions;

import 'fake_adapter.dart';

/// `YYYY-MM` du mois courant décalé de [back] mois (tests indépendants de la date).
String ym(int back) {
  final n = DateTime.now();
  return currentPeriode(DateTime(n.year, n.month - back));
}

const waveUrl = 'https://pay.wave.com/c/abc';
const hostedUrl = 'https://app.paydunya.com/checkout/invoice/inv-1';

/// Faux serveur de paiement, avec compteurs pour vérifier ce qui a été appelé.
class PayServer {
  PayServer({
    this.enabled = true,
    List<String>? periods,
    this.createStatus = 200,
    this.softpayBody = const {'mode': 'softpay', 'url': waveUrl},
    List<String>? statuses,
  })  : periods = periods ?? [ym(2), ym(1), ym(0)],
        statuses = statuses ?? ['pending', 'pending', 'completed'];

  bool enabled;
  List<String> periods;
  int createStatus;
  Map<String, Object> softpayBody;
  List<String> statuses;
  int created = 0;
  int polled = 0;
  bool statusDown = false;

  /// Si défini, le suivi reste « en vol » jusqu'à sa libération (écran d'attente figé).
  Completer<void>? gate;
  final createdBodies = <Object?>[];
  final softpayBodies = <Object?>[];
  final memberVersements = <Map<String, dynamic>>[];

  String get currentId => 'pay-$created';

  Map<String, FakeHandler> routes() => {
        'GET /api/mobile/v1/config': (o) => FakeReply(200, configJson(), {'etag': '"c"'}),
        'GET /api/store/products': (o) => const FakeReply(200, {'products': []}),
        'GET /api/mobile/v1/me': (o) => FakeReply(200, {'member': memberJson(versements: memberVersements)}),
        'GET /api/mobile/v1/payments/due': (o) => FakeReply(200, {
              'paymentsEnabled': enabled,
              'unitAmount': 1400,
              'maxMonths': 6,
              'periods': [for (final p in periods) {'periode': p, 'amount': 1400}],
            }),
        'POST /api/mobile/v1/payments/cotisation': (o) {
          createdBodies.add(o.data);
          if (createStatus != 200) {
            return FakeReply(createStatus, {'error': {'code': 'payments_unavailable', 'message': 'x'}});
          }
          created++;
          final n = (o.data as Map)['monthsCount'] as int;
          return FakeReply(200, {
            'paymentId': 'pay-$created',
            'amount': 1400 * n,
            'periodes': periods.reversed.take(n).toList().reversed.toList(),
            'checkoutUrl': hostedUrl,
          });
        },
        'POST /api/mobile/v1/payments/pay-1/softpay': (o) => _softpay(o),
        'POST /api/mobile/v1/payments/pay-2/softpay': (o) => _softpay(o),
        'GET /api/mobile/v1/payments/pay-1': (o) => _status('pay-1', o),
        'GET /api/mobile/v1/payments/pay-2': (o) => _status('pay-2', o),
      };

  FakeReply _softpay(RequestOptions o) {
    softpayBodies.add(o.data);
    return FakeReply(200, softpayBody);
  }

  Future<FakeReply> _status(String id, RequestOptions o) async {
    if (statusDown) throw networkDownError(o);
    if (gate != null) await gate!.future;
    final s = statuses[polled < statuses.length ? polled : statuses.length - 1];
    polled++;
    return FakeReply(200, {
      'id': id,
      'status': s,
      'amount': 2800,
      'periodes': [ym(1), ym(0)],
      'receiptUrl': s == 'completed' ? 'https://app.paydunya.com/receipt/r1' : null,
    });
  }
}

