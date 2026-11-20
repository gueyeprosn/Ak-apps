import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'ak_widgets.dart';

enum OfficialPage {
  about('https://www.ahloulkhidmah.org/qui-sommes-nous'),
  email('mailto:contact@ahloulkhidmah.org'),
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

Future<void> openOfficialDestination(
  BuildContext context,
  WidgetRef ref,
  Uri uri,
) async {
  var opened = false;
  try {
    opened = await ref.read(officialPageLauncherProvider)(uri);
  } catch (_) {
    // Une application compatible peut manquer sur cet appareil.
  }
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).officialPageError)),
  );
}

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
          final slug = productSlug;
          final uri = page == OfficialPage.shop && slug != null
              ? Uri.https('www.ahloulkhidmah.org', '/boutique/produits/$slug')
              : Uri.parse(page.url);
          await openOfficialDestination(context, ref, uri);
        },
      );
}
