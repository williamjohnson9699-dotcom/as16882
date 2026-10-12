import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/product.dart';
import '../models/page_data.dart';
import 'http_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final HttpService _httpService = HttpService();

  // 搜索商品
  Future<ApiResponse<PageData<Product>>> searchProducts({
    String? keyword,
    int? categoryId,
    int? shopId,
    bool? isHot,
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
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }
    if (shopId != null) {
      queryParams['shopId'] = shopId.toString();
    }
    if (isHot != null) {
      queryParams['isHot'] = isHot.toString();
    }

    return await _httpService.get<PageData<Product>>(
      ApiConstants.productSearch,
      queryParams: queryParams,
      fromJsonT: (json) => PageData.fromJson(
        json as Map<String, dynamic>,
        (item) => Product.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  // 获取商品详情
  Future<ApiResponse<Product>> getProductDetail(String productId) async {
    return await _httpService.get<Product>(
      ApiConstants.productDetail(productId),
      fromJsonT: (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  // 根据分类获取商品
  Future<ApiResponse<PageData<Product>>> getProductsByCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    return await _httpService.get<PageData<Product>>(
      ApiConstants.productsByCategory(categoryId),
      queryParams: queryParams,
      fromJsonT: (json) => PageData.fromJson(
        json as Map<String, dynamic>,
        (item) => Product.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  // 获取热卖商品
  Future<ApiResponse<PageData<Product>>> getHotProducts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    return await _httpService.get<PageData<Product>>(
      ApiConstants.hotProducts,
      queryParams: queryParams,
      fromJsonT: (json) => PageData.fromJson(
        json as Map<String, dynamic>,
        (item) => Product.fromJson(item as Map<String, dynamic>),
      ),
    );
  }
}
