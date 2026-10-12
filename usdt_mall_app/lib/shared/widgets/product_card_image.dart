import 'package:flutter/material.dart';

import '../../core/utils/image_util.dart';

/// 商品卡片下半部文案的固定高度。图片区按原图常见的 2:3 预留，格子比例按这个高度算，避免加载后把列表顶下去。
class ProductCardMetrics {
  static const double textBlockHeight = 76;

  /// 缩略图宽高比（宽 / 高）。商品图多为 400×600，整张放进这个区域，不裁切。
  static const double imageAspectRatio = 2 / 3;

  /// 按列数和图片区比例计算网格子项宽高比。
  ///
  /// 参数:
  /// - [maxWidth]: 网格可用宽度
  /// - [crossAxisCount]: 列数
  /// - [crossAxisSpacing]: 列间距
  ///
  /// 返回: 子项宽高比；宽度无效时返回 0.48
  static double gridAspectRatio({
    required double maxWidth,
    required int crossAxisCount,
    required double crossAxisSpacing,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0 || crossAxisCount <= 0) {
      return 0.48;
    }
    final cellWidth =
        (maxWidth - crossAxisSpacing * (crossAxisCount - 1)) / crossAxisCount;
    if (cellWidth <= 0) {
      return 0.48;
    }
    final imageHeight = cellWidth / imageAspectRatio;
    return cellWidth / (imageHeight + textBlockHeight);
  }
}

/// 卡片上半部的商品图。按 2:3 整张显示，只在超出格子时缩小，不放大、不裁切。没有地址或加载失败时显示占位。
class ProductCardImage extends StatelessWidget {
  final String? imagePath;

  const ProductCardImage({
    super.key,
    required this.imagePath,
  });

  static String? pathOf(Map<String, dynamic> product) {
    for (final key in ['mainImage', 'image']) {
      final raw = product[key];
      if (raw == null) {
        continue;
      }
      final text = raw.toString().trim();
      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUtil.getImageUrl(imagePath);
    return AspectRatio(
      aspectRatio: ProductCardMetrics.imageAspectRatio,
      child: ColoredBox(
        color: Colors.grey.shade200,
        child: imageUrl.isEmpty
            ? const _ProductImagePlaceholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const _ProductImagePlaceholder(),
              ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ExcludeSemantics(
        child: Icon(Icons.image_outlined, size: 32, color: Color(0xFF9E9E9E)),
      ),
    );
  }
}

/// 分类、搜索、首页共用的商品卡片。点按区域是整张卡片。
class ProductSummaryCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final double nameSize;
  final double priceSize;

  const ProductSummaryCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
    this.margin,
    this.nameSize = 14,
    this.priceSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final price = product['price'] ?? 0;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProductCardImage(imagePath: ProductCardImage.pathOf(product)),
                SizedBox(
                  height: ProductCardMetrics.textBlockHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: nameSize,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: const Color(0xFF212121),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '\$$price',
                          style: TextStyle(
                            fontSize: priceSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC62828),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
