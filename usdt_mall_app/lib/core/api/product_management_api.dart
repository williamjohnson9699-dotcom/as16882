import 'http_client.dart';
import '../models/api_response.dart';

/// 商品管理API接口
class ProductManagementApi {
  static final HttpClient _client = HttpClient();

  /// 获取商品列表
  /// [keyword] 搜索关键词（商品名称、编号）
  /// [category] 分类筛选: all/生活/男鞋/女鞋/配饰/男装/女装/男包/女包/男童/女童/全球购
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> getProductList({
    String? keyword,
    String? category,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _client.post(
      '/product-management/query',
      data: {
        'keyword': keyword,
        'category': category,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 获取商品详情
  /// [productId] 商品ID
  static Future<ApiResponse<Map<String, dynamic>>> getProductDetail(
    String productId,
  ) async {
    return await _client.get('/product-management/products/$productId');
  }

  /// 添加商品
  /// [name] 商品名称
  /// [category] 商品分类
  /// [price] 商品价格
  /// [stock] 库存数量
  /// [description] 商品说明
  /// [images] 商品图片列表（最多5张）
  static Future<ApiResponse<Map<String, dynamic>>> addProduct({
    required String name,
    required String category,
    required String price,
    required int stock,
    String? description,
    List<String>? images,
  }) async {
    return await _client.post(
      '/product-management/products',
      data: {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'description': description,
        'images': images,
      },
    );
  }

  /// 批量添加商品
  static Future<ApiResponse<Map<String, dynamic>>> batchAddProduct({
    required List<Map<String, dynamic>> products,
  }) async {
    return await _client.post(
      '/product-management/products/batch',
      data: {
        'products': products,
      },
    );
  }

  /// 更新商品信息
  /// [productId] 商品ID
  /// [name] 商品名称
  /// [category] 商品分类
  /// [price] 商品价格
  /// [stock] 库存数量
  /// [sales] 销量
  /// [views] 浏览量
  /// [status] 状态: active/inactive
  /// [description] 商品说明
  /// [images] 商品图片列表（最多5张）
  static Future<ApiResponse<Map<String, dynamic>>> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String price,
    required int stock,
    int? sales,
    int? views,
    required String status,
    String? description,
    List<String>? images,
  }) async {
    return await _client.put(
      '/product-management/products/$productId',
      data: {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'sales': sales,
        'views': views,
        'status': status,
        'description': description,
        'images': images,
      },
    );
  }

  /// 删除商品
  /// [productId] 商品ID
  static Future<ApiResponse<void>> deleteProduct(String productId) async {
    return await _client.delete('/product-management/products/$productId');
  }
}
