package com.usdt.mall.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.usdt.mall.vo.request.ShopSearchReqVO;
import com.usdt.mall.vo.response.ProductRespVO;
import com.usdt.mall.vo.response.ShopRespVO;

import java.util.Map;

/**
 * 店铺Service接口
 */
public interface ShopService {

	/**
	 * 搜索店铺（分页）
	 */
	Page<ShopRespVO> searchShops(ShopSearchReqVO reqVO);

	/**
	 * 获取店铺详情
	 */
	ShopRespVO getShopDetail(Long id, Long userId);

	/**
	 * 获取店铺商品列表（分页）
	 */
	Page<ProductRespVO> getShopProducts(Long shopId, Integer page, Integer pageSize);

	/**
	 * 关注店铺
	 */
	void followShop(Long shopId, Long userId);

	/**
	 * 取消关注店铺
	 */
	void unfollowShop(Long shopId, Long userId);

	/**
	 * 检查是否关注店铺
	 */
	Boolean isFollowed(Long shopId, Long userId);

	/**
	 * 增加店铺浏览量
	 */
	void increaseViews(Long id);

	/**
	 * 获取我的店铺信息
	 */
	ShopRespVO getMyShop(String token);

	/**
	 * 获取店铺统计信息（最近30天汇总）
	 */
	Map<String, Object> getShopStatistics(Long shopId);

	/**
	 * 获取我的关注列表
	 */
	Page<ShopRespVO> getMyFollows(Long userId, String keyword, Integer page, Integer pageSize);

	/**
	 * 获取我的关注统计
	 */
	Map<String, Integer> getMyFollowStats(Long userId);

	/**
	 * 更新店铺信息
	 */
	void updateShop(Long shopId, com.usdt.mall.vo.request.UpdateShopReqVO reqVO, Long userId);
}
