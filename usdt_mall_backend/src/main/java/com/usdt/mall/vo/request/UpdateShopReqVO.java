package com.usdt.mall.vo.request;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 更新店铺信息请求VO
 */
@Data
public class UpdateShopReqVO {

	/**
	 * 店铺名称
	 */
	private String name;

	/**
	 * 店铺图标URL
	 */
	private String logo;

	/**
	 * 订单数量（最大100000）
	 */
	private Integer orderCount;

	/**
	 * 销售额（最大40000000）
	 */
	private BigDecimal salesAmount;

	/**
	 * 关注数量（最大500）
	 */
	private Integer followCount;

	/**
	 * 店铺等级（最大10级）
	 */
	private Integer level;

	/**
	 * 店铺评分（最大5.0）
	 */
	private Double rating;

	/**
	 * 浏览量（最大500000）
	 */
	private Integer views;

	/**
	 * 信誉分（最大100分）
	 */
	private Integer creditScore;
}
