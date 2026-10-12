import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/category.dart';
import 'http_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final HttpService _httpService = HttpService();

  // 获取所有分类列表
  Future<ApiResponse<List<Category>>> getAllCategories() async {
    return await _httpService.get<List<Category>>(
      ApiConstants.categoryList,
      fromJsonT: (json) => (json as List)
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
