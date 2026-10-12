package com.usdt.mall.service;

import java.util.Map;

/**
 * 系统配置服务接口
 */
public interface SystemConfigService {

	/**
	 * 获取利润率配置
	 */
	Integer getProfitRate();

	/**
	 * 更新利润率配置
	 */
	void updateProfitRate(Integer profitRate);

	/**
	 * 获取所有系统配置
	 */
	Map<String, String> getAllConfigs();

	/**
	 * 获取收款地址
	 */
	String getReceivingAddress();

	/**
	 * 更新收款地址
	 */
	void updateReceivingAddress(String address);
}
