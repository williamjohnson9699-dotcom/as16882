import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/responsive_util.dart';

/// 订单成功对话框
class OrderSuccessDialog extends StatefulWidget {
  const OrderSuccessDialog({super.key});

  @override
  State<OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<OrderSuccessDialog> {
  int _countdown = 5; // 倒计时秒数
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 启动倒计时
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          context.go('/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 400,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成功图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 24),
            // 成功提示
            Text(
              l10n.orderCreatedSuccess,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 倒计时提示
            Text(
              l10n.secondsRedirectHome(_countdown),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // 按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  l10n.continueShopping,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
