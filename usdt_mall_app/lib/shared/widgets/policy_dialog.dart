import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';

/// 政策对话框（用于显示使用条款、隐私政策等）
class PolicyDialog extends StatelessWidget {
  final String title;
  final String content;

  const PolicyDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // 内容
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 关闭按钮
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }
}
