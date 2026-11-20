import 'package:ahloulkhidmah_mobile/features/barkelu/barkelu_screen.dart';
import 'package:ahloulkhidmah_mobile/features/media/media_screen.dart';
import 'package:ahloulkhidmah_mobile/l10n/app_localizations.dart';
import 'package:ahloulkhidmah_mobile/shared/widgets/ak_image_viewer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_adapter.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('Barkelu et galerie restent utilisables en arabe à 200 %',
      (tester) async {
    const product = 'حقيبة قماشية من متجر أهل الخدمة';
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(
      tester,
      width: 320,
      textScale: 2,
      prefs: {'pref.lang': 'ar', 'pref.theme': 'dark'},
      routes: {
        'GET /api/mobile/v1/config': (_) => FakeReply(200, configJson()),
        'GET /api/store/categories': (_) => const FakeReply(200, {
              'categories': [
                {'name': 'المنسوجات', 'slug': 'textile'},
              ],
            }),
        'GET /api/store/products': (_) => const FakeReply(200, {
              'products': [
                {'name': product, 'price': 4000},
                {'name': 'كتاب', 'price': 5000},
              ],
            }),
      },
    );
    await tester.tap(findTab('Barkelu'));
    await tester.pumpAndSettle();
    final shop = find.byType(BarkeluScreen);
    final shopContext = tester.element(shop);
    expect(Directionality.of(shopContext), TextDirection.rtl);
    final l = AppLocalizations.of(shopContext);
    final cards = find.byType(AkProductCard);
    await tester.scrollUntilVisible(
      find.text(product),
      150,
      scrollable:
          find.descendant(of: shop, matching: find.byType(Scrollable)).first,
    );
    expect(cards, findsNWidgets(2));
    expect(tester.getTopLeft(cards.first).dx, tester.getTopLeft(cards.last).dx);
    await tester.ensureVisible(cards.first);
    await tester.pumpAndSettle();
    await tester.tap(cards.first.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text(l.shopWebCheckout), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(findTab('الرئيسية'));
    await tester.pumpAndSettle();
    final media = find.text(l.mediaLabel);
    await tester.scrollUntilVisible(media, 150);
    await tester.pumpAndSettle();
    await tester.tap(media.hitTestable());
    await tester.pumpAndSettle();
    final gallery = find.byType(MediaScreen);
    expect(Directionality.of(tester.element(gallery)), TextDirection.rtl);
    final featured = find.text(l.galleryPhoto2);
    await tester.scrollUntilVisible(
      featured,
      150,
      scrollable:
          find.descendant(of: gallery, matching: find.byType(Scrollable)).first,
    );
    final featuredCard = find.widgetWithText(AkNewsCard, l.galleryPhoto2);
    await tester.ensureVisible(featuredCard);
    await tester.pumpAndSettle();
    await tester.tap(featuredCard.hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(AkImageViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
