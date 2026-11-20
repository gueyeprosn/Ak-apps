import 'package:flutter/material.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/assets/ak_assets.dart';
import '../../core/theme/ak_immersive.dart';

/// Surface de contenu avec un léger relief sur le fond de page.
class AkRaisedCard extends StatelessWidget {
  const AkRaisedCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AkRadius.radiusLg),
      side: BorderSide(color: p.border),
    );

    Widget surface(Widget content) => DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            shadows: [
              BoxShadow(
                color: p.scrim.withValues(alpha: .09),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: p.surfaceRaised,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        );

    final tap = onTap;
    if (tap == null) return surface(child);
    return AkAnimatedButton(
      builder: (states) => surface(
        Semantics(
          button: true,
          child: InkWell(
            statesController: states,
            onTap: tap,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Raccourci de service en grille.
class AKServiceCard extends StatelessWidget {
  const AKServiceCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.goldAccent = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool goldAccent;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return AkRaisedCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AkSpace.space1,
            vertical: AkSpace.space2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: goldAccent ? p.warningBg : p.surfaceTint,
                  borderRadius: BorderRadius.circular(AkRadius.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AkSpace.space2),
                  child: Icon(
                    icon,
                    color: goldAccent ? p.warning : p.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: AkSpace.space1),
              Text(
                label,
                style: AkText.caption.copyWith(color: p.ink),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte illustrée ouvrant son contenu dans la médiathèque.
class AKNewsCard extends StatelessWidget {
  const AKNewsCard({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return AkRaisedCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AkSpace.space2),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AkRadius.radiusMd),
              child: Image.asset(
                imageAsset,
                width: 88,
                height: 64,
                fit: BoxFit.cover,
                cacheWidth: 288,
                excludeFromSemantics: true,
                frameBuilder: (context, image, frame, synchronouslyLoaded) =>
                    synchronouslyLoaded || frame != null
                        ? image
                        : SizedBox(
                            width: 88,
                            height: 64,
                            child: ColoredBox(color: p.surfaceSunken),
                          ),
              ),
            ),
            const SizedBox(width: AkSpace.space3),
            Expanded(
              child: Text(
                title,
                style: AkText.bodyStrong.copyWith(color: p.ink),
              ),
            ),
            const SizedBox(width: AkSpace.space2),
            ExcludeSemantics(
              child: Icon(Icons.chevron_right, color: p.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte membre numérique officielle « Khidmah Immersive ».
class AKMemberCard extends StatelessWidget {
  const AKMemberCard({
    super.key,
    required this.memberName,
    required this.memberId,
    this.photoUrl,
    this.photoAsset,
    this.isActive = true,
    this.validUntil = '31 déc. 2025',
    this.onTap,
  });

  final String memberName;
  final String memberId;
  final String? photoUrl;
  final String? photoAsset;
  final bool isActive;
  final String validUntil;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AkRadius.radiusXl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064C3B),
            Color(0xFF085B47),
            Color(0xFF043427),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064C3B).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motifs géométriques dorés en filigrane
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                AkAssets.logoOfficiel,
                width: 220,
                height: 220,
              ),
            ),
          ),
          // Silhouette de la mosquée en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: CustomPaint(
              painter: _GoldWavePainter(),
            ),
          ),
          // Contenu de la carte
          Padding(
            padding: const EdgeInsets.all(AkSpace.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête de la carte
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        AkAssets.logoOfficiel,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AkSpace.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ahloul Khidmah',
                            style: TextStyle(
                              fontFamily: AkFonts.display,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AKColors.ivory,
                            ),
                          ),
                          Text(
                            'أهل الخدمة',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: AkFonts.sans,
                              fontSize: 12,
                              color: AKColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Carte de membre',
                          style: TextStyle(
                            fontFamily: AkFonts.sans,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AKColors.goldLight,
                          ),
                        ),
                        Text(
                          'بطاقة عضو',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: AkFonts.sans,
                            fontSize: 10,
                            color: AKColors.ivory.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AkSpace.space5),
                // Corps de la carte : Photo + Infos + QR Code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Photo de membre avec cadre doré
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AKColors.gold, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoAsset != null
                          ? Image.asset(photoAsset!, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFF0B5844),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: AKColors.gold,
                              ),
                            ),
                    ),
                    const SizedBox(width: AkSpace.space4),
                    // Nom et numéro de membre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: TextStyle(
                              fontFamily: AkFonts.sans,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AKColors.ivory,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "N° d'adhérent",
                            style: TextStyle(
                              fontFamily: AkFonts.sans,
                              fontSize: 11,
                              color: AKColors.ivory.withValues(alpha: 0.65),
                            ),
                          ),
                          Text(
                            memberId,
                            style: TextStyle(
                              fontFamily: AkFonts.sans,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AKColors.gold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AkSpace.space1),
                          // Badge actif
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AkSpace.space2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF087A58),
                              borderRadius:
                                  BorderRadius.circular(AkRadius.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  isActive ? 'Actif' : 'Inactif',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AkSpace.space2),
                    // QR Code vérifiable
                    Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AkRadius.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _MockQrCodePainter(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkSpace.space4),
                // Bas de carte : date de validité
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AKColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valide jusqu’au $validUntil',
                          style: TextStyle(
                            fontFamily: AkFonts.sans,
                            fontSize: 11,
                            color: AKColors.ivory.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Peintre de la vague dorée en bas de carte
class _GoldWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00D6A84D), Color(0x55D6A84D), Color(0x99D6A84D)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.1,
        size.width * 0.7,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.6,
        size.width,
        size.height * 0.2,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Peintre de motif QR Code net
class _MockQrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final w = size.width / 9;

    // Coins repères (Position Detection Patterns)
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, w * 3, w * 3), paint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(x + w, y + w, w, w), whitePaint);
    }

    drawFinder(0, 0);
    drawFinder(size.width - w * 3, 0);
    drawFinder(0, size.height - w * 3);

    // Modules intérieurs
    final points = [
      Offset(4 * w, 1 * w),
      Offset(4 * w, 2 * w),
      Offset(4 * w, 4 * w),
      Offset(1 * w, 4 * w),
      Offset(2 * w, 4 * w),
      Offset(3 * w, 4 * w),
      Offset(5 * w, 4 * w),
      Offset(6 * w, 4 * w),
      Offset(7 * w, 4 * w),
      Offset(4 * w, 6 * w),
      Offset(4 * w, 7 * w),
      Offset(6 * w, 6 * w),
      Offset(7 * w, 6 * w),
      Offset(6 * w, 7 * w),
      Offset(2 * w, 5 * w),
      Offset(5 * w, 2 * w),
      Offset(7 * w, 3 * w),
    ];
    for (final p in points) {
      canvas.drawRect(Rect.fromLTWH(p.dx, p.dy, w, w), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carte produit de la boutique Barkelu (Maquette 1 & 2).
class AKProductCard extends StatelessWidget {
  const AKProductCard({
    super.key,
    required this.title,
    required this.price,
    this.imageAsset,
    this.imageUrl,
    this.category,
    required this.onTap,
    this.onAddToCart,
    this.isFavorite = false,
  });

  final String title;
  final String price;
  final String? imageAsset;
  final String? imageUrl;
  final String? category;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return AkAnimatedButton(
      builder: (states) => Material(
        color: p.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkRadius.radiusLg),
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec bouton favori
              Stack(
                children: [
                  Container(
                    height: 128,
                    width: double.infinity,
                    color: const Color(0xFFF0EAE1),
                    child: imageAsset != null
                        ? Image.asset(imageAsset!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            size: 48,
                            color: AKColors.gold,
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? AKColors.alert : p.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AkSpace.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AkText.bodyStrong.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AkSpace.space2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontFamily: AkFonts.sans,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AKColors.deep,
                          ),
                        ),
                        InkWell(
                          onTap: onAddToCart,
                          borderRadius:
                              BorderRadius.circular(AkRadius.radiusSm),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AKColors.gold,
                              borderRadius:
                                  BorderRadius.circular(AkRadius.radiusSm),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                              color: AKColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
