import 'json.dart';

/// `GET /categories` item. `productCount` is absent on the admin listing.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    this.productCount,
    this.isActive = true,
  });

  factory Category.fromJson(Json json) => Category(
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
    sortOrder: asInt(json['sortOrder']),
    productCount: json['productCount'] == null
        ? null
        : asInt(json['productCount']),
    isActive: asBool(json['isActive'], true),
  );

  final String id;
  final String name;
  final String slug;
  final int sortOrder;
  final int? productCount;
  final bool isActive;
}

/// The `{id, name, slug}` embedded in a product.
class CategoryRef {
  const CategoryRef({required this.id, required this.name, required this.slug});

  factory CategoryRef.fromJson(Json json) => CategoryRef(
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
  );

  final String id;
  final String name;
  final String slug;
}
