package com.usdt.mall.vo.response;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 订单明细响应VO
 */
@Data
public class OrderItemRespVO {

	/**
	 * 订单明细ID
	 */
	private Long id;

	/**
	 * 订单ID
	 */
	private Long orderId;

	/**
	 * 商品ID
	 */
	private Long productId;

	/**
	 * 商品名称
	 */
	private String productName;

	/**
	 * 商品图片
	 */
	private String productImage;

	/**
	 * 商品价格
	 */
	private BigDecimal price;

	/**
	 * 购买数量
	 */
	private Integer quantity;

	/**
	 * 小计
	 */
	private BigDecimal subtotal;
}
