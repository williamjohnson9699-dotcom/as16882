package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 店铺搜索请求VO
 */
@Data
public class ShopSearchReqVO {

	/**
	 * 搜索关键词
	 */
	private String keyword;

	/**
	 * 当前页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 12;
}
