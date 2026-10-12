package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 轮播商品实体类
 */
@Data
@TableName("carousel_product")
public class CarouselProduct {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 商品ID
	 */
	private Long productId;

	/**
	 * 排序顺序
	 */
	private Integer sortOrder;

	/**
	 * 创建时间
	 */
	@TableField("create_time")
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	@TableField("update_time")
	private LocalDateTime updateTime;
}
