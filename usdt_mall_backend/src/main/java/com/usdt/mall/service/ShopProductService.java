package com.usdt.mall.service;

import com.usdt.mall.vo.request.ShopProductQueryReqVO;

import java.util.List;
import java.util.Map;

/**
 * 店铺商品服务接口
 */
public interface ShopProductService {

	/**
	 * 查询店铺商品列表
	 */
	Map<String, Object> queryShopProducts(Long userId, ShopProductQueryReqVO reqVO);

	/**
	 * 删除店铺商品
	 */
	void deleteShopProduct(Long userId, Long productId);

	/**
	 * 查询所有商品列表（用于添加视图）
	 */
	Map<String, Object> queryAllProducts(Long userId, String keyword, String category, Integer page, Integer pageSize);

	/**
	 * 添加商品到店铺
	 */
	void addProductToShop(Long userId, Long productId);

	/**
	 * 创建新商品并添加到店铺
	 */
	void createAndAddProduct(Long userId, String name, String category, String price, Integer stock, String description, List<String> images);
}
