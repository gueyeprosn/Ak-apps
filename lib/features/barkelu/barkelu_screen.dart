import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/api/api_error.dart';
import '../../core/config/remote_config.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/security/web_allowlist.dart';
import '../../core/theme/ak_immersive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_loading_skeleton.dart';
import '../../shared/widgets/ak_service_tile.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';
import 'data/catalogue_repository.dart';
import 'domain/product.dart';

class BarkeluScreen extends ConsumerStatefulWidget {
  const BarkeluScreen({super.key});

  @override
  ConsumerState<BarkeluScreen> createState() => _BarkeluScreenState();
}

class _BarkeluScreenState extends ConsumerState<BarkeluScreen> {
  final _searchField = TextEditingController();
  final _scroll = ScrollController();
  CatalogueQuery _query = (search: '', category: null, page: 1);

  @override
  void dispose() {
    _searchField.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _search(String text) => setState(() {
        _query = (search: text.trim(), category: _query.category, page: 1);
      });

  void _page(int page) {
    setState(() => _query =
        (search: _query.search, category: _query.category, page: page));
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentProducts = productsProvider(_query);
    final catalogue = ref.watch(currentProducts);
    final categories =
        ref.watch(shopCategoriesProvider).valueOrNull ?? const [];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AkLayout.contentMax),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shopCategoriesProvider);
              ref.invalidate(currentProducts);
              try {
                await ref.read(currentProducts.future);
              } catch (_) {
                // L’état de l’API est affiché dans la liste.
              }
            },
            child: ListView(
              controller: _scroll,
              padding: akPagePadding,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AkHeading(
                    title: l.actionBarkelu, icon: Icons.shopping_bag_outlined),
                const SizedBox(height: AkSpace.space3),
                TextField(
                  controller: _searchField,
                  textInputAction: TextInputAction.search,
                  maxLength: 80,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    labelText: l.shopSearch,
                    counterText: '',
                    border: const OutlineInputBorder(),
                    suffixIcon: AkIconButton(
                      label: l.shopSearch,
                      onPressed: () => _search(_searchField.text),
                      icon: Icons.search,
                    ),
                  ),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: AkSpace.space2),
                  Wrap(
                    spacing: AkSpace.space2,
                    children: [
                      for (final category in categories)
                        FilterChip(
                          label: Text(category.name),
                          selected: _query.category == category.slug,
                          onSelected: (selected) => setState(() => _query = (
                                search: _query.search,
                                category: selected ? category.slug : null,
                                page: 1,
                              )),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AkSpace.space3),
                ...catalogue.when(
                  loading: () => [AkLoadingSkeleton(label: l.loading)],
                  error: (error, _) => [
                    AkBanner(
                      tone: AkTone.warning,
                      icon: error is ApiException && error.isNetwork
                          ? Icons.wifi_off
                          : Icons.error_outline,
                      text: error is ApiException && error.isNetwork
                          ? l.networkError
                          : l.genericError,
                    ),
                    const SizedBox(height: AkSpace.space3),
                    AkButton(
                        label: l.retryButton,
                        onPressed: () => ref.invalidate(currentProducts)),
                  ],
                  data: (data) => [
                    if (data.products.isEmpty)
                      AkCard(
                        child: _query.search.isEmpty && _query.category == null
                            ? AkHeading(
                                title: l.comingSoon,
                                subtitle: l.barkeluSoonBody,
                                section: true)
                            : Text(l.shopNoMatches),
                      ),
                    for (final product in data.products) ...[
                      AkProductCard(
                          product: product,
                          onTap: () => _showProduct(context, product)),
                      const SizedBox(height: AkSpace.space3),
                    ],
                    if (_query.page > 1 || data.hasNext)
                      Wrap(
                        spacing: AkSpace.space2,
                        children: [
                          if (_query.page > 1)
                            AkButton(
                                label: l.onboardingBack,
                                expand: false,
                                kind: AkButtonKind.outline,
                                onPressed: () => _page(_query.page - 1)),
                          if (data.hasNext)
                            AkButton(
                                label: l.onboardingNext,
                                expand: false,
                                kind: AkButtonKind.outline,
                                onPressed: () => _page(_query.page + 1)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AkSpace.space3),
                OfficialPageButton(
                    page: OfficialPage.shop, label: l.shopOpenWeb),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProduct(BuildContext context, Product product) {
    final slug = product.slug;
    if (slug == null) {
      showAkBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
          padding: akPagePadding,
          child: _ProductDetails(product: product),
        )),
      );
      return;
    }
    Navigator.of(context).push<void>(AkPageTransition<void>(
      context: context,
      pageKey: ValueKey(slug),
      child: _ProductScreen(product: product, slug: slug),
    ).createRoute(context));
  }
}

class AkProductCard extends ConsumerWidget {
  const AkProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = _productImage(ref, product.coverUrl);
    final slug = product.slug;
    if (image == null) {
      return AkCard(
          padding: EdgeInsets.zero,
          child: AkServiceTile(
            icon: Icons.shopping_bag_outlined,
            label: product.name,
            onTap: onTap,
            subtitle: _price(context, product),
          ));
    }
    return AkCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductPhoto(image: image, tag: slug),
            Padding(
              padding: const EdgeInsets.all(AkSpace.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AkText.bodyStrong),
                  if (product.price != null) Text(_price(context, product)!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductScreen extends ConsumerWidget {
  const _ProductScreen({required this.product, required this.slug});

  final Product product;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final details = ref.watch(productDetailsProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SafeArea(
        child: ListView(
          padding: akPagePadding,
          children: [
            if (_productImage(
                    ref, product.coverUrl ?? details.valueOrNull?.coverUrl)
                case final image?)
              ClipRRect(
                borderRadius: BorderRadius.circular(AkRadius.radiusLg),
                child: _ProductPhoto(image: image, tag: slug),
              ),
            const SizedBox(height: AkSpace.space4),
            _ProductDetails(product: details.valueOrNull ?? product),
            if (details.isLoading) ...[
              const SizedBox(height: AkSpace.space3),
              AkLoadingSkeleton(label: l.loading, count: 1),
            ] else if (details.hasError) ...[
              const SizedBox(height: AkSpace.space3),
              AkBanner(
                  tone: AkTone.warning,
                  icon: Icons.error_outline,
                  text: details.error is ApiException &&
                          (details.error as ApiException).isNetwork
                      ? l.networkError
                      : l.genericError),
              AkButton(
                  label: l.retryButton,
                  kind: AkButtonKind.text,
                  onPressed: () =>
                      ref.invalidate(productDetailsProvider(slug))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AkHeading(title: product.name, subtitle: product.category),
        if (product.price != null)
          Text(_price(context, product)!, style: AkText.amount),
        if (product.description case final description?
            when description.trim().isNotEmpty) ...[
          const SizedBox(height: AkSpace.space3),
          Text(description),
        ],
        for (final variant in product.variants)
          Padding(
            padding: const EdgeInsets.only(top: AkSpace.space2),
            child:
                Text('${variant.label} · ${formatAmount(variant.price, lang)}'),
          ),
        const SizedBox(height: AkSpace.space4),
        Text(l.shopWebCheckout),
        const SizedBox(height: AkSpace.space3),
        OfficialPageButton(
          page: OfficialPage.shop,
          productSlug: product.slug,
          label: l.shopOpenWeb,
          kind: AkButtonKind.primary,
        ),
      ],
    );
  }
}

class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({required this.image, required this.tag});

  final String image;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final photo = AspectRatio(
      aspectRatio: 2,
      child: LayoutBuilder(
          builder: (context, constraints) => Image.network(
                image,
                fit: BoxFit.cover,
                cacheWidth: (constraints.maxWidth *
                        MediaQuery.devicePixelRatioOf(context))
                    .clamp(360, 1440)
                    .round(),
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: context.ak.surfaceSunken,
                  child: const Center(
                      child: Icon(Icons.image_not_supported_outlined)),
                ),
              )),
    );
    return tag == null || MediaQuery.disableAnimationsOf(context)
        ? photo
        : Hero(tag: tag!, child: photo);
  }
}

String? _price(BuildContext context, Product product) => product.price == null
    ? null
    : formatAmount(
        product.price!, Localizations.localeOf(context).languageCode);

String? _productImage(WidgetRef ref, String? cover) {
  if (cover == null) return null;
  final origin = Uri.parse(ref.watch(appEnvProvider).apiBaseUrl);
  final source = Uri.tryParse(cover);
  if (source == null) return null;
  final url = origin.resolveUri(source).toString();
  final config =
      ref.watch(configProvider).value?.config ?? MobileConfig.embedded;
  return isAllowedWebUrl(url, [origin.host, ...config.webAllowlist])
      ? url
      : null;
}
