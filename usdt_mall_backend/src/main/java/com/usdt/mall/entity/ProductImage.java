package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 商品图片实体类
 */
@Data
@TableName("product_image")
public class ProductImage {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 商品ID
	 */
	private Long productId;

	/**
	 * 图片地址
	 */
	private String imageUrl;

	/**
	 * 排序顺序
	 */
	private Integer sortOrder;

	/**
	 * 是否主图: 0-否, 1-是
	 */
	private Integer isMain;

	/**
	 * 创建时间
	 */
	@TableField("create_time")
	private LocalDateTime createTime;
}
