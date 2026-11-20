import 'package:ahloulkhidmah_mobile/features/payment/payment_repository.dart';
import 'package:ahloulkhidmah_mobile/features/payment/payment_security.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/harness.dart';

Map<String, dynamic> dueJson({int n = 3, bool enabled = true, int max = 6}) => {
      'paymentsEnabled': enabled,
      'unitAmount': 1400,
      'maxMonths': max,
      'periods': [
        for (var i = 0; i < n; i++) {'periode': '2026-${(11 - n + 1 + i).toString().padLeft(2, '0')}', 'amount': 1400},
      ],
    };

void main() {
  group('DueInfo', () {
    test('les mois proposés vont du plus récent au plus ancien', () {
      final d = DueInfo.fromJson(dueJson());
      expect(d.periods.map((p) => p.periode), ['2026-09', '2026-10', '2026-11'], reason: 'ordre du serveur : ancien → récent');
      expect(d.newestFirst.map((p) => p.periode), ['2026-11', '2026-10', '2026-09']);
    });

    test('choisir N mois retient les N plus récents, jamais des mois à l\'avance', () {
      final d = DueInfo.fromJson(dueJson());
      expect(d.selection(1).map((p) => p.periode), ['2026-11']);
      expect(d.selection(2).map((p) => p.periode), ['2026-11', '2026-10']);
    });

    test('plafond : jamais plus que les mois dus ni que le maximum du serveur', () {
      expect(DueInfo.fromJson(dueJson(n: 2)).selectableMonths, 2);
      expect(DueInfo.fromJson(dueJson(n: 6, max: 4)).selectableMonths, 4);
    });

    test('aperçu du total = montant × mois (le serveur recalcule et fait foi)', () {
      expect(DueInfo.fromJson(dueJson()).previewTotal(3), 4200);
    });
  });

  group('isAllowedPaymentUrl', () {
    test('accepte HTTPS sur les hôtes de paiement connus', () {
      for (final u in [
        'https://pay.wave.com/c/abc',
        'https://app.paydunya.com/checkout/invoice/x',
        'https://orangemoneysn.page.link/xyz',
        'https://sugu.orange-sonatel.com/p',
      ]) {
        expect(isAllowedPaymentUrl(u), isTrue, reason: u);
      }
    });

    test('refuse HTTP, hôte inconnu, hôte imitant un hôte connu, identifiants, schémas dangereux', () {
      for (final u in [
        'http://pay.wave.com/c/abc',
        'https://evil.example/pay',
        'https://pay.wave.com.evil.example/c',
        'https://evil.example/https://pay.wave.com/',
        'https://user:pw@pay.wave.com/c',
        'javascript:alert(1)',
        'wave://pay?x=1',
        'intent://x#Intent;scheme=http;end',
        '',
      ]) {
        expect(isAllowedPaymentUrl(u), isFalse, reason: u);
      }
      expect(isAllowedPaymentUrl(null), isFalse);
    });
  });

  group('PaymentRepository', () {
    PaymentRepository repo(Map<String, FakeHandler> routes) => PaymentRepository(buildClients(routes, tokens: null).clients);

    test('softpay Wave : prend `url`', () async {
      final r = repo({'POST /api/mobile/v1/payments/p1/softpay': (o) => const FakeReply(200, {'mode': 'softpay', 'url': 'https://pay.wave.com/c/1'})});
      final t = await r.startSoftpay('p1', PayMethod.wave, phone: '+221770000001');
      expect(t.url, 'https://pay.wave.com/c/1');
      expect(t.hosted, isFalse);
    });

    test('softpay Orange Money : préfère `omUrl`, puis `maxitUrl`', () async {
      final a = repo({'POST /api/mobile/v1/payments/p1/softpay': (o) => const FakeReply(200, {'mode': 'softpay', 'omUrl': 'https://orangemoneysn.page.link/a', 'maxitUrl': 'https://sugu.orange-sonatel.com/b'})});
      expect((await a.startSoftpay('p1', PayMethod.orange)).url, 'https://orangemoneysn.page.link/a');
      final b = repo({'POST /api/mobile/v1/payments/p1/softpay': (o) => const FakeReply(200, {'mode': 'softpay', 'maxitUrl': 'https://sugu.orange-sonatel.com/b'})});
      expect((await b.startSoftpay('p1', PayMethod.orange)).url, 'https://sugu.orange-sonatel.com/b');
    });

    test('repli : mode hosted → page de paiement classique', () async {
      final r = repo({'POST /api/mobile/v1/payments/p1/softpay': (o) => const FakeReply(200, {'mode': 'hosted', 'url': 'https://app.paydunya.com/checkout/invoice/z'})});
      final t = await r.startSoftpay('p1', PayMethod.wave);
      expect(t.hosted, isTrue);
      expect(t.url, 'https://app.paydunya.com/checkout/invoice/z');
    });

    test('déjà payé côté serveur', () async {
      final r = repo({'POST /api/mobile/v1/payments/p1/softpay': (o) => const FakeReply(200, {'status': 'completed', 'alreadyPaid': true})});
      expect((await r.startSoftpay('p1', PayMethod.wave)).alreadyPaid, isTrue);
    });

    test('statut : états du serveur, y compris inconnu = « pending » (jamais « payé » par défaut)', () async {
      for (final (raw, expected) in [
        ('completed', PaymentState.completed),
        ('canceled', PaymentState.canceled),
        ('failed', PaymentState.failed),
        ('pending', PaymentState.pending),
        ('n_importe_quoi', PaymentState.pending),
      ]) {
        final r = repo({'GET /api/mobile/v1/payments/p1': (o) => FakeReply(200, {'id': 'p1', 'status': raw, 'amount': 1400, 'periodes': ['2026-11']})});
        expect((await r.status('p1')).state, expected, reason: raw);
      }
    });
  });
}
