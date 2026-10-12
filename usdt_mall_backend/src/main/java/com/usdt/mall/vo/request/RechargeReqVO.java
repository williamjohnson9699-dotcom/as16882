package com.usdt.mall.vo.request;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.DecimalMin;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * 充值请求VO
 */
@Schema(description = "充值请求")
@Data
public class RechargeReqVO {

	@Schema(description = "充值方式: USDT-TRC20, USDT-ERC20, BTC, ETH", required = true)
	@NotBlank(message = "充值方式不能为空")
	private String paymentMethod;

	@Schema(description = "充值金额", required = true)
	@NotNull(message = "充值金额不能为空")
	@DecimalMin(value = "0.01", message = "充值金额必须大于0")
	private BigDecimal amount;

	@Schema(description = "凭证图片URL")
	private String proofImage;

	@Schema(description = "收款地址", required = true)
	@NotBlank(message = "收款地址不能为空")
	@javax.validation.constraints.Size(min = 1, max = 200, message = "收款地址长度必须在1-200位之间")
	private String receivingAddress;

	@Schema(description = "备注")
	private String remark;
}
