package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 店铺查询请求VO
 */
@Data
public class ShopQueryReqVO {
	/**
	 * 搜索关键词（店铺名称、店主姓名）
	 */
	private String keyword;

	/**
	 * 页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 10;
}
