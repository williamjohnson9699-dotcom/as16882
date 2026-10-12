package com.usdt.mall.service;

import java.math.BigDecimal;

/**
 * 店铺统计服务接口
 */
public interface ShopStatisticsService {

	/**
	 * 更新店铺统计数据
	 *
	 * @param shopId      店铺ID
	 * @param orderAmount 订单金额
	 */
	void updateStatistics(Long shopId, BigDecimal orderAmount);
}
