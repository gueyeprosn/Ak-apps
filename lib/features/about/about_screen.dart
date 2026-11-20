import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_brand_app_bar.dart';
import '../../shared/widgets/ak_photo_hero.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';
import 'whatsapp_fab.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = context.ak;
    final pillars = [
      (Icons.groups_outlined, l.aboutMobilize, l.aboutMobilizeBody),
      (Icons.account_tree_outlined, l.aboutOrganize, l.aboutOrganizeBody),
      (Icons.volunteer_activism_outlined, l.aboutFund, l.aboutFundBody),
      (Icons.eco_outlined, l.aboutImpact, l.aboutImpactBody),
    ];

    return Scaffold(
      appBar: AkBrandAppBar(context: context, title: l.aboutTitle),
      floatingActionButton: const WhatsAppFab(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
            child: ListView(
              padding: akPagePadding.copyWith(
                bottom: AkSpace.space12 + AkSpace.space8,
              ),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AkRadius.radiusXl),
                  child: AkPhotoHero(
                    asset: AkAssets.toubaVision,
                    minHeight: 208,
                    topPadding: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l.aboutHeroTitle,
                            style:
                                AkText.titleLg.copyWith(color: AKColors.ivory),
                          ),
                        ),
                        const SizedBox(height: AkSpace.space1),
                        Text(
                          l.aboutHeroBody,
                          style: AkText.bodySm.copyWith(color: AKColors.ivory),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AkSpace.space3),
                AkReveal(
                  stage: 1,
                  stagger: true,
                  child: AkRaisedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AkSpace.space4),
                      child: AkHeading(
                        title: l.aboutMissionTitle,
                        subtitle: l.aboutMissionBody,
                        section: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AkSpace.space6),
                AkHeading(title: l.aboutPillarsTitle, section: true),
                const SizedBox(height: AkSpace.space3),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useGrid = constraints.maxWidth >= AkLayout.compact &&
                        MediaQuery.textScalerOf(context).scale(14) < 21;
                    final width = useGrid
                        ? (constraints.maxWidth - AkSpace.space3) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: AkSpace.space3,
                      runSpacing: AkSpace.space3,
                      children: [
                        for (final (icon, title, body) in pillars)
                          SizedBox(
                            width: width,
                            child: AkRaisedCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AkSpace.space4),
                                child: AkHeading(
                                  title: title,
                                  subtitle: body,
                                  icon: icon,
                                  section: true,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AkSpace.space6),
                AkHeading(
                  title: l.aboutContacts,
                  subtitle: l.aboutLocation,
                  section: true,
                ),
                const SizedBox(height: AkSpace.space3),
                AkRaisedCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            Icon(Icons.chat_outlined, color: palette.primary),
                        title: const Text('WhatsApp'),
                        subtitle: const Text(
                          '+221 75 228 28 28',
                          textDirection: TextDirection.ltr,
                        ),
                        onTap: () => openOfficialDestination(
                          context,
                          ref,
                          Uri.parse(OfficialPage.support.url),
                        ),
                      ),
                      Divider(height: 1, color: palette.border),
                      ListTile(
                        leading:
                            Icon(Icons.mail_outline, color: palette.primary),
                        title: Text(l.aboutEmail),
                        subtitle: Text(
                          Uri.parse(OfficialPage.email.url).path,
                          textDirection: TextDirection.ltr,
                        ),
                        onTap: () => openOfficialDestination(
                          context,
                          ref,
                          Uri.parse(OfficialPage.email.url),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AkSpace.space4),
                OfficialPageButton(
                  page: OfficialPage.about,
                  label: l.aboutReadOfficial,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
