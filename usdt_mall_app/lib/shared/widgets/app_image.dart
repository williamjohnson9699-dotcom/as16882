import 'package:flutter/material.dart';
import '../../core/utils/image_util.dart';
import '../../core/l10n/app_localizations.dart';

/// 统一的网络图片组件
/// 自动处理图片路径转换，支持 Web 和移动端
class AppNetworkImage extends StatelessWidget {
  /// 图片路径（可以是相对路径或完整 URL）
  final String? imagePath;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 图片适配方式
  final BoxFit? fit;

  /// 占位符组件
  final Widget? placeholder;

  /// 错误时显示的组件
  final Widget? errorWidget;

  /// 加载时显示的组件
  final Widget? loadingWidget;

  /// 边框圆角
  final BorderRadius? borderRadius;

  /// 图片颜色混合模式
  final Color? color;

  /// 颜色混合模式
  final BlendMode? colorBlendMode;

  /// 对齐方式
  final Alignment alignment;

  /// 重复方式
  final ImageRepeat repeat;

  /// 是否启用缓存
  final bool enableCache;

  const AppNetworkImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.loadingWidget,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.enableCache = true,
  });

  @override
  Widget build(BuildContext context) {
    // 获取完整的图片 URL
    final imageUrl = ImageUtil.getImageUrl(imagePath);

    // 如果 URL 为空，显示错误组件
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      loadingBuilder: loadingWidget != null
          ? (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return loadingWidget!;
            }
          : null,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('图片加载失败: $imageUrl, 错误: $error');
        return _buildErrorWidget();
      },
    );

    // 如果有圆角，包装在 ClipRRect 中
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image_outlined,
            size: (width != null && height != null)
                ? (width! < height! ? width! : height!) * 0.5
                : 40,
            color: Colors.grey[400],
          ),
        );
  }
}

/// 圆形头像组件
class AppCircleAvatar extends StatelessWidget {
  /// 图片路径
  final String? imagePath;

  /// 头像半径
  final double radius;

  /// 背景颜色
  final Color? backgroundColor;

  /// 占位符（通常是文字或图标）
  final Widget? child;

  /// 错误时显示的图标
  final IconData errorIcon;

  const AppCircleAvatar({
    super.key,
    this.imagePath,
    this.radius = 20,
    this.backgroundColor,
    this.child,
    this.errorIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUtil.getImageUrl(imagePath);

    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: child ?? Icon(errorIcon, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('头像加载失败: $imageUrl, 错误: $exception');
      },
      child: child,
    );
  }
}

/// 商品图片组件（带默认样式）
class ProductImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppNetworkImage(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              l10n.translate('no_image'),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

/// 店铺 Logo 组件
class ShopLogo extends StatelessWidget {
  final String? imagePath;
  final double size;
  final bool isCircle;

  const ShopLogo({
    super.key,
    required this.imagePath,
    this.size = 60,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCircle) {
      return AppCircleAvatar(
        imagePath: imagePath,
        radius: size / 2,
        errorIcon: Icons.store,
      );
    }

    return AppNetworkImage(
      imagePath: imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.store, size: size * 0.5, color: Colors.grey[400]),
      ),
    );
  }
}

/// 轮播图组件
class CarouselImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const CarouselImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = AppNetworkImage(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(12),
      loadingWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }
}

/// 聊天消息图片组件
class ChatImage extends StatelessWidget {
  final String? imagePath;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback? onTap;

  const ChatImage({
    super.key,
    required this.imagePath,
    this.maxWidth = 200,
    this.maxHeight = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = AppNetworkImage(
      imagePath: imagePath,
      width: maxWidth,
      height: maxHeight,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }
}

/// 缩略图组件
class ThumbnailImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final VoidCallback? onTap;
  final bool selected;

  const ThumbnailImage({
    super.key,
    required this.imagePath,
    this.size = 60,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AppNetworkImage(
          imagePath: imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}

/// 图片网格组件
class ImageGrid extends StatelessWidget {
  final List<String> imagePaths;
  final int crossAxisCount;
  final double spacing;
  final double aspectRatio;
  final void Function(int index)? onImageTap;

  const ImageGrid({
    super.key,
    required this.imagePaths,
    this.crossAxisCount = 3,
    this.spacing = 8,
    this.aspectRatio = 1,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: imagePaths.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageTap?.call(index),
          child: AppNetworkImage(
            imagePath: imagePaths[index],
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
