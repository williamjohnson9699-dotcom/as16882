package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 商品搜索请求VO
 */
@Data
public class ProductSearchReqVO {

	/**
	 * 搜索关键词
	 */
	private String keyword;

	/**
	 * 分类ID
	 */
	private Long categoryId;

	/**
	 * 店铺ID
	 */
	private Long shopId;

	/**
	 * 是否热卖：0-否，1-是
	 */
	private Integer isHot;

	/**
	 * 当前页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 20;
}
