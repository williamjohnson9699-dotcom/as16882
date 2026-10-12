import 'package:flutter/material.dart';

/// 响应式布局工具类
class ResponsiveUtil {
  /// 判断是否为移动端（宽度 < 600）
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// 判断是否为平板（600 <= 宽度 < 1024）
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// 判断是否为桌面端（宽度 >= 1024）
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// 获取内容区域宽度
  /// - 移动端：全宽
  /// - 平板：90%宽度
  /// - 桌面：固定1080px
  static double getContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return width; // 移动端全宽
    if (width < 1024) return width * 0.9; // 平板90%
    return 1080; // 桌面固定1080
  }

  /// 获取内容区域最大宽度约束
  static BoxConstraints getContentConstraints(BuildContext context) {
    return BoxConstraints(maxWidth: getContentWidth(context));
  }

  /// 获取响应式的内边距
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(isMobile(context) ? 12 : 24);
  }

  /// 获取响应式的字体大小
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    required double desktop,
  }) {
    return isMobile(context) ? mobile : desktop;
  }

  /// 获取网格列数
  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 5,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }
}
