package com.usdt.mall.service;

import com.usdt.mall.vo.request.ShopQueryReqVO;
import com.usdt.mall.vo.request.ShopUpdateReqVO;

import java.util.Map;

/**
 * 店铺管理服务接口
 */
public interface ShopManagementService {
	/**
	 * 查询店铺列表
	 */
	Map<String, Object> queryShops(ShopQueryReqVO reqVO);

	/**
	 * 删除店铺
	 */
	void deleteShop(Long shopId);

	/**
	 * 更新店铺状态
	 */
	void updateShopStatus(Long shopId, Integer status);

	/**
	 * 更新店铺信息
	 */
	void updateShop(Long shopId, ShopUpdateReqVO reqVO);

	/**
	 * 管理员解除店铺因超时未支付产生的商家页面限制。
	 *
	 * @param shopId 店铺ID
	 * @param operatorUserId 操作人用户ID，必须是管理员
	 */
	void unlockPaymentLock(Long shopId, Long operatorUserId);
}
