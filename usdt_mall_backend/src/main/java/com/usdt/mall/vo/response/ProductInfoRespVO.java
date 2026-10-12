package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 商品信息响应VO
 */
@Data
public class ProductInfoRespVO {
	/**
	 * 商品ID
	 */
	private Long id;

	/**
	 * 商品名称
	 */
	private String name;

	/**
	 * 商品分类
	 */
	private String category;

	/**
	 * 商品价格
	 */
	private String price;

	/**
	 * 库存数量
	 */
	private Integer stock;

	/**
	 * 销量
	 */
	private Integer sales;

	/**
	 * 浏览量
	 */
	private Integer views;

	/**
	 * 状态: active/inactive
	 */
	private String status;

	/**
	 * 商品主图
	 */
	private String mainImage;

	/**
	 * 商品图片列表
	 */
	private List<String> images;

	/**
	 * 商品说明
	 */
	private String description;

	/**
	 * 上架日期
	 */
	private LocalDateTime createTime;
}
