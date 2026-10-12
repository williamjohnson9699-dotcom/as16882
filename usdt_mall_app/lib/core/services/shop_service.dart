import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../models/page_data.dart';
import 'http_service.dart';

class ShopService {
  static final ShopService _instance = ShopService._internal();
  factory ShopService() => _instance;
  ShopService._internal();

  final HttpService _httpService = HttpService();

  // 搜索店铺
  Future<ApiResponse<PageData<Shop>>> searchShops({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    return await _httpService.get<PageData<Shop>>(
      ApiConstants.shopSearch,
      queryParams: queryParams,
      fromJsonT: (json) => PageData.fromJson(
        json as Map<String, dynamic>,
        (item) => Shop.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  // 获取店铺详情
  Future<ApiResponse<Shop>> getShopDetail(String shopId) async {
    return await _httpService.get<Shop>(
      ApiConstants.shopDetail(shopId),
      needAuth: true,
      fromJsonT: (json) => Shop.fromJson(json as Map<String, dynamic>),
    );
  }

  // 获取店铺商品列表
  Future<ApiResponse<PageData<Product>>> getShopProducts(
    String shopId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    return await _httpService.get<PageData<Product>>(
      ApiConstants.shopProducts(shopId),
      queryParams: queryParams,
      fromJsonT: (json) => PageData.fromJson(
        json as Map<String, dynamic>,
        (item) => Product.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  // 关注店铺
  Future<ApiResponse<void>> followShop(String shopId) async {
    return await _httpService.post<void>(
      ApiConstants.followShop(shopId),
      needAuth: true,
    );
  }

  // 取消关注店铺
  Future<ApiResponse<void>> unfollowShop(String shopId) async {
    return await _httpService.delete<void>(
      ApiConstants.followShop(shopId),
      needAuth: true,
    );
  }

  // 检查关注状态
  Future<ApiResponse<bool>> checkFollowStatus(String shopId) async {
    return await _httpService.get<bool>(
      ApiConstants.shopFollowStatus(shopId),
      needAuth: true,
      fromJsonT: (json) => json as bool,
    );
  }
}
