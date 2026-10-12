import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;

class ApiConstants {
  // 环境配置
  static const bool isProduction = true; // true: 生产环境, false: 开发环境
  static const String productionDomain = 'www.as1688.me';

  static String get baseUrl {
    final url = _getBaseUrl();
    _printEnvironmentInfo(url);
    return url;
  }

  static String _getBaseUrl() {
    if (kIsWeb) {
      if (!isProduction) {
        return 'http://127.0.0.1:8080/api/v1';
      }
      // 生产环境与当前页面同源，/api 由站点反代到后端。
      return '${Uri.base.origin}/api/v1';
    }
    if (isProduction) {
      return 'https://$productionDomain/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static bool _hasLoggedEnvironment = false;

  static void _printEnvironmentInfo(String url) {
    if (!_hasLoggedEnvironment) {
      _hasLoggedEnvironment = true;
      debugPrint('=================================');
      debugPrint('🌍 环境配置信息');
      debugPrint('=================================');
      debugPrint('当前环境: ${isProduction ? "生产环境 (PRODUCTION)" : "开发环境 (DEVELOPMENT)"}');
      debugPrint('API地址: $url');
      if (kIsWeb && !isProduction) {
        debugPrint('访问方式: 本地后端 http://127.0.0.1:8080');
      } else if (kIsWeb) {
        debugPrint('访问方式: 同源反代 /api');
      } else if (isProduction) {
        debugPrint('域名: $productionDomain');
      }
      String platform = 'Unknown';
      if (kIsWeb) {
        platform = 'Web';
      } else {
        platform = defaultTargetPlatform.name;
      }
      debugPrint('运行平台: $platform');
      debugPrint('=================================');
    }
  }

  // 认证相关
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String userInfo = '/auth/userinfo';
  static const String onlineStatus = '/auth/online-status';

  // 用户相关
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/password';
  static const String setPaymentPassword = '/user/payment-password';

  // 商品相关
  static const String productSearch = '/product/search';
  static String productDetail(String id) => '/product/$id';
  static String productsByCategory(String categoryId) => '/product/category/$categoryId';
  static const String hotProducts = '/product/hot';

  // 店铺相关
  static const String shopSearch = '/shop/search';
  static String shopDetail(String id) => '/shop/$id';
  static String shopProducts(String id) => '/shop/$id/products';
  static String followShop(String id) => '/shop/$id/follow';
  static String shopFollowStatus(String id) => '/shop/$id/follow/status';

  // 分类相关
  static const String categoryList = '/category/list';

  // 订单相关
  static const String orders = '/orders';
  static String orderDetail(int id) => '/orders/$id';
  static String payOrder(int id) => '/orders/$id/pay';

  // 购物车相关
  static const String cart = '/cart';
  static String cartItem(int id) => '/cart/$id';

  // 账户相关
  static const String accountBalance = '/account/balance';
  static const String accountTransactions = '/account/transactions';
  static const String recharge = '/account/recharge';
  static const String withdraw = '/account/withdraw';
  static const String rechargeWithdrawRecords = '/account/recharge-withdraw';

  // 聊天相关
  static const String chatSessions = '/chat/sessions';
  static const String mySession = '/chat/my-session';
  static String sessionMessages(int sessionId) => '/chat/sessions/$sessionId/messages';
  static const String sendMessage = '/chat/messages';
  static String markSessionRead(int sessionId) => '/chat/sessions/$sessionId/read';

  // 文件上传
  static const String uploadFile = '/file/upload';
  static String downloadFile(String filename) => '/file/download/$filename';
  static String deleteFile(String filename) => '/file/$filename';
  static String previewFile(String filename) => '/file/preview/$filename';
}
