import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/api/api_error.dart';
import '../../core/auth/member.dart';
import '../../core/providers.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_brand_app_bar.dart';
import '../../shared/widgets/ak_image_viewer.dart';
import '../../shared/widgets/ak_loading_skeleton.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';
import 'card_controller.dart';

/// Carte membre numérique : l'image générée par le serveur, affichée telle
/// quelle. Utilisable sans réseau grâce à la copie locale.
class CardScreen extends ConsumerStatefulWidget {
  const CardScreen({super.key});

  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cardControllerProvider.notifier).load());
  }

  void _showDetails(BuildContext context, Member member) {
    final l = AppLocalizations.of(context);
    showAkBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: akPagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AkHeading(title: l.cardDetails),
              if (member.name.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(member.name),
                ),
              if (member.id.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(member.id, textDirection: TextDirection.ltr),
                ),
              if (member.isActive)
                StatusChip(
                  label: l.memberActive,
                  tone: AkTone.success,
                  icon: Icons.check_circle_outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = context.ak;
    final s = ref.watch(cardControllerProvider);
    final c = ref.read(cardControllerProvider.notifier);
    final error = s.error;
    final offline = error is ApiException && error.isNetwork;
    final missingRoute = error is ApiException && error.status == 404;
    final webAccount =
        OfficialPageButton(page: OfficialPage.account, label: l.accountOpenWeb);
    final auth = ref.watch(authControllerProvider);
    final member = auth is AuthLoggedIn ? auth.member : null;

    return Scaffold(
      appBar: AkBrandAppBar(
        context: context,
        title: l.cardTitle,
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (s.status) {
          CardStatus.loading => LayoutBuilder(
              builder: (context, constraints) => Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AkSpace.space4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: AkLoadingSkeleton(
                      label: l.loading,
                      count: 1,
                      height: constraints.maxHeight * .55,
                    ),
                  ),
                ),
              ),
            ),
          CardStatus.unavailable => StateView(
              icon: Icons.badge_outlined,
              tone: AkTone.warning,
              title: l.cardUnavailableTitle,
              body: l.cardUnavailableBody,
              secondaryAction: webAccount,
            ),
          CardStatus.error => StateView(
              icon: offline ? Icons.wifi_off : Icons.badge_outlined,
              tone: AkTone.warning,
              title: l.cardUnavailableTitle,
              body: missingRoute
                  ? l.cardMobileUnavailable
                  : offline
                      ? l.cardLoadFailedBody
                      : l.genericError,
              actionLabel: missingRoute ? null : l.retryButton,
              onAction: missingRoute ? null : c.load,
              secondaryAction: webAccount,
            ),
          CardStatus.ready => LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AkLayout.contentMax),
                  child: ListView(
                    padding: akPagePadding,
                    children: [
                      if (s.stale) ...[
                        AkBanner(
                          tone: AkTone.warning,
                          icon: Icons.wifi_off,
                          text: l.cardStaleBanner(
                              DateFormat.yMMMd(lang).format(s.image!.savedAt)),
                        ),
                        const SizedBox(height: AkSpace.space3),
                      ],
                      AkReveal(
                        child: AkRaisedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AkSpace.space4),
                            child: Column(
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: (constraints.maxHeight * .39)
                                        .clamp(128.0, 320.0),
                                  ),
                                  child: AkMembershipCard(
                                    image: MemoryImage(s.image!.bytes),
                                    label: l.cardImageLabel(member?.name ?? ''),
                                    expandLabel: l.cardFullScreen,
                                  ),
                                ),
                                const SizedBox(height: AkSpace.space4),
                                if (member?.isActive ?? false) ...[
                                  StatusChip(
                                    label: l.memberActive,
                                    tone: AkTone.success,
                                    icon: Icons.check_circle_outline,
                                  ),
                                  const SizedBox(height: AkSpace.space2),
                                ],
                                Text(
                                  l.cardHint,
                                  style:
                                      AkText.bodySm.copyWith(color: p.inkSoft),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (s.shareFailed) ...[
                        const SizedBox(height: AkSpace.space3),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l.cardShareFailed,
                            key: const Key('share-failed'),
                            style: AkText.bodySm.copyWith(color: p.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: AkSpace.space4),
                      AkReveal(
                        stage: 1,
                        stagger: true,
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AkSpace.space3,
                            runSpacing: AkSpace.space3,
                            children: [
                              AkButton(
                                key: const Key('share-card'),
                                label: l.cardShare,
                                kind: AkButtonKind.gold,
                                icon: Icons.ios_share,
                                loading: s.sharing,
                                expand: false,
                                onPressed: c.share,
                              ),
                              if (member != null)
                                AkButton(
                                  label: l.cardDetails,
                                  icon: Icons.info_outline,
                                  kind: AkButtonKind.outline,
                                  expand: false,
                                  onPressed: () =>
                                      _showDetails(context, member),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }
}

/// Le badge officiel est affiché à son ratio serveur 1024 × 1536.
class AkMembershipCard extends StatelessWidget {
  const AkMembershipCard(
      {super.key,
      required this.image,
      required this.label,
      required this.expandLabel});

  final ImageProvider image;
  final String label;
  final String expandLabel;

  @override
  Widget build(BuildContext context) {
    final tag = image;
    return AkAnimatedButton(
      builder: (states) => TextButton(
        statesController: states,
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero, minimumSize: Size.zero),
        onPressed: () => AkImageViewer.open(
          context,
          AkImageViewer(
              image: image, title: label, heroTag: tag, aspectRatio: 2 / 3),
        ),
        child: Semantics(
          label: expandLabel,
          child: HeroMode(
            enabled: !MediaQuery.disableAnimationsOf(context),
            child: Hero(
              tag: tag,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Image(
                  image: image,
                  key: const Key('card-image'),
                  semanticLabel: label,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
