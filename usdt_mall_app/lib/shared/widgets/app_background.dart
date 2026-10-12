import 'package:flutter/material.dart';

/// 应用背景装饰组件
/// 提供简约的渐变背景和几何图案
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFECEFF1), // 基础背景色
      child: Stack(
        children: [
          // 曲线渐变背景
          _buildCurvedGradient(),
          // 几何图案装饰
          _buildGeometricPattern(),
          // 实际内容
          child,
        ],
      ),
    );
  }

  /// 构建曲线渐变背景
  Widget _buildCurvedGradient() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CurvedGradientPainter(),
      ),
    );
  }

  /// 构建几何图案
  Widget _buildGeometricPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GeometricPatternPainter(),
      ),
    );
  }
}

/// 几何图案绘制器
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制圆形图案
    _drawCircles(canvas, size, paint);

    // 绘制网格线
    _drawGrid(canvas, size, paint);
  }

  /// 绘制圆形装饰
  void _drawCircles(Canvas canvas, Size size, Paint paint) {
    // 右上角大圆
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.2,
      paint,
    );

    // 左下角中圆
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      size.width * 0.15,
      paint,
    );

    // 右下角小圆
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.9),
      size.width * 0.08,
      paint,
    );
  }

  /// 绘制网格线
  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 50.0;

    // 绘制垂直线
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // 绘制水平线
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 曲线渐变绘制器
class _CurvedGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制多层曲线波浪（往下移动）
    _drawWave(canvas, size, 0, const Color(0xFFBBDEFB), 0.3);
    _drawWave(canvas, size, 50, const Color(0xFF90CAF9), 0.2);
    _drawWave(canvas, size, 100, const Color(0xFF64B5F6), 0.15);
  }

  /// 绘制波浪曲线
  void _drawWave(Canvas canvas, Size size, double offset, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();

    // 起点（往下移动到 0.6 的位置）
    path.moveTo(0, size.height * 0.6 + offset);

    // 使用贝塞尔曲线绘制波浪
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5 + offset,
      size.width * 0.5,
      size.height * 0.6 + offset,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7 + offset,
      size.width,
      size.height * 0.6 + offset,
    );

    // 连接到右下角和左下角
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
