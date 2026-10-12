package com.usdt.mall.service;

import java.util.List;
import java.util.Map;

/**
 * 轮播商品服务接口
 */
public interface CarouselProductService {

	/**
	 * 获取轮播商品列表
	 */
	List<Map<String, Object>> getCarouselProducts();

	/**
	 * 获取所有商品列表（用于选择）
	 */
	List<Map<String, Object>> getAllProducts();

	/**
	 * 分页搜索商品（用于选择）
	 */
	Map<String, Object> searchProducts(String keyword, Integer page, Integer pageSize);

	/**
	 * 添加轮播商品
	 */
	void addCarouselProduct(Long productId);

	/**
	 * 删除轮播商品
	 */
	void deleteCarouselProduct(Long carouselId);

	/**
	 * 更新轮播商品排序
	 */
	void updateCarouselOrder(List<Long> productIds);
}
