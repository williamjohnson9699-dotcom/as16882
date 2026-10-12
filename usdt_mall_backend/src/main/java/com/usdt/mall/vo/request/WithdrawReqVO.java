package com.usdt.mall.vo.request;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.DecimalMin;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * 提现请求VO
 */
@Schema(description = "提现请求")
@Data
public class WithdrawReqVO {

	@Schema(description = "提现方式: USDT-TRC20, USDT-ERC20, BTC, ETH", required = true)
	@NotBlank(message = "提现方式不能为空")
	private String paymentMethod;

	@Schema(description = "提现金额", required = true)
	@NotNull(message = "提现金额不能为空")
	@DecimalMin(value = "0.01", message = "提现金额必须大于0")
	private BigDecimal amount;

	@Schema(description = "收款地址", required = true)
	@NotBlank(message = "收款地址不能为空")
	private String receivingAddress;

	@Schema(description = "支付密码", required = true)
	@NotBlank(message = "支付密码不能为空")
	private String paymentPassword;
}
