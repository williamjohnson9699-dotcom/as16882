import 'package:flutter/material.dart';
import 'package:usdt_mall_app/core/api/shop_api.dart';
import 'package:usdt_mall_app/core/utils/image_util.dart';
import 'package:usdt_mall_app/core/l10n/app_localizations.dart';
import 'package:usdt_mall_app/core/utils/responsive_util.dart';
import 'package:usdt_mall_app/features/shop/widgets/edit_shop_dialog.dart';

/// 我的店铺视图
class MyShopView extends StatefulWidget {
  const MyShopView({super.key});

  @override
  State<MyShopView> createState() => _MyShopViewState();
}

class _MyShopViewState extends State<MyShopView> {
  bool _isLoading = false;
  Map<String, dynamic>? _shopInfo;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  /// 加载店铺信息
  Future<void> _loadShopInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ShopApi.getMyShop();
      if (response.isSuccess && response.data != null) {
        final shopData = response.data as Map<String, dynamic>;
        setState(() {
          _shopInfo = shopData;
        });

        // 加载统计信息
        await _loadStatistics(shopData['id']);
      } else {
        setState(() {
          _shopInfo = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _shopInfo = null;
        _isLoading = false;
      });
    }
  }

  /// 加载统计信息
  Future<void> _loadStatistics(int shopId) async {
    try {
      final response = await ShopApi.getShopStatistics(shopId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _statistics = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Text(
              l10n.myShop,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shopInfo == null
                    ? _buildNoShop()
                    : _buildShopInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShop() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noShopYet,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pleaseApplyShopFirst,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShopHeader(),
          const SizedBox(height: 24),
          _buildStatisticsSection(),
          const SizedBox(height: 24),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ImageUtil.getImageUrl(_shopInfo!['logo'] ?? ''),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: Icon(Icons.store, size: 50, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shopInfo!['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 编辑按钮已隐藏
                    // IconButton(
                    //   icon: Icon(Icons.edit, color: Colors.blue[700]),
                    //   onPressed: _handleEditShop,
                    //   tooltip: l10n.translate('edit_shop'),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _shopInfo!['category'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_shopInfo!['status'] == 1 ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _shopInfo!['status'] == 1 ? AppLocalizations.of(context).shopOpen : AppLocalizations.of(context).shopClosed,
                    style: TextStyle(
                      fontSize: 13,
                      color: _shopInfo!['status'] == 1 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 处理编辑店铺
  Future<void> _handleEditShop() async {
    if (_shopInfo == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditShopDialog(shopData: _shopInfo!),
    );

    if (result == true) {
      // 重新加载店铺信息
      _loadShopInfo();
    }
  }

  Widget _buildStatisticsSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shopStatistics,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard(l10n.todayOrders, '${_statistics?['todayOrders'] ?? 0}', Icons.today, Colors.purple)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(l10n.todaySales, '${_statistics?['todaySales'] ?? 0}', Icons.monetization_on, Colors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(l10n.todayProfit, '${_statistics?['todayProfit'] ?? 0}', Icons.account_balance_wallet, Colors.indigo)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(l10n.orderCount, '${_statistics?['totalOrders'] ?? 0}', Icons.shopping_cart_outlined, Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(l10n.totalSales, '${_statistics?['totalSales'] ?? 0}', Icons.attach_money, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(l10n.totalProfit, '${_statistics?['totalProfit'] ?? 0}', Icons.trending_up, Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shopInfo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(l10n.shopLevelLabel, 'Lv.${_shopInfo!['level'] ?? 1}'),
          _buildInfoRow(l10n.shopRating, '${_shopInfo!['rating'] ?? 5.0}'),
          _buildInfoRow(l10n.followCount, '${_shopInfo!['followCount'] ?? 0}'),
          _buildInfoRow(l10n.shopViews, '${_shopInfo!['views'] ?? 0}'),
          _buildInfoRow(l10n.shopCreditScore, '${_shopInfo!['creditScore'] ?? 100}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
