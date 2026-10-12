package com.usdt.mall.vo.request;

import lombok.Data;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import java.util.List;

/**
 * 代下订单请求VO
 */
@Data
public class ProxyOrderReqVO {

	/**
	 * 用户ID
	 */
	@NotNull(message = "用户ID不能为空")
	private Long userId;

	/**
	 * 收货地址ID
	 */
	@NotNull(message = "收货地址ID不能为空")
	private Long addressId;

	/**
	 * 商品列表
	 */
	@NotEmpty(message = "商品列表不能为空")
	private List<ProxyOrderProduct> products;

	/**
	 * 订单备注
	 */
	private String remark;

	/**
	 * 支付密码
	 */
	@NotNull(message = "支付密码不能为空")
	private String paymentPassword;

	@Data
	public static class ProxyOrderProduct {
		/**
		 * 商品ID
		 */
		@NotNull(message = "商品ID不能为空")
		private Long productId;

		/**
		 * 数量
		 */
		@NotNull(message = "商品数量不能为空")
		private Integer quantity;
	}
}
