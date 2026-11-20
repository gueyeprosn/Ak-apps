import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_image_viewer.dart';
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
      appBar: AppBar(
        title: Text(l.cardTitle),
      ),
      body: SafeArea(
        child: switch (s.status) {
          CardStatus.loading =>
            Center(child: CircularProgressIndicator(semanticsLabel: l.loading)),
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
              builder: (context, constraints) => ListView(
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
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: (constraints.maxHeight * 0.60)
                                  .clamp(200.0, 560.0) *
                              2 /
                              3),
                      child: AkMembershipCard(
                        image: MemoryImage(s.image!.bytes),
                        label: l.cardImageLabel(member?.name ?? ''),
                        expandLabel: l.cardFullScreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: AkSpace.space3),
                  if (member?.isActive ?? false) ...[
                    Center(
                        child: StatusChip(
                            label: l.memberActive,
                            tone: AkTone.success,
                            icon: Icons.check_circle_outline)),
                    const SizedBox(height: AkSpace.space2),
                  ],
                  Text(l.cardHint,
                      style: AkText.bodySm.copyWith(color: p.inkSoft),
                      textAlign: TextAlign.center),
                  if (s.shareFailed) ...[
                    const SizedBox(height: AkSpace.space2),
                    Semantics(
                      liveRegion: true,
                      child: Text(l.cardShareFailed,
                          key: const Key('share-failed'),
                          style: AkText.bodySm.copyWith(color: p.danger)),
                    ),
                  ],
                  const SizedBox(height: AkSpace.space4),
                  AkButton(
                    key: const Key('share-card'),
                    label: l.cardShare,
                    icon: Icons.ios_share,
                    loading: s.sharing,
                    onPressed: c.share,
                  ),
                ],
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
    return AkReveal(
      child: TextButton(
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
