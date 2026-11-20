typedef CatalogueQuery = ({String search, String? category, int page});

class CataloguePage {
  const CataloguePage(this.products, {required this.hasNext});

  final List<Product> products;
  final bool hasNext;
}

class ShopCategory {
  const ShopCategory(this.slug, this.name);

  final String slug;
  final String name;
}

class Product {
  const Product({
    required this.name,
    required this.price,
    this.slug,
    this.category,
    this.coverUrl,
    this.description,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final cover = json['coverImage'];
    final images = json['images'];
    final first = images is List && images.isNotEmpty ? images.first : null;
    final picture = cover is Map
        ? cover['url']
        : first is Map
            ? first['url']
            : null;
    final rawSlug = json['slug'];
    return Product(
      slug: rawSlug is String && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(rawSlug)
          ? rawSlug
          : null,
      name: json['name'] is String ? (json['name'] as String).trim() : '',
      category: json['category'] is String ? json['category'] as String : null,
      price: json['price'] is num ? (json['price'] as num).toInt() : null,
      coverUrl: picture is String && picture.isNotEmpty ? picture : null,
      description:
          json['description'] is String ? json['description'] as String : null,
      variants: [
        for (final variant
            in json['variants'] is List ? json['variants'] as List : const [])
          if (variant is Map &&
              variant['label'] is String &&
              variant['price'] is num)
            (
              label: variant['label'] as String,
              price: (variant['price'] as num).toInt()
            ),
      ],
    );
  }

  final String? slug;
  final String name;
  final String? category;
  final int? price;
  final String? coverUrl;
  final String? description;
  final List<({String label, int price})> variants;
}
