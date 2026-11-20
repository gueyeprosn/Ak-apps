import 'package:ahloulkhidmah_mobile/core/auth/member.dart';
import 'package:ahloulkhidmah_mobile/core/config/env.dart';
import 'package:ahloulkhidmah_mobile/core/config/remote_config.dart';
import 'package:ahloulkhidmah_mobile/core/format.dart';
import 'package:ahloulkhidmah_mobile/core/security/web_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/fake_adapter.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  group('periodeLabel', () {
    test('mois en français', () {
      expect(periodeLabel('2026-11', 'fr'), 'novembre 2026');
      expect(periodeLabel('2026-01', 'fr'), 'janvier 2026');
    });
    test('mois en arabe (le serveur ne les fournit qu\'en français)', () {
      final ar = periodeLabel('2026-11', 'ar');
      expect(ar, isNot('novembre 2026'));
      expect(ar, contains('نوفمبر'));
    });
    test('valeur invalide : renvoyée telle quelle, sans planter', () {
      expect(periodeLabel('abc', 'fr'), 'abc');
      expect(periodeLabel('2026-13', 'fr'), '2026-13');
    });
  });

  group('compareVersions', () {
    test('ordre numérique, pas alphabétique', () {
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.2.3', '1.2.3'), 0);
      expect(compareVersions('1.2.3+45', '1.2.3'), 0, reason: 'le numéro de build est ignoré');
    });
  });

  group('MobileConfig', () {
    test('analyse le contrat du serveur', () {
      final c = MobileConfig.fromJson(configJson());
      expect(c.version, 3);
      expect(c.tabs.map((t) => t.id), ['home', 'cotisations', 'barkelu', 'account']);
      expect(c.tabs.last.requiresAuth, isTrue);
      expect(c.tabs.first.label.resolve('ar'), 'الرئيسية');
    });

    test("l'arabe retombe sur le français quand il manque", () {
      final c = MobileConfig.fromJson(configJson());
      final barkelu = c.tabs.firstWhere((t) => t.id == 'barkelu');
      expect(barkelu.label.resolve('ar'), 'Barkelu');
    });

    test('un drapeau désactivé masque la rubrique ; un drapeau absent la laisse', () {
      final off = MobileConfig.fromJson(configJson(features: {'barkelu': false}));
      expect(off.visibleTabs.map((t) => t.id), ['home', 'cotisations', 'account']);
      final missing = MobileConfig.fromJson(configJson(features: const {}));
      expect(missing.visibleTabs.length, 4, reason: 'rétrocompatibilité : drapeau inconnu = actif');
    });

    test('un type de rubrique inconnu ne plante pas', () {
      final c = MobileConfig.fromJson(configJson(tabs: [
        {'id': 'x', 'label': {'fr': 'X'}, 'type': 'hologramme', 'screen': 'z'},
      ]));
      expect(c.tabs.single.type, TabType.unknown);
    });

    test('rejette une configuration invalide (repli côté dépôt)', () {
      expect(() => MobileConfig.fromJson({'tabs': []}), throwsFormatException);
      expect(() => MobileConfig.fromJson(configJson(minApp: 'abc')), throwsFormatException);
    });

    test('la configuration embarquée est exploitable seule', () {
      expect(MobileConfig.embedded.visibleTabs.length, 4);
      expect(MobileConfig.embedded.maintenanceEnabled, isFalse);
    });
  });

  group('formatAmount', () {
    test('français : espace insécable U+00A0 (Cairo n\'a pas U+202F)', () {
      expect(formatAmount(1400, 'fr'), '1 400 FCFA');
      expect(formatAmount(140000, 'fr'), '140 000 FCFA');
      expect(formatAmount(500, 'fr'), '500 FCFA');
      expect(formatAmount(0, 'fr'), '0 FCFA');
    });

    test('arabe : chiffres arabo-indiens, séparateur ٬ (U+066C), « فرنك »', () {
      expect(formatAmount(1400, 'ar'), '١٬٤٠٠ فرنك');
      expect(formatAmount(12000, 'ar'), '١٢٬٠٠٠ فرنك');
    });

    test('le séparateur arabe de milliers ne contient jamais d\'espace ordinaire', () {
      // Une espace ordinaire inverserait l'ordre des groupes dans un texte RTL.
      final s = formatAmount(1234567, 'ar').split(' ').first;
      expect(s.contains(' '), isFalse);
    });
  });

  group('isAllowedWebUrl', () {
    const hosts = ['www.ahloulkhidmah.org'];
    test('accepte HTTPS sur un hôte autorisé', () {
      expect(isAllowedWebUrl('https://www.ahloulkhidmah.org/mission', hosts), isTrue);
    });
    test('refuse HTTP, autre hôte, sous-domaine piège et identifiants intégrés', () {
      expect(isAllowedWebUrl('http://www.ahloulkhidmah.org/', hosts), isFalse);
      expect(isAllowedWebUrl('https://evil.example/', hosts), isFalse);
      expect(isAllowedWebUrl('https://www.ahloulkhidmah.org.evil.example/', hosts), isFalse);
      expect(isAllowedWebUrl('https://user:pw@www.ahloulkhidmah.org/', hosts), isFalse);
      expect(isAllowedWebUrl('javascript:alert(1)', hosts), isFalse);
      expect(isAllowedWebUrl(null, hosts), isFalse);
      expect(isAllowedWebUrl('', hosts), isFalse);
    });
  });

  group('AppEnv', () {
    test('HTTPS obligatoire en production, même si HTTP est « autorisé »', () {
      expect(
        () => const AppEnv(name: 'prod', apiBaseUrl: 'http://x.test', allowInsecureHttp: true).assertSecure(),
        throwsStateError,
      );
      expect(() => const AppEnv(name: 'prod', apiBaseUrl: 'https://x.test').assertSecure(), returnsNormally);
    });
    test('HTTP seulement hors production et sur demande explicite', () {
      expect(() => const AppEnv(name: 'dev', apiBaseUrl: 'http://127.0.0.1:3001').assertSecure(), throwsStateError);
      expect(
        () => const AppEnv(name: 'dev', apiBaseUrl: 'http://127.0.0.1:3001', allowInsecureHttp: true).assertSecure(),
        returnsNormally,
      );
    });
  });

  group('Member', () {
    test('lit le profil et retrouve le versement d\'une période', () {
      final m = Member.fromJson(memberJson(versements: [
        {'periode': '2026-11', 'periodeLabel': 'novembre 2026', 'montant': 1400, 'statut': 'paye', 'canal': 'paydunya', 'paidAt': '2026-11-12T10:00:00.000Z'},
        {'periode': '2026-10', 'periodeLabel': 'octobre 2026', 'montant': 1400, 'statut': 'en_attente', 'canal': 'paydunya'},
      ]));
      expect(m.initials, 'AD');
      expect(m.versementFor('2026-11')!.isPaid, isTrue);
      expect(m.versementFor('2026-10')!.isPaid, isFalse);
      expect(m.versementFor('2026-09'), isNull);
    });
  });
}
