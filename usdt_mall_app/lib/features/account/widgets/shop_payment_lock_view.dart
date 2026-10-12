import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/app_provider.dart';

/// 商家超时未支付时替代商家页面的联系客服页。
class ShopPaymentLockView extends StatefulWidget {
  const ShopPaymentLockView({super.key});

  @override
  State<ShopPaymentLockView> createState() => _ShopPaymentLockViewState();
}

class _ShopPaymentLockViewState extends State<ShopPaymentLockView> {
  /// 进入页面时重新拉取店铺订单统计，超时订单处理完后可以恢复商家页面。
  ///
  /// 无参数。无返回值。
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AppProvider>().loadShopOrderStats(null);
    });
  }

  /// 打开现有客服会话页。
  ///
  /// 无参数。无返回值。
  void _openCustomerService() {
    context.go('/chat');
  }

  /// 构建联系客服说明和入口。
  ///
  /// [context] 用于读取文案和跳转。
  /// 返回占满内容区的联系客服页面。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 72, color: Colors.blue[700]),
            const SizedBox(height: 20),
            Text(
              l10n.contactCustomerService,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.shopPaymentOverdueMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _openCustomerService,
              icon: const Icon(Icons.chat_outlined),
              label: Text(l10n.contactCustomerService),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
