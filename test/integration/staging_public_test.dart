// Tests d'intégration : le VRAI client Dart contre le VRAI serveur de test
// (endpoints publics d'adhésion, de don, de SoftPay et de statut).
//
// Ignorés tant que l'URL n'est pas fournie :
//
//   flutter test test/integration/staging_public_test.dart \
//     --dart-define=STAGING_URL=http://127.0.0.1:3001
//
// Limite assumée : le serveur de test n'a PAS de clés PayDunya (aucun
// paiement possible, 503 sur toute création). On vérifie donc le contrat réel
// (statuts, forme des réponses, messages) mais pas la création d'un paiement
// ni sa confirmation : ces deux preuves exigent des clés de TEST PayDunya.
// Les lignes `it-public-pending` / `it-public-done` sont insérées à la main
// dans la base de test (voir docs/ADHESION_DONS.md).
@TestOn('vm')
library;

import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/api/api_error.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/config/env.dart';
import 'package:ahloulkhidmah_mobile/features/payment/payment_repository.dart';
import 'package:ahloulkhidmah_mobile/features/public_pay/public_pay_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = String.fromEnvironment('STAGING_URL');

PublicPayRepository _repo() {
  final clients = createApiClients(
    env: const AppEnv(name: 'staging', apiBaseUrl: _url, allowInsecureHttp: true),
    store: MemoryTokenStore(),
    events: SessionEvents(),
    info: const ClientInfo(platform: 'android', appVersion: '1.0.0'),
  );
  return PublicPayRepository(clients);
}

void main() {
  final skip = _url.isEmpty ? 'STAGING_URL non fourni : test d\'intégration ignoré' : null;

  group('endpoints publics du serveur de test', skip: skip, () {
    const adhesion = AdhesionDraft(
      nom: 'TestMobile',
      prenoms: 'Essai',
      tel: '+221771239901',
      paysRegion: 'Sénégal',
      montant: '1400',
    );

    test('adhésion sans PayDunya : 503 lisible, aucun paiement créé', () async {
      await expectLater(
        _repo().createAdhesion(adhesion),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
    });

    test('don sans PayDunya : 503 lisible', () async {
      await expectLater(
        _repo().createDonation(const DonationDraft(anonymous: true, montant: '5000', campagne: 'general')),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
    });

    test('SoftPay sans PayDunya : 503', () async {
      await expectLater(
        _repo().startSoftpay('it-public-pending', PayMethod.wave, phone: '+221771239901'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
    });

    test('statut d\'un paiement inconnu : 404', () async {
      await expectLater(
        _repo().status('inexistant'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });

    test('statut d\'un paiement en attente : « pending », jamais « payé »', () async {
      final s = await _repo().status('it-public-pending');
      expect(s.state, PaymentState.pending);
      expect(s.amount, 1400);
      expect(s.isFinal, isFalse);
    });

    test('statut d\'un paiement confirmé par le serveur : « completed » avec son montant', () async {
      final s = await _repo().status('it-public-done');
      expect(s.state, PaymentState.completed);
      expect(s.amount, 5000);
      expect(s.isFinal, isTrue);
    });
  });
}
