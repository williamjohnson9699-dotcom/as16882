import '../utils/date_util.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int sales;
  final int views;
  final String? mainImage;
  final List<String>? images;
  final int shopId;
  final String? shopName;
  final int categoryId;
  final String? categoryName;
  final int status;
  final bool isHot;
  final DateTime? createTime;
  final DateTime? updateTime;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.sales = 0,
    this.views = 0,
    this.mainImage,
    this.images,
    required this.shopId,
    this.shopName,
    required this.categoryId,
    this.categoryName,
    this.status = 1,
    this.isHot = false,
    this.createTime,
    this.updateTime,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      sales: json['sales'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      mainImage: json['mainImage'] as String?,
      images: json['images'] != null
          ? (json['images'] as String).split(',')
          : null,
      shopId: json['shopId'] as int,
      shopName: json['shopName'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String?,
      status: json['status'] as int? ?? 1,
      isHot: json['isHot'] as bool? ?? false,
      createTime: DateUtil.parseAsLocalDateTime(json['createTime']),
      updateTime: DateUtil.parseAsLocalDateTime(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'sales': sales,
      'views': views,
      'mainImage': mainImage,
      'images': images?.join(','),
      'shopId': shopId,
      'shopName': shopName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': status,
      'isHot': isHot,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
    };
  }
}
