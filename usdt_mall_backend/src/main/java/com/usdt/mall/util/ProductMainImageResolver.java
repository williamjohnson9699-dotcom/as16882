package com.usdt.mall.util;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.usdt.mall.entity.Product;
import com.usdt.mall.entity.ProductImage;
import com.usdt.mall.mapper.ProductImageMapper;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.List;

/**
 * 列表接口的主图补全。主图为空时用排序后的第一张附图，仍然没有则返回空字符串。
 */
@Component
public class ProductMainImageResolver {

	@Resource
	private ProductImageMapper productImageMapper;

	public String resolve(Product product) {
		if (product == null) {
			return "";
		}
		String mainImage = normalize(product.getMainImage());
		if (!mainImage.isEmpty()) {
			return mainImage;
		}
		if (product.getId() == null) {
			return "";
		}
		LambdaQueryWrapper<ProductImage> wrapper = new LambdaQueryWrapper<>();
		wrapper.eq(ProductImage::getProductId, product.getId());
		wrapper.orderByAsc(ProductImage::getSortOrder);
		List<ProductImage> images = productImageMapper.selectList(wrapper);
		for (ProductImage image : images) {
			String url = normalize(image.getImageUrl());
			if (!url.isEmpty()) {
				return url;
			}
		}
		return "";
	}

	public String resolve(String mainImage, List<String> galleryUrls) {
		String current = normalize(mainImage);
		if (!current.isEmpty()) {
			return current;
		}
		if (galleryUrls == null) {
			return "";
		}
		for (String url : galleryUrls) {
			String normalized = normalize(url);
			if (!normalized.isEmpty()) {
				return normalized;
			}
		}
		return "";
	}

	private String normalize(String value) {
		if (value == null) {
			return "";
		}
		String trimmed = value.trim();
		if (trimmed.isEmpty() || "null".equalsIgnoreCase(trimmed)) {
			return "";
		}
		return trimmed;
	}
}
