package com.usdt.mall.vo.request;

import lombok.Data;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;

/**
 * 添加购物车请求VO
 */
@Data
public class AddCartReqVO {

	/**
	 * 商品ID
	 */
	@NotNull(message = "商品ID不能为空")
	private Long productId;

	/**
	 * 店铺ID
	 */
	@NotNull(message = "店铺ID不能为空")
	private Long shopId;

	/**
	 * 数量
	 */
	@NotNull(message = "数量不能为空")
	@Min(value = 1, message = "数量至少为1")
	private Integer quantity;
}
