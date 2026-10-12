package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 商品实体类
 */
@Data
@TableName("product")
public class Product {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 商品名称
	 */
	private String name;

	/**
	 * 商品描述
	 */
	private String description;

	/**
	 * 商品价格
	 */
	private BigDecimal price;

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
	 * 商品主图URL
	 */
	private String mainImage;

	/**
	 * 商品图片列表（JSON格式）
	 */
	private String images;

	/**
	 * 所属分类ID
	 */
	private Long categoryId;

	/**
	 * 商品状态：0-下架，1-上架
	 */
	private Integer status;

	/**
	 * 是否热卖：0-否，1-是
	 */
	private Integer isHot;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	private LocalDateTime updateTime;
}
