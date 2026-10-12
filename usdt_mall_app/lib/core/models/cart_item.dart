import '../utils/date_util.dart';

class CartItem {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final String? productName;
  final double? productPrice;
  final String? productImage;
  final int? stock;
  final int? shopId;
  final String? shopName;
  final String? shopLogo;
  final DateTime? createTime;
  final DateTime? updateTime;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.productName,
    this.productPrice,
    this.productImage,
    this.stock,
    this.shopId,
    this.shopName,
    this.shopLogo,
    this.createTime,
    this.updateTime,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      userId: json['userId'] as int,
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
      productName: json['productName'] as String?,
      productPrice: (json['productPrice'] as num?)?.toDouble(),
      productImage: json['productImage'] as String?,
      stock: json['stock'] as int?,
      shopId: json['shopId'] as int?,
      shopName: json['shopName'] as String?,
      shopLogo: json['shopLogo'] as String?,
      createTime: DateUtil.parseAsLocalDateTime(json['createTime']),
      updateTime: DateUtil.parseAsLocalDateTime(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'stock': stock,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
    };
  }
}
