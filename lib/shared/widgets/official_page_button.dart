import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'ak_widgets.dart';

enum OfficialPage {
  media('https://www.ahloulkhidmah.org/mediatheque'),
  shop('https://www.ahloulkhidmah.org/boutique'),
  account('https://www.ahloulkhidmah.org/mon-espace'),
  history('https://www.ahloulkhidmah.org/mon-espace/historique'),
  support('https://wa.me/221752282828');

  const OfficialPage(this.url);
  final String url;
}

final officialPageLauncherProvider =
    Provider<Future<bool> Function(Uri)>((ref) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

/// Les destinations sont connues à la compilation. Le navigateur ouvre la
/// page avec sa propre session web, sans jeton de l’application.
class OfficialPageButton extends ConsumerWidget {
  const OfficialPageButton({
    super.key,
    required this.page,
    required this.label,
    this.productSlug,
    this.icon = Icons.open_in_new,
    this.kind = AkButtonKind.outline,
  });

  final OfficialPage page;
  final String label;
  final String? productSlug;
  final IconData icon;
  final AkButtonKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AkButton(
        label: label,
        icon: icon,
        kind: kind,
        onPressed: () async {
          var opened = false;
          try {
            final slug = productSlug;
            final uri = page == OfficialPage.shop && slug != null
                ? Uri.https('www.ahloulkhidmah.org', '/boutique/produits/$slug')
                : Uri.parse(page.url);
            opened = await ref.read(officialPageLauncherProvider)(uri);
          } catch (_) {
            // Certains appareils n'ont aucune application pour ouvrir le lien.
          }
          if (opened || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context).officialPageError)),
          );
        },
      );
}
