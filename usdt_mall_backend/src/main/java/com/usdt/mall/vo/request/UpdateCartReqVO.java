package com.usdt.mall.vo.request;

import lombok.Data;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;

/**
 * 更新购物车请求VO
 */
@Data
public class UpdateCartReqVO {

	/**
	 * 数量
	 */
	@NotNull(message = "数量不能为空")
	@Min(value = 1, message = "数量至少为1")
	private Integer quantity;
}
