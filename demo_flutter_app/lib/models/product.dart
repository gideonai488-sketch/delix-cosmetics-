import 'package:flutter/foundation.dart';

enum ProductCategory { skincare, hairStyling, makeup, fragrance, bodycare }

extension ProductCategoryExt on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.skincare:
        return 'Skincare';
      case ProductCategory.hairStyling:
        return 'Hair Styling';
      case ProductCategory.makeup:
        return 'Makeup';
      case ProductCategory.fragrance:
        return 'Fragrance';
      case ProductCategory.bodycare:
        return 'Body Care';
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.skincare:
        return '✨';
      case ProductCategory.hairStyling:
        return '💇';
      case ProductCategory.makeup:
        return '💄';
      case ProductCategory.fragrance:
        return '🌸';
      case ProductCategory.bodycare:
        return '🧴';
    }
  }
}

class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final String description;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String? badge;
  final String? size;
  final List<String> details;
  final List<String> included;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    this.badge,
    this.size,
    this.details = const [],
    this.included = const [],
  });

  bool get isOnSale => originalPrice > price;

  int get discountPercent =>
      isOnSale ? ((1 - price / originalPrice) * 100).round() : 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    final rawImageUrl = map['image_url'];
    final imageUrl = _normalizeImageUrl(map['image_url']?.toString() ?? '');
    
    if (kDebugMode) {
      print('[Product.fromMap] Product: ${map['name']}');
      print('  Raw image_url value: $rawImageUrl (type: ${rawImageUrl.runtimeType})');
      print('  Normalized imageUrl: $imageUrl');
      print('  Map keys: ${map.keys.toList()}');
    }
    
    return Product(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      category: productCategoryFromString(map['category']?.toString()),
      description: map['description']?.toString() ?? '',
      price: _readDouble(map['price']),
      originalPrice: _readDouble(map['original_price'] ?? map['originalPrice']),
      rating: _readDouble(map['rating']),
      reviews: _readInt(map['reviews_count'] ?? map['reviews']),
      imageUrl: imageUrl,
      badge: map['badge']?.toString(),
      size: map['size']?.toString(),
      details: _readStringList(map['details']),
      included: _readStringList(map['included']),
    );
  }
}

ProductCategory productCategoryFromString(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'skincare':
      return ProductCategory.skincare;
    case 'hair_styling':
    case 'hair styling':
    case 'hairstyling':
      return ProductCategory.hairStyling;
    case 'makeup':
      return ProductCategory.makeup;
    case 'fragrance':
      return ProductCategory.fragrance;
    case 'bodycare':
    case 'body_care':
    case 'body care':
      return ProductCategory.bodycare;
    default:
      return ProductCategory.skincare;
  }
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

String _normalizeImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return '';
}
