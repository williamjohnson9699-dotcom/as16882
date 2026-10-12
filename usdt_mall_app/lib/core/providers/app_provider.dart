import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../api/cart_api.dart';
import '../api/order_api.dart';
import '../api/account_records_api.dart';
import '../api/shop_application_api.dart';
import '../api/shop_api.dart';
import '../utils/date_util.dart';

/// 应用全局状态Provider
class AppProvider extends ChangeNotifier {
  // 默认语言配置（修改这里即可全局生效）
  static const Locale _defaultLocale = Locale('en', 'US');

  // 静态变量，用于在任何地方访问当前语言
  static Locale currentLocale = _defaultLocale;

  // 购物车商品数量
  int _cartCount = 0;

  // 买家订单入口红点，只取订单统计接口的 menuBadge
  int _pendingOrderCount = 0;
  int _pendingShipmentCount = 0;
  int _pendingReceiptCount = 0;
  int _completedOrderCount = 0;
  int _cancelledOrderCount = 0;

  // 待处理账户记录数量
  int _pendingRecordCount = 0;
  int _pendingRechargeCount = 0;
  int _pendingWithdrawCount = 0;
  int _pendingSellerPayCount = 0;
  int _pendingPlatformRebateCount = 0;
  int _pendingBuyerSettlementCount = 0;

  // 待审核店铺申请数量
  int _pendingShopApplicationCount = 0;

  // 店铺待处理订单数量
  int _pendingShopOrderCount = 0;

  // 店铺订单统计
  int _shopPendingShipmentCount = 0;
  int _shopPendingReceiptCount = 0;
  int _shopCompletedOrderCount = 0;
  int _shopCancelledOrderCount = 0;

  /// 店铺用户有超过48小时未支付货款的订单时，商家页面关闭。
  bool _shopPaymentOverdue = false;

  // 关注统计
  int _myFollowCount = 0;
  int _shopFollowCount = 0;

  // 未读消息数量
  int _unreadMessageCount = 0;

  // 当前语言
  Locale _locale = _defaultLocale;

  AppProvider() {
    // 初始化时同步静态变量
    AppProvider.currentLocale = _locale;
  }

  // 是否加载中
  bool _isLoading = false;

  int get cartCount => _cartCount;
  int get pendingOrderCount => _pendingOrderCount;
  int get pendingShipmentCount => _pendingShipmentCount;
  int get pendingReceiptCount => _pendingReceiptCount;
  int get completedOrderCount => _completedOrderCount;
  int get cancelledOrderCount => _cancelledOrderCount;
  int get pendingRecordCount => _pendingRecordCount;
  int get pendingRechargeCount => _pendingRechargeCount;
  int get pendingWithdrawCount => _pendingWithdrawCount;
  int get pendingSellerPayCount => _pendingSellerPayCount;
  int get pendingPlatformRebateCount => _pendingPlatformRebateCount;
  int get pendingBuyerSettlementCount => _pendingBuyerSettlementCount;
  int get pendingShopApplicationCount => _pendingShopApplicationCount;
  int get pendingShopOrderCount => _pendingShopOrderCount;
  int get shopPendingShipmentCount => _shopPendingShipmentCount;
  int get shopPendingReceiptCount => _shopPendingReceiptCount;
  int get shopCompletedOrderCount => _shopCompletedOrderCount;
  int get shopCancelledOrderCount => _shopCancelledOrderCount;
  bool get shopPaymentOverdue => _shopPaymentOverdue;
  int get myFollowCount => _myFollowCount;
  int get shopFollowCount => _shopFollowCount;
  int get unreadMessageCount => _unreadMessageCount;
  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  /// 更新购物车数量
  void updateCartCount(int count) {
    _cartCount = count;
    notifyListeners();
  }

  /// 更新待处理订单数量
  void updatePendingOrderCount(int count) {
    _pendingOrderCount = count;
    notifyListeners();
  }

  /// 更新订单统计数量
  void updateOrderCounts({
    required int pendingShipment,
    required int pendingReceipt,
    required int completed,
    required int cancelled,
  }) {
    _pendingShipmentCount = pendingShipment;
    _pendingReceiptCount = pendingReceipt;
    _completedOrderCount = completed;
    _cancelledOrderCount = cancelled;
    _pendingOrderCount = pendingShipment + pendingReceipt;
    notifyListeners();
  }

  void updatePendingShopOrderCount(int count) {
    _pendingShopOrderCount = count;
    notifyListeners();
  }

  /// 更新店铺订单统计。入口红点只写入接口返回的 menuBadge。
  ///
  /// [paymentOverdue] 为 null 时保留当前锁定状态，避免旧统计结果把超时锁定清掉。
  void updateShopOrderCounts({
    required int pendingShipment,
    required int pendingReceipt,
    required int completed,
    required int cancelled,
    required int menuBadge,
    bool? paymentOverdue,
  }) {
    _shopPendingShipmentCount = pendingShipment;
    _shopPendingReceiptCount = pendingReceipt;
    _shopCompletedOrderCount = completed;
    _shopCancelledOrderCount = cancelled;
    _pendingShopOrderCount = menuBadge;
    if (paymentOverdue != null) {
      _shopPaymentOverdue = paymentOverdue;
    }
    notifyListeners();
  }

  /// 更新用户订单统计数据。入口红点只用 menuBadge，不再把四个数量本地相加。
  void updateUserOrderStats(Map<String, dynamic> stats) {
    _pendingShipmentCount = _asCount(stats['pendingShipment']);
    _pendingReceiptCount = _asCount(stats['pendingReceipt']);
    _completedOrderCount = _asCount(stats['completed']);
    _cancelledOrderCount = _asCount(stats['cancelled']);
    _pendingOrderCount = _asCount(stats['menuBadge']);
    notifyListeners();
  }

  int _asCount(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  /// 更新待处理账户记录数量
  void updatePendingRecordCount(int count) {
    _pendingRecordCount = count;
    notifyListeners();
  }

  /// 从后端加载购物车数量
  Future<void> loadCartCount() async {
    try {
      final response = await CartApi.getCartCount();
      if (response.isSuccess && response.data != null) {
        _cartCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 从后端加载待处理订单数量
  Future<void> loadPendingOrderCount() async {
    try {
      final response = await OrderApi.getPendingOrderCount();
      if (response.isSuccess && response.data != null) {
        _pendingOrderCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 从后端加载用户订单统计
  Future<void> loadUserOrderStats() async {
    try {
      final response = await OrderApi.getUserOrderStats();
      if (response.isSuccess && response.data != null) {
        updateUserOrderStats(response.data!);
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 从后端加载待处理账户记录数量
  Future<void> loadPendingRecordCount() async {
    try {
      final response = await AccountRecordsApi.getPendingCount();
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _pendingRecordCount = (data['total'] as num?)?.toInt() ?? 0;
        _pendingRechargeCount = (data['recharge'] as num?)?.toInt() ?? 0;
        _pendingWithdrawCount = (data['withdraw'] as num?)?.toInt() ?? 0;
        _pendingSellerPayCount = (data['sellerPay'] as num?)?.toInt() ?? 0;
        _pendingPlatformRebateCount =
            (data['platformRebate'] as num?)?.toInt() ?? 0;
        _pendingBuyerSettlementCount =
            (data['buyerSettlement'] as num?)?.toInt() ?? 0;
        notifyListeners();
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 从后端加载待审核店铺申请数量
  Future<void> loadPendingShopApplicationCount() async {
    try {
      final response = await ShopApplicationApi.getPendingCount();
      if (response.isSuccess && response.data != null) {
        _pendingShopApplicationCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 从后端加载店铺订单统计。
  ///
  /// 接口带 paymentOverdue 时以接口为准；旧接口没有该字段时，
  /// 再用待发货订单的创建时间判断是否超过48小时未支付。
  ///
  /// [shopId] 保留给调用方，统计固定走当前用户的店铺统计接口。
  /// 返回值无。
  Future<void> loadShopOrderStats(int? shopId) async {
    try {
      final response = await OrderApi.getMyShopOrderStats();
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final bool overdue = data.containsKey('paymentOverdue')
            ? _asCount(data['paymentOverdue']) == 1
            : await _detectSellerPaymentOverdue();
        updateShopOrderCounts(
          pendingShipment: _asCount(data['pendingShipment']),
          pendingReceipt: _asCount(data['pendingReceipt']),
          completed: _asCount(data['completed']),
          cancelled: _asCount(data['cancelled']),
          menuBadge: _asCount(data['menuBadge']),
          paymentOverdue: overdue,
        );
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 旧统计接口没有超时标记时，检查待发货订单里是否有超过48小时仍未支付的订单。
  ///
  /// 返回 true 表示商家页面应关闭。没有店铺或请求失败时返回 false。
  Future<bool> _detectSellerPaymentOverdue() async {
    final shopResponse = await ShopApi.getMyShop();
    if (!shopResponse.isSuccess || shopResponse.data is! Map) {
      return false;
    }
    final shopId = (shopResponse.data as Map)['id'];
    if (shopId is! num) {
      return false;
    }

    const int pageSize = 100;
    const int maxPages = 20;
    var page = 1;
    var totalPages = 1;
    while (page <= totalPages && page <= maxPages) {
      final response = await OrderApi.getShopOrders(
        shopId.toInt(),
        status: 0,
        page: page,
        pageSize: pageSize,
      );
      if (!response.isSuccess || response.data is! Map) {
        return false;
      }
      final data = response.data as Map;
      if (_pageHasOverdueUnpaidOrder(data)) {
        return true;
      }
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      page++;
    }
    return false;
  }

  /// 判断一页待发货订单里是否存在超过48小时仍未支付货款的订单。
  ///
  /// [data] 店铺订单分页结果，读取 records。
  /// 返回 true 表示这一页已经足够关闭商家页面。
  bool _pageHasOverdueUnpaidOrder(Map data) {
    final records = data['records'];
    if (records is! List) {
      return false;
    }
    final deadline = DateTime.now().subtract(const Duration(hours: 48));
    for (final item in records) {
      if (item is! Map) {
        continue;
      }
      if (_sellerHasPaid(item['sellerPaid'])) {
        continue;
      }
      final created = DateUtil.parseAsLocalDateTime(item['createTime']);
      if (created != null && !created.isAfter(deadline)) {
        return true;
      }
    }
    return false;
  }

  /// 判断卖家是否已经支付货款。
  ///
  /// [value] 接口返回的 sellerPaid，布尔 true 或数字 1 视为已支付。
  /// 返回 true 表示已支付。
  bool _sellerHasPaid(dynamic value) {
    return value == true || value == 1;
  }

  /// 增加购物车数量
  void incrementCartCount() {
    _cartCount++;
    notifyListeners();
  }

  /// 减少购物车数量
  void decrementCartCount() {
    if (_cartCount > 0) {
      _cartCount--;
      notifyListeners();
    }
  }

  /// 更新未读消息数量
  void updateUnreadMessageCount(int count) {
    _unreadMessageCount = count;
    notifyListeners();
  }

  /// 增加未读消息数量
  void incrementUnreadMessageCount() {
    _unreadMessageCount++;
    notifyListeners();
  }

  /// 清空未读消息数量
  void clearUnreadMessageCount() {
    _unreadMessageCount = 0;
    notifyListeners();
  }

  /// 加载关注统计
  Future<void> loadFollowStats() async {
    try {
      final response = await ShopApi.getMyFollowStats();
      if (response.isSuccess && response.data != null) {
        _myFollowCount = response.data?['myFollowCount'] ?? 0;
        _shopFollowCount = response.data?['shopFollowCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('加载关注统计失败: $e');
      }
    }
  }

  /// 切换语言
  void changeLocale(Locale locale) {
    _locale = locale;
    AppProvider.currentLocale = locale;
    notifyListeners();
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 清除所有状态
  void clear() {
    _cartCount = 0;
    _pendingOrderCount = 0;
    _pendingShipmentCount = 0;
    _pendingReceiptCount = 0;
    _completedOrderCount = 0;
    _cancelledOrderCount = 0;
    _pendingRecordCount = 0;
    _pendingRechargeCount = 0;
    _pendingWithdrawCount = 0;
    _pendingShopApplicationCount = 0;
    _pendingShopOrderCount = 0;
    _unreadMessageCount = 0;
    _isLoading = false;
    notifyListeners();
  }
}
