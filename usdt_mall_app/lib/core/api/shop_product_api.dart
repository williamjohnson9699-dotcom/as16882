import 'http_client.dart';
import '../models/api_response.dart';

/// 店铺商品API接口
class ShopProductApi {
  static final HttpClient _client = HttpClient();

  /// 查询店铺商品列表
  /// [keyword] 搜索关键词（商品名称）
  /// [category] 分类筛选: all/生活/男鞋/女鞋/配饰/男装/女装/男包/女包/男童/女童/全球购
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> getProductList({
    String? keyword,
    String? category,
    int page = 1,
    int pageSize = 12,
  }) async {
    return await _client.post(
      '/shop/products/query',
      data: {
        'keyword': keyword,
        'category': category,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 删除店铺商品
  /// [productId] 商品ID
  static Future<ApiResponse<void>> deleteProduct(String productId) async {
    return await _client.delete('/shop/products/$productId');
  }

  /// 查询所有商品列表（用于添加视图）
  /// [keyword] 搜索关键词（商品名称）
  /// [category] 分类筛选
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> getAllProductList({
    String? keyword,
    String? category,
    int page = 1,
    int pageSize = 12,
  }) async {
    return await _client.post(
      '/shop/products/all',
      data: {
        'keyword': keyword,
        'category': category,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 添加商品到店铺
  /// [productId] 商品ID
  static Future<ApiResponse<void>> addProductToShop(String productId) async {
    return await _client.post('/shop/products/add/$productId');
  }

  /// 创建新商品并添加到店铺
  /// [name] 商品名称
  /// [category] 商品分类
  /// [price] 商品价格
  /// [stock] 库存数量
  /// [description] 商品描述
  /// [images] 商品图片列表
  static Future<ApiResponse<void>> createAndAddProduct({
    required String name,
    required String category,
    required String price,
    required int stock,
    String? description,
    List<String>? images,
  }) async {
    return await _client.post(
      '/shop/products/create',
      data: {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        if (description != null) 'description': description,
        if (images != null) 'images': images,
      },
    );
  }
}
