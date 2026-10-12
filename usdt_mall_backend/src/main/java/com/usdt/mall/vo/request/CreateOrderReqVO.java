package com.usdt.mall.vo.request;

import lombok.Data;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import java.util.List;

/**
 * 创建订单请求VO
 */
@Data
public class CreateOrderReqVO {

	/**
	 * 购物车ID列表
	 */
	@NotEmpty(message = "购物车ID列表不能为空")
	private List<Long> cartIds;

	/**
	 * 收货地址ID
	 */
	@NotNull(message = "收货地址ID不能为空")
	private Long addressId;

	/**
	 * 支付密码
	 */
	@NotEmpty(message = "支付密码不能为空")
	private String paymentPassword;

	/**
	 * 订单备注
	 */
	private String remark;
}
