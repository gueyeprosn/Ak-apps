import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/providers.dart';
import '../domain/product.dart';

final productsProvider = FutureProvider.autoDispose
    .family<CataloguePage, CatalogueQuery>((ref, query) {
  final client = ref.watch(apiClientsProvider).plain;
  return guardApi(() async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/store/products',
      queryParameters: {
        if (query.search.isNotEmpty) 'q': query.search,
        if (query.category case final slug?) 'categorie': slug,
        if (query.page > 1) 'page': query.page,
      },
    );
    final data = response.data;
    final items = data?['products'];
    if (items is! List) throw const FormatException('Catalogue incomplet');
    final total = data?['total'];
    final pageSize = data?['pageSize'];
    return CataloguePage(
      items
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .where((product) => product.name.isNotEmpty)
          .toList(),
      hasNext: total is int &&
          pageSize is int &&
          pageSize > 0 &&
          total > query.page * pageSize,
    );
  });
});

final shopCategoriesProvider =
    FutureProvider.autoDispose<List<ShopCategory>>((ref) {
  final client = ref.watch(apiClientsProvider).plain;
  return guardApi(() async {
    final response =
        await client.get<Map<String, dynamic>>('/api/store/categories');
    final items = response.data?['categories'];
    if (items is! List) throw const FormatException('Catégories indisponibles');
    return [
      for (final category in items)
        if (category is Map &&
            category['slug'] is String &&
            category['name'] is String)
          ShopCategory(category['slug'] as String, category['name'] as String),
    ];
  });
});

final productDetailsProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, slug) {
  final client = ref.watch(apiClientsProvider).plain;
  return guardApi(() async {
    final response = await client.get<Map<String, dynamic>>(
        '/api/store/products/${Uri.encodeComponent(slug)}');
    final data = response.data?['product'];
    if (data is! Map<String, dynamic>)
      throw const FormatException('Fiche produit indisponible');
    final product = Product.fromJson(data);
    if (product.name.isEmpty)
      throw const FormatException('Fiche produit incomplète');
    return product;
  });
});
