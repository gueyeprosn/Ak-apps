import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/auth/member.dart';
import '../../core/config/remote_config.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/security/web_allowlist.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_loading_skeleton.dart';
import '../../shared/widgets/ak_photo_hero.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.now});

  /// Injectable pour les tests (période courante).
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final auth = ref.watch(authControllerProvider);
    final member = auth is AuthLoggedIn ? auth.member : null;
    final config =
        ref.watch(configProvider).value?.config ?? MobileConfig.embedded;
    final tabs = config.visibleTabs;
    final contributions = tabs
        .where(
            (tab) => tab.type == TabType.native && tab.screen == 'cotisations')
        .firstOrNull;
    final shop = tabs
        .where((tab) => tab.type == TabType.native && tab.screen == 'barkelu')
        .firstOrNull;
    final period = currentPeriode(now ?? DateTime.now());
    final photo =
        _memberPhoto(member?.photoUrl, ref.watch(appEnvProvider).apiBaseUrl);
    final surface = context.ak.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: akSystemUiStyle(Brightness.dark),
      child: ColoredBox(
        color: AKColors.deep,
        child: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: surface,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AkLayout.contentMax),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom:
                        AkSpace.space6 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HomeMasthead(
                        onAbout: () => context.push('/qui-sommes-nous'),
                        onContact: () => openOfficialDestination(
                          context,
                          ref,
                          Uri.parse(OfficialPage.support.url),
                        ),
                      ),
                      AkPhotoHero(
                        asset: AkAssets.toubaHero,
                        alignment: const Alignment(0, .22),
                        child: _HomeGreeting(member: member, photo: photo),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AkSpace.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AkSpace.space2),
                            if (auth is AuthUnknown)
                              AkLoadingSkeleton(
                                label: l.loading,
                                count: 2,
                                height: 96,
                              )
                            else ...[
                              if (member == null)
                                AkReveal(
                                    stage: 1,
                                    stagger: true,
                                    child: const _VisitorActions())
                              else
                                AkReveal(
                                  stage: 1,
                                  stagger: true,
                                  child: AkContributionCard(
                                    payment: member.versementFor(period),
                                    period: period,
                                    contributionsTabId: contributions?.id,
                                  ),
                                ),
                              const SizedBox(height: AkSpace.space4),
                              AkReveal(
                                stage: 2,
                                stagger: true,
                                child: _HomeServices(
                                  contributionsTabId: contributions?.id,
                                  barkeluTabId: shop?.id,
                                ),
                              ),
                            ],
                            const SizedBox(height: AkSpace.space4),
                            const AkReveal(
                                stage: 3,
                                stagger: true,
                                child: _HomeCommunity()),
                            for (final message in config.messages) ...[
                              const SizedBox(height: AkSpace.space4),
                              AkBanner(
                                tone: message.level == 'warning'
                                    ? AkTone.warning
                                    : AkTone.info,
                                icon: message.level == 'warning'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline,
                                text: message.text.resolve(lang),
                              ),
                            ],
                            if (kDebugMode)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: AkSpace.space12),
                                  child: AkButton(
                                    label: 'Khidmah Immersive — Catalogue',
                                    kind: AkButtonKind.text,
                                    icon: Icons.design_services_outlined,
                                    onPressed: () =>
                                        context.push('/design-catalogue'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _memberPhoto(String? raw, String baseUrl) {
    if (raw == null || raw.trim().isEmpty) return null;
    final origin = Uri.parse(baseUrl);
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final resolved = origin.resolveUri(uri).toString();
    if (!isAllowedWebUrl(resolved, [origin.host])) return null;
    return ResizeImage(NetworkImage(resolved),
        width: 192, allowUpscaling: false);
  }
}

class _HomeMasthead extends StatelessWidget {
  const _HomeMasthead({required this.onAbout, required this.onContact});

  final VoidCallback onAbout;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      color: AKColors.deep,
      child: IconButtonTheme(
        data: const IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(AKColors.ivory),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AkSpace.space2,
            vertical: AkSpace.space1,
          ),
          child: AkReveal(
            slide: false,
            child: Row(
              children: [
                AkIconButton(
                  label: l.aboutTitle,
                  icon: Icons.info_outline,
                  onPressed: onAbout,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AkAssets.logoOfficiel,
                        width: 44,
                        height: 44,
                        cacheWidth: 144,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: AkSpace.space2),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ahloul Khidmah',
                              style: AkText.bodyStrong
                                  .copyWith(color: AKColors.ivory),
                              textDirection: TextDirection.ltr,
                            ),
                            Text(
                              'أهل الخدمة',
                              style: AkText.caption.copyWith(
                                fontFamily: AkFonts.arabic,
                                color: AKColors.goldLight,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AkIconButton(
                  label: l.aboutWhatsApp,
                  icon: Icons.chat_bubble_outline,
                  onPressed: onContact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({required this.member, required this.photo});

  final Member? member;
  final ImageProvider? photo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profile = member;
    final title = profile == null
        ? l.welcomeTitle
        : l.homeGreeting(
            profile.prenoms.isEmpty ? profile.name : profile.prenoms);
    final headline = Semantics(
      header: true,
      child: Text(
        title,
        style: AkText.titleLg.copyWith(color: AKColors.ivory),
      ),
    );
    final detail = Text(
      profile == null ? l.heroSubtitle : l.memberActive,
      style: AkText.bodySm.copyWith(
        color: profile == null ? AKColors.ivory : AKColors.goldLight,
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile?.isActive == true) detail,
              headline,
              if (profile == null) detail,
            ],
          ),
        ),
        if (profile != null) ...[
          const SizedBox(width: AkSpace.space3),
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AKColors.goldLight, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AKColors.deep,
                  foregroundImage: photo,
                  onForegroundImageError: photo == null ? null : (_, __) {},
                  child: profile.initials.isEmpty
                      ? const Icon(Icons.person_outline, color: AKColors.ivory)
                      : Text(
                          profile.initials,
                          style:
                              AkText.bodyStrong.copyWith(color: AKColors.ivory),
                        ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VisitorActions extends StatelessWidget {
  const _VisitorActions();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final join = AkButton(
      key: const Key('home-join'),
      label: l.homeJoin,
      icon: Icons.person_add_outlined,
      onPressed: () => context.push('/join'),
    );
    final give = AkSecondaryButton(
      key: const Key('home-give'),
      label: l.homeContribute,
      icon: Icons.favorite_border,
      onPressed: () => context.push('/give'),
    );
    return Column(
      children: [
        if (MediaQuery.textScalerOf(context).scale(14) >= 21) ...[
          join,
          const SizedBox(height: AkSpace.space2),
          give,
        ] else
          Row(
            children: [
              Expanded(child: join),
              const SizedBox(width: AkSpace.space2),
              Expanded(child: give),
            ],
          ),
        AkButton(
          key: const Key('home-login'),
          kind: AkButtonKind.text,
          label: l.loginButton,
          icon: Icons.login,
          onPressed: () => context.push('/login'),
        ),
      ],
    );
  }
}

class _HomeServices extends StatelessWidget {
  const _HomeServices(
      {required this.contributionsTabId, required this.barkeluTabId});

  final String? contributionsTabId;
  final String? barkeluTabId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) >= 21
            ? 2
            : 3;
        const gap = AkSpace.space2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final contributions = contributionsTabId;
        final shop = barkeluTabId;
        final services = <AKServiceCard>[
          AKServiceCard(
            label: l.actionCard,
            icon: Icons.badge_outlined,
            onTap: () => context.push('/card'),
          ),
          AKServiceCard(
            label: l.contributionsLabel,
            icon: Icons.payments_outlined,
            goldAccent: true,
            onTap: () {
              if (contributions != null) {
                context.go('/t/$contributions');
              } else {
                context.push('/pay');
              }
            },
          ),
          if (shop != null)
            AKServiceCard(
              label: l.actionBarkelu,
              icon: Icons.shopping_bag_outlined,
              goldAccent: true,
              onTap: () => context.go('/t/$shop'),
            ),
          AKServiceCard(
            label: l.homeJoin,
            icon: Icons.group_outlined,
            onTap: () => context.push('/join'),
          ),
          AKServiceCard(
            label: l.actionContribute,
            icon: Icons.favorite_border,
            goldAccent: true,
            onTap: () => context.push('/give'),
          ),
          AKServiceCard(
            label: l.mediaLabel,
            icon: Icons.photo_library_outlined,
            onTap: () => context.push('/media'),
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final service in services)
              SizedBox(width: width, child: service),
          ],
        );
      },
    );
  }
}

class _HomeCommunity extends StatelessWidget {
  const _HomeCommunity();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void openGallery() => context.push('/media');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = AkHeading(title: l.galleryTitle, section: true);
            final action = AkButton(
              label: l.galleryOpen,
              kind: AkButtonKind.text,
              expand: false,
              onPressed: openGallery,
            );
            if (MediaQuery.textScalerOf(context).scale(14) >= 21 ||
                constraints.maxWidth < 300) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, action],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                Flexible(
                    child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: action)),
              ],
            );
          },
        ),
        AKNewsCard(
          title: l.galleryPhoto2,
          imageAsset: AkAssets.gallery[2],
          onTap: openGallery,
        ),
      ],
    );
  }
}

class AkContributionCard extends StatelessWidget {
  const AkContributionCard({
    super.key,
    required this.payment,
    required this.period,
    required this.contributionsTabId,
  });

  final Versement? payment;
  final String period;
  final String? contributionsTabId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = context.ak;
    final payment = this.payment;
    final (label, tone, icon) = switch (payment?.isPaid) {
      null => (l.statusDue, AkTone.warning, Icons.schedule),
      true => (l.statusUpToDate, AkTone.success, Icons.check_circle_outline),
      false => (l.statusPending, AkTone.warning, Icons.schedule),
    };
    final (action, actionIcon, onTap) = switch (payment?.isPaid) {
      null => (l.actionPay, Icons.payment_outlined, () => context.push('/pay')),
      false when contributionsTabId != null => (
          l.versementsTitle,
          Icons.receipt_long_outlined,
          () => context.go('/t/$contributionsTabId'),
        ),
      _ => (l.actionCard, Icons.badge_outlined, () => context.push('/card')),
    };

    return AkRaisedCard(
      child: Padding(
        padding: const EdgeInsets.all(AkSpace.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AkSpace.space2,
              runSpacing: AkSpace.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l.dueCardTitle(periodeLabel(period, lang)),
                    style: AkText.bodyStrong),
                StatusChip(label: label, tone: tone, icon: icon),
              ],
            ),
            if (payment != null) ...[
              const SizedBox(height: AkSpace.space1),
              Text(
                formatAmount(payment.montant, lang),
                style: AkText.amount
                    .copyWith(color: p.ink, fontSize: 24, height: 1.2),
              ),
            ],
            const SizedBox(height: AkSpace.space2),
            AkButton(
              label: action,
              kind: AkButtonKind.gold,
              icon: actionIcon,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
