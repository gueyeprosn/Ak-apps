import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/official_page_button.dart';

class WhatsAppFab extends ConsumerWidget {
  const WhatsAppFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FloatingActionButton(
        heroTag: null,
        tooltip: AppLocalizations.of(context).aboutWhatsApp,
        backgroundColor: AKColors.deep,
        foregroundColor: AKColors.ivory,
        onPressed: () => openOfficialDestination(
          context,
          ref,
          Uri.parse(OfficialPage.support.url),
        ),
        child: const Icon(Icons.chat_outlined),
      );
}
