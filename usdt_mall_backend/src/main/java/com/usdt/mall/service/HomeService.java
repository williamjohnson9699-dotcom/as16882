package com.usdt.mall.service;

import java.util.Map;

/**
 * 首页服务接口
 */
public interface HomeService {

	/**
	 * 获取热卖商品
	 */
	Map<String, Object> getHotProducts(Integer limit);

	/**
	 * 获取热卖商品（分页）
	 */
	Map<String, Object> getHotProductsWithPagination(Integer page, Integer pageSize);

	/**
	 * 获取每日新发现商品
	 */
	Map<String, Object> getDailyDiscover(Integer limit);
}
