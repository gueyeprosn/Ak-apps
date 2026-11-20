import 'package:ahloulkhidmah_mobile/core/api/api_error.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/phone.dart';
import 'package:ahloulkhidmah_mobile/features/payment/payment_repository.dart';
import 'package:ahloulkhidmah_mobile/features/public_pay/amount_choice.dart';
import 'package:ahloulkhidmah_mobile/features/public_pay/public_pay_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/harness.dart';

PhoneCountry c(String iso) => phoneCountries.firstWhere((x) => x.iso == iso);

void main() {
  group('téléphone (mêmes règles que le site)', () {
    test('Sénégal : 9 chiffres commençant par 70/75/76/77/78', () {
      expect(validatePhone(c('SN'), '77 123 45 67').e164, '+221771234567');
      expect(validatePhone(c('SN'), '701234567').e164, '+221701234567');
      expect(validatePhone(c('SN'), '791234567').problem, PhoneProblem.invalidSenegal);
      expect(validatePhone(c('SN'), '7712345').problem, PhoneProblem.tooShort);
      expect(validatePhone(c('SN'), '7712345678').problem, PhoneProblem.tooLong);
      expect(validatePhone(c('SN'), '  ').problem, PhoneProblem.empty);
    });

    test('chiffres arabo-indiens acceptés', () {
      expect(validatePhone(c('SN'), '٧٧ ١٢٣ ٤٥ ٦٧').e164, '+221771234567');
    });

    test('indicatif collé avec le numéro, ou « 0 » national en tête', () {
      expect(validatePhone(c('SN'), '+221 77 123 45 67').e164, '+221771234567');
      expect(validatePhone(c('SN'), '00221771234567').e164, '+221771234567');
      expect(validatePhone(c('FR'), '06 12 34 56 78').e164, '+33612345678');
      expect(validatePhone(c('FR'), '612345678').e164, '+33612345678');
      expect(validatePhone(c('FR'), '61234567').problem, PhoneProblem.tooShort);
    });

    test('autre pays : numéro complet de 10 à 15 chiffres', () {
      expect(validatePhone(phoneOtherCountry, '+55 11 91234 5678').e164, '+5511912345678');
      expect(validatePhone(phoneOtherCountry, '12345').problem, PhoneProblem.tooShort);
      expect(validatePhone(phoneOtherCountry, '1234567890123456').problem, PhoneProblem.tooLong);
    });

    test('splitE164 retrouve pays et numéro national (formulaire pré-rempli)', () {
      expect(splitE164('+221771234567').country.iso, 'SN');
      expect(splitE164('+221771234567').national, '771234567');
      expect(splitE164('+33612345678').country.iso, 'FR');
      expect(splitE164('+5511912345678').country.dial, '');
    });
  });

  group('montant « autre »', () {
    test('lecture tolérante, jamais de signe ni de décimale', () {
      expect(parseOtherAmount('1 500'), 1500);
      expect(parseOtherAmount('٢٥٠٠'), 2500);
      expect(parseOtherAmount(''), isNull);
      expect(parseOtherAmount('abc'), isNull);
      expect(otherAmountDigits('٢ ٥٠٠'), '2500');
    });
  });

  group('corps envoyés au serveur', () {
    test('adhésion : champs du schéma du site, montant autre seulement si choisi', () {
      const d = AdhesionDraft(nom: ' Diop ', prenoms: 'Awa', tel: '+221771234567', paysRegion: 'Sénégal', montant: '14000');
      expect(d.toJson(), {'nom': 'Diop', 'prenoms': 'Awa', 'tel': '+221771234567', 'paysRegion': 'Sénégal', 'montant': '14000'});
      const o = AdhesionDraft(nom: 'D', prenoms: 'A', tel: '+221771234567', paysRegion: 'S', montant: 'autre', montantAutre: '2500');
      expect(o.toJson()['montantAutre'], '2500');
      expect(o.previewAmount, 2500);
      expect(d.previewAmount, 14000);
    });

    test('don anonyme : AUCUNE donnée d\'identité n\'est envoyée', () {
      const d = DonationDraft(
        anonymous: true,
        montant: '5000',
        campagne: 'touba',
        prenoms: 'Awa',
        nom: 'Diop',
        tel: '+221771234567',
        email: 'a@b.sn',
        message: ' Pour Touba ',
      );
      final j = d.toJson();
      expect(j['anonymous'], true);
      for (final k in ['prenoms', 'nom', 'tel', 'email']) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
      expect(j['message'], 'Pour Touba');
      expect(j['campagne'], 'touba');
    });

    test('don nominatif : identité envoyée, champs vides omis', () {
      const d = DonationDraft(anonymous: false, montant: 'autre', montantAutre: '750', campagne: 'general', prenoms: 'Awa', tel: '+221771234567');
      final j = d.toJson();
      expect(j['prenoms'], 'Awa');
      expect(j['tel'], '+221771234567');
      expect(j.containsKey('nom'), isFalse);
      expect(j.containsKey('email'), isFalse);
      expect(j.containsKey('message'), isFalse);
      expect(j['montantAutre'], '750');
    });

    test('égalité : deux saisies identiques = même demande (paiement réutilisé)', () {
      const a = AdhesionDraft(nom: 'D', prenoms: 'A', tel: '+221771234567', paysRegion: 'S', montant: '1400');
      const b = AdhesionDraft(nom: 'D', prenoms: 'A', tel: '+221771234567', paysRegion: 'S', montant: '1400');
      const other = AdhesionDraft(nom: 'D', prenoms: 'A', tel: '+221771234567', paysRegion: 'S', montant: '14000');
      expect(a == b, isTrue);
      expect(a == other, isFalse);
    });
  });

  group('PublicPayRepository', () {
    PublicPayRepository repo(Map<String, FakeHandler> routes) =>
        PublicPayRepository(buildClients(routes).clients);

    const draft = AdhesionDraft(nom: 'D', prenoms: 'A', tel: '+221771234567', paysRegion: 'S', montant: '1400');

    test('adhésion : paiement hébergé', () async {
      final r = repo({
        'POST /api/adhesions': (o) => const FakeReply(200, {'ok': true, 'paymentId': 'p1', 'paymentUrl': 'https://app.paydunya.com/x'}),
      });
      final p = await r.createAdhesion(draft) as HostedPayment;
      expect(p.paymentId, 'p1');
      expect(p.checkoutUrl, 'https://app.paydunya.com/x');
    });

    test('adhésion : secours Wave du site = instructions, jamais un paiement', () async {
      final r = repo({
        'POST /api/adhesions': (o) => const FakeReply(200, {
              'ok': true,
              'fallback': 'wave',
              'wave': {'number': '+221 75 525 00 02', 'amount': 1400, 'reference': 'AK-1'},
            }),
      });
      final p = await r.createAdhesion(draft);
      expect(p, isA<WaveManualPayment>());
      expect((p as WaveManualPayment).reference, 'AK-1');
    });

    test('réponse sans identifiant de paiement = erreur (rien à payer)', () async {
      final r = repo({'POST /api/adhesions': (o) => const FakeReply(200, {'ok': true})});
      await expectLater(r.createAdhesion(draft), throwsA(isA<ApiException>()));
    });

    test('statut HTTP conservé (409 numéro déjà inscrit)', () async {
      final r = repo({'POST /api/adhesions': (o) => const FakeReply(409, {'error': 'déjà utilisé'})});
      await expectLater(r.createAdhesion(draft), throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)));
    });

    test('don : paiement hébergé avec montant du serveur', () async {
      final r = repo({
        'POST /api/contributions': (o) =>
            const FakeReply(200, {'ok': true, 'contributionId': 'c1', 'paymentId': 'p2', 'url': 'https://app.paydunya.com/y', 'amount': 5000}),
      });
      final p = await r.createDonation(const DonationDraft(anonymous: true, montant: '5000', campagne: 'general')) as HostedPayment;
      expect((p.paymentId, p.amount), ('p2', 5000));
    });

    test('SoftPay : Wave, Orange (omUrl), repli classique, déjà payé', () async {
      LaunchTarget? out;
      Future<void> run(Map<String, Object> body, PayMethod m) async {
        out = await repo({'POST /api/payments/softpay': (o) => FakeReply(200, body)}).startSoftpay('p', m, phone: '+221771234567');
      }

      await run({'ok': true, 'url': 'https://pay.wave.com/c/1'}, PayMethod.wave);
      expect((out!.url, out!.hosted), ('https://pay.wave.com/c/1', false));
      await run({'ok': true, 'url': 'https://u', 'omUrl': 'https://orangemoneysn.page.link/1'}, PayMethod.orange);
      expect(out!.url, 'https://orangemoneysn.page.link/1');
      await run({'ok': true, 'fallback': true, 'url': 'https://app.paydunya.com/z'}, PayMethod.wave);
      expect((out!.url, out!.hosted), ('https://app.paydunya.com/z', true));
      await run({'ok': true, 'alreadyPaid': true, 'status': 'completed'}, PayMethod.wave);
      expect(out!.alreadyPaid, isTrue);
    });

    test('statut : un état inconnu n\'est jamais « payé »', () async {
      PaymentSnapshot? s;
      for (final (raw, expected) in [
        ('completed', PaymentState.completed),
        ('pending', PaymentState.pending),
        ('failed', PaymentState.failed),
        ('canceled', PaymentState.canceled),
        ('whatever', PaymentState.pending),
      ]) {
        s = await repo({'GET /api/payments/p/status': (o) => FakeReply(200, {'id': 'p', 'status': raw, 'amount': 1})}).status('p');
        expect(s.state, expected, reason: raw);
      }
    });

    test('les appels publics ne portent jamais le jeton de session', () async {
      final h = buildClients({
        'POST /api/adhesions': (o) => const FakeReply(200, {'paymentId': 'p'}),
        'GET /api/payments/p/status': (o) => const FakeReply(200, {'status': 'pending'}),
      }, tokens: const AuthTokens(accessToken: 'secret-access', refreshToken: 'secret-refresh'));
      final r = PublicPayRepository(h.clients);
      await r.createAdhesion(draft);
      await r.status('p');
      // Une session existe bel et bien : les appels publics ne l'emploient pas.
      expect(h.adapter.requests, hasLength(2));
      for (final req in h.adapter.requests) {
        expect(req.headers.containsKey('Authorization'), isFalse);
      }
      // Contrôle du contrôle : le client authentifié, lui, porte le jeton.
      await h.clients.authed.get<dynamic>('/api/payments/p/status');
      expect(h.adapter.requests.last.headers['Authorization'], 'Bearer secret-access');
    });
  });
}
