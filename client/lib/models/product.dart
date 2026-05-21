class PlatformPrice {
  final String platform;
  final double price;
  final String shopType;
  final String url;

  const PlatformPrice({
    required this.platform,
    required this.price,
    required this.shopType,
    required this.url,
  });

  factory PlatformPrice.fromJson(Map<String, dynamic> json) {
    return PlatformPrice(
      platform: json['platform'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      shopType: json['shopType'] as String? ?? '',
      url: json['url'] as String? ?? '#',
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'price': price,
        'shopType': shopType,
        'url': url,
      };
}

class Product {
  final String id;
  final String name;
  final String image;
  final List<PlatformPrice> platformPrices;
  final double lowestPrice;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.platformPrices,
    required this.lowestPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      platformPrices: (json['platformPrices'] as List<dynamic>?)
              ?.map((e) => PlatformPrice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'platformPrices': platformPrices.map((p) => p.toJson()).toList(),
        'lowestPrice': lowestPrice,
      };
}
