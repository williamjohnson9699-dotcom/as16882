package com.usdt.mall.service;

import java.util.Map;

/**
 * 搜索服务接口
 */
public interface SearchService {

	/**
	 * 搜索商品
	 */
	Map<String, Object> searchProducts(String keyword, Integer page, Integer pageSize);

	/**
	 * 搜索店铺
	 */
	Map<String, Object> searchShops(String keyword, Integer page, Integer pageSize);
}
