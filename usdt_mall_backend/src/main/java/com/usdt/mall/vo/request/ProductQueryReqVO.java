package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 商品查询请求VO
 */
@Data
public class ProductQueryReqVO {
	/**
	 * 搜索关键词（商品名称、编号）
	 */
	private String keyword;

	/**
	 * 分类筛选
	 */
	private String category;

	/**
	 * 页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 10;
}
