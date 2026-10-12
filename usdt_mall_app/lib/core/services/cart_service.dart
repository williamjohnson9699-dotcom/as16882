import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/cart_item.dart';
import 'http_service.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final HttpService _httpService = HttpService();

  // 添加商品到购物车
  Future<ApiResponse<void>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    return await _httpService.post<void>(
      ApiConstants.cart,
      needAuth: true,
      body: {
        'productId': productId,
        'quantity': quantity,
      },
    );
  }

  // 获取购物车列表
  Future<ApiResponse<List<CartItem>>> getCartList() async {
    return await _httpService.get<List<CartItem>>(
      ApiConstants.cart,
      needAuth: true,
      fromJsonT: (json) => (json as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // 更新购物车商品数量
  Future<ApiResponse<void>> updateCartQuantity({
    required int cartId,
    required int quantity,
  }) async {
    return await _httpService.put<void>(
      ApiConstants.cartItem(cartId),
      needAuth: true,
      body: {
        'quantity': quantity,
      },
    );
  }

  // 删除购物车商品
  Future<ApiResponse<void>> deleteCartItem(int cartId) async {
    return await _httpService.delete<void>(
      ApiConstants.cartItem(cartId),
      needAuth: true,
    );
  }
}
