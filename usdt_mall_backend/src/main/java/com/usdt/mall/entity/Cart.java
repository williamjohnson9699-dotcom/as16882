package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 购物车实体类
 */
@Data
@TableName("cart")
public class Cart {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 商品ID
	 */
	private Long productId;

	/**
	 * 店铺ID
	 */
	private Long shopId;

	/**
	 * 数量
	 */
	private Integer quantity;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	private LocalDateTime updateTime;
}
