class PriceRange {
  final double min;
  final double max;

  const PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? double.infinity,
    );
  }

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

class Filter {
  final String sort;
  final PriceRange? priceRange;
  final String? shopType;
  final String? brand;
  final String? category;

  const Filter({
    this.sort = 'default',
    this.priceRange,
    this.shopType,
    this.brand,
    this.category,
  });

  factory Filter.defaultFilter() => const Filter(sort: 'default');

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      sort: json['sort'] as String? ?? 'default',
      priceRange: json['priceRange'] != null
          ? PriceRange.fromJson(json['priceRange'] as Map<String, dynamic>)
          : null,
      shopType: json['shopType'] as String?,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'sort': sort};
    if (priceRange != null) map['priceRange'] = priceRange!.toJson();
    if (shopType != null) map['shopType'] = shopType;
    if (brand != null) map['brand'] = brand;
    if (category != null) map['category'] = category;
    return map;
  }

  Filter copyWith({
    String? sort,
    PriceRange? priceRange,
    String? shopType,
    String? brand,
    String? category,
    bool clearPriceRange = false,
    bool clearShopType = false,
    bool clearBrand = false,
    bool clearCategory = false,
  }) {
    return Filter(
      sort: sort ?? this.sort,
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      shopType: clearShopType ? null : (shopType ?? this.shopType),
      brand: clearBrand ? null : (brand ?? this.brand),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}
