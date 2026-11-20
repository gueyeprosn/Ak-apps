import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/theme/ak_immersive.dart';
import '../../shared/widgets/ak_widgets.dart';

/// En-tête de marque et formulaire communs aux deux étapes de l'accès membre.
class AccessScaffold extends StatelessWidget {
  const AccessScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 76,
        backgroundColor: AKColors.deep,
        foregroundColor: AKColors.ivory,
        systemOverlayStyle: akSystemUiStyle(Brightness.dark),
        surfaceTintColor: Colors.transparent,
        title: const Image(
          image: AssetImage(AkAssets.logoOfficiel),
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AKColors.emeraldGradient),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AkSpace.space1),
          child: SizedBox(
            height: AkSpace.space1,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AKColors.goldGradient),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: akPagePadding,
              child: AkReveal(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AkRaisedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AkSpace.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: AkText.headline,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AkSpace.space2),
                            Text(
                              subtitle,
                              style: AkText.bodySm.copyWith(
                                color: context.ak.inkSoft,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AkSpace.space5),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                    if (footer.isNotEmpty) ...[
                      const SizedBox(height: AkSpace.space2),
                      ...footer,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
