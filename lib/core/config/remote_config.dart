/// Contrat de la configuration distante (`GET /api/mobile/v1/config`).
///
/// Ce sont des **données** : l'application n'exécute jamais de code reçu du
/// serveur (règle des magasins). Un `screen` inconnu de cette version mène à
/// l'écran de repli, jamais à une erreur.
library;

/// Texte bilingue. L'arabe retombe sur le français s'il est absent.
class LocalizedText {
  const LocalizedText({required this.fr, this.ar});

  factory LocalizedText.fromJson(Object? j) {
    if (j is Map) {
      return LocalizedText(fr: (j['fr'] ?? '').toString(), ar: j['ar'] as String?);
    }
    return LocalizedText(fr: (j ?? '').toString());
  }

  final String fr;
  final String? ar;

  String resolve(String languageCode) =>
      languageCode == 'ar' && ar != null && ar!.isNotEmpty ? ar! : fr;
}

enum TabType { native, webview, external, unknown }

class TabConfig {
  const TabConfig({
    required this.id,
    required this.label,
    required this.type,
    this.icon,
    this.screen,
    this.url,
    this.requiresAuth = false,
    this.feature,
  });

  factory TabConfig.fromJson(Map<String, dynamic> j) => TabConfig(
        id: (j['id'] ?? '').toString(),
        label: LocalizedText.fromJson(j['label']),
        icon: j['icon'] as String?,
        type: switch (j['type']) {
          'native' => TabType.native,
          'webview' => TabType.webview,
          'external' => TabType.external,
          _ => TabType.unknown,
        },
        screen: j['screen'] as String?,
        url: j['url'] as String?,
        requiresAuth: j['requiresAuth'] == true,
        feature: j['feature'] as String?,
      );

  /// Identifiant stable de la rubrique, jamais réutilisé côté serveur.
  final String id;
  final LocalizedText label;
  final String? icon;
  final TabType type;
  final String? screen;
  final String? url;
  final bool requiresAuth;
  final String? feature;
}

class ConfigMessage {
  const ConfigMessage({required this.id, required this.level, required this.text});
  final String id;
  final String level; // info | warning
  final LocalizedText text;
}

class MobileConfig {
  const MobileConfig({
    required this.version,
    required this.minAppVersion,
    required this.recommendedVersion,
    required this.maintenanceEnabled,
    required this.maintenanceMessage,
    required this.features,
    required this.tabs,
    required this.webAllowlist,
    required this.messages,
  });

  /// Lève une [FormatException] si le contrat n'est pas respecté : l'appelant
  /// retombe alors sur la dernière configuration valide ou celle embarquée.
  factory MobileConfig.fromJson(Map<String, dynamic> j) {
    final tabsJson = j['tabs'];
    if (tabsJson is! List || tabsJson.isEmpty) {
      throw const FormatException('config: tabs manquant');
    }
    final minV = (j['minAppVersion'] ?? '').toString();
    final recV = (j['recommendedVersion'] ?? minV).toString();
    if (!_semver.hasMatch(minV)) {
      throw FormatException('config: minAppVersion invalide ($minV)');
    }
    final maintenance = j['maintenance'] is Map ? j['maintenance'] as Map : const {};
    return MobileConfig(
      version: (j['configVersion'] as num?)?.toInt() ?? 0,
      minAppVersion: minV,
      recommendedVersion: _semver.hasMatch(recV) ? recV : minV,
      maintenanceEnabled: maintenance['enabled'] == true,
      maintenanceMessage: maintenance['message'] == null
          ? null
          : LocalizedText.fromJson(maintenance['message']),
      features: {
        for (final e in ((j['features'] as Map?) ?? const {}).entries)
          e.key.toString(): e.value == true,
      },
      tabs: [
        for (final t in tabsJson)
          if (t is Map<String, dynamic>) TabConfig.fromJson(t),
      ],
      webAllowlist: [
        for (final h in (j['webAllowlist'] as List? ?? const [])) h.toString().toLowerCase(),
      ],
      messages: [
        for (final m in (j['messages'] as List? ?? const []))
          if (m is Map)
            ConfigMessage(
              id: (m['id'] ?? '').toString(),
              level: (m['level'] ?? 'info').toString(),
              text: LocalizedText.fromJson(m['text']),
            ),
      ],
    );
  }

  static final _semver = RegExp(r'^\d+\.\d+\.\d+$');

  final int version;
  final String minAppVersion;
  final String recommendedVersion;
  final bool maintenanceEnabled;
  final LocalizedText? maintenanceMessage;
  final Map<String, bool> features;
  final List<TabConfig> tabs;
  final List<String> webAllowlist;
  final List<ConfigMessage> messages;

  /// Un drapeau absent est considéré actif (rétrocompatibilité : une nouvelle
  /// version de l'application ne doit pas masquer une rubrique que le serveur
  /// n'a pas encore déclarée).
  bool featureEnabled(String? feature) => feature == null || (features[feature] ?? true);

  /// Rubriques affichables : drapeau actif. Les rubriques réservées aux
  /// membres restent visibles (elles mènent à la connexion pour un visiteur).
  List<TabConfig> get visibleTabs =>
      tabs.where((t) => featureEnabled(t.feature)).toList(growable: false);

  /// Configuration embarquée : utilisée au premier lancement sans réseau et si
  /// la configuration reçue est invalide. Identique à celle du serveur.
  static const MobileConfig embedded = MobileConfig(
    version: 0,
    minAppVersion: '1.0.0',
    recommendedVersion: '1.0.0',
    maintenanceEnabled: false,
    maintenanceMessage: null,
    features: {'barkelu': true, 'payments': true},
    webAllowlist: ['www.ahloulkhidmah.org'],
    messages: [],
    tabs: [
      TabConfig(
        id: 'home',
        label: LocalizedText(fr: 'Accueil', ar: 'الرئيسية'),
        type: TabType.native,
        icon: 'home',
        screen: 'home',
      ),
      TabConfig(
        id: 'card',
        label: LocalizedText(fr: 'Carte', ar: 'بطاقة'),
        type: TabType.native,
        icon: 'card',
        screen: 'card',
        requiresAuth: true,
      ),
      TabConfig(
        id: 'cotisations',
        label: LocalizedText(fr: 'Cotisations', ar: 'الاشتراكات'),
        type: TabType.native,
        icon: 'wallet',
        screen: 'cotisations',
        requiresAuth: true,
        feature: 'payments',
      ),
      TabConfig(
        id: 'barkelu',
        label: LocalizedText(fr: 'Barkelu', ar: 'المتجر'),
        type: TabType.native,
        icon: 'shop',
        screen: 'barkelu',
        feature: 'barkelu',
      ),
      TabConfig(
        id: 'account',
        label: LocalizedText(fr: 'Compte', ar: 'حسابي'),
        type: TabType.native,
        icon: 'person',
        screen: 'account',
        requiresAuth: true,
      ),
    ],
  );
}

/// Compare deux versions `X.Y.Z` (négatif si [a] < [b]).
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
        for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0,
      ];
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
