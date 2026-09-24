import 'category.dart';
import 'json.dart';

/// `GET /products` item.
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.unit,
    required this.price,
    this.imageUrl,
    required this.inStock,
    required this.stockQty,
    required this.autoApprove,
    required this.category,
  });

  factory ProductSummary.fromJson(Json json) => ProductSummary(
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
    unit: asString(json['unit']),
    price: asMoney(json['price']),
    imageUrl: asStringOrNull(json['imageUrl']),
    inStock: asBool(json['inStock']),
    stockQty: asInt(json['stockQty']),
    autoApprove: asBool(json['autoApprove']),
    category: CategoryRef.fromJson(asJson(json['category'])),
  );

  final String id;
  final String name;
  final String slug;
  final String unit;

  /// Default variant's price, 2-dp string.
  final String price;
  final String? imageUrl;
  final bool inStock;
  final int stockQty;
  final bool autoApprove;
  final CategoryRef category;
}

class Variant {
  const Variant({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    required this.stockQty,
    required this.isActive,
    this.priceDelta,
  });

  factory Variant.fromJson(Json json) => Variant(
    id: asString(json['id']),
    name: asString(json['name']),
    sku: asStringOrNull(json['sku']),
    price: asMoney(json['price']),
    stockQty: asInt(json['stockQty']),
    isActive: asBool(json['isActive'], true),
    priceDelta: json['priceDelta'] == null ? null : asMoney(json['priceDelta']),
  );

  final String id;
  final String name;
  final String? sku;

  /// `basePrice + priceDelta`, computed by the API.
  final String price;
  final int stockQty;
  final bool isActive;

  /// Only on admin responses.
  final String? priceDelta;

  bool get inStock => stockQty > 0;
}

/// `GET /products/:id`.
class Product extends ProductSummary {
  const Product({
    required super.id,
    required super.name,
    required super.slug,
    required super.unit,
    required super.price,
    super.imageUrl,
    required super.inStock,
    required super.stockQty,
    required super.autoApprove,
    required super.category,
    required this.description,
    required this.images,
    required this.variants,
  });

  factory Product.fromJson(Json json) {
    final summary = ProductSummary.fromJson(json);
    return Product(
      id: summary.id,
      name: summary.name,
      slug: summary.slug,
      unit: summary.unit,
      price: summary.price,
      imageUrl: summary.imageUrl,
      inStock: summary.inStock,
      stockQty: summary.stockQty,
      autoApprove: summary.autoApprove,
      category: summary.category,
      description: asStringOrNull(json['description']),
      images: asStringList(json['images']),
      variants: asJsonList(json['variants'])
          .map(Variant.fromJson)
          .toList(growable: false),
    );
  }

  final String? description;
  final List<String> images;
  final List<Variant> variants;

  List<Variant> get activeVariants =>
      variants.where((v) => v.isActive).toList(growable: false);
}

/// `GET /admin/products/:id`.
class AdminProduct extends Product {
  const AdminProduct({
    required super.id,
    required super.name,
    required super.slug,
    required super.unit,
    required super.price,
    super.imageUrl,
    required super.inStock,
    required super.stockQty,
    required super.autoApprove,
    required super.category,
    required super.description,
    required super.images,
    required super.variants,
    required this.basePrice,
    required this.isActive,
    required this.sortOrder,
    required this.categoryId,
  });

  factory AdminProduct.fromJson(Json json) {
    final product = Product.fromJson(json);
    return AdminProduct(
      id: product.id,
      name: product.name,
      slug: product.slug,
      unit: product.unit,
      price: product.price,
      imageUrl: product.imageUrl,
      inStock: product.inStock,
      stockQty: product.stockQty,
      autoApprove: product.autoApprove,
      category: product.category,
      description: product.description,
      images: product.images,
      variants: product.variants,
      basePrice: asMoney(json['basePrice']),
      isActive: asBool(json['isActive'], true),
      sortOrder: asInt(json['sortOrder']),
      categoryId: asString(json['categoryId'], product.category.id),
    );
  }

  final String basePrice;
  final bool isActive;
  final int sortOrder;
  final String categoryId;
}
