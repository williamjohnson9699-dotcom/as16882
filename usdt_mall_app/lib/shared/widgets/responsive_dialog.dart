import 'package:flutter/material.dart';
import '../../core/utils/responsive_util.dart';

/// 响应式对话框包装器
/// 自动适配移动端和 Web 端的布局
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final bool fullScreenOnMobile;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.fullScreenOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile && fullScreenOnMobile) {
      // 移动端全屏对话框
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : (maxWidth ?? 600),
          maxHeight: maxHeight ?? double.infinity,
        ),
        padding: padding ?? const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }
}

/// 响应式 AlertDialog 包装器
class ResponsiveAlertDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;

  const ResponsiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      title: title != null ? Text(title!) : null,
      content: content != null
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 400,
              ),
              child: content,
            )
          : null,
      actions: actions,
      actionsPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 8 : 12,
      ),
    );
  }
}
