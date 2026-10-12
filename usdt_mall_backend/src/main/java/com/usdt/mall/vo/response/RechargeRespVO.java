package com.usdt.mall.vo.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 充值记录响应VO
 */
@Schema(description = "充值记录响应")
@Data
public class RechargeRespVO {

	@Schema(description = "记录ID")
	private Long id;

	@Schema(description = "订单号")
	private String orderNo;

	@Schema(description = "充值方式")
	private String paymentMethod;

	@Schema(description = "充值金额")
	private BigDecimal amount;

	@Schema(description = "状态: 0-待审核, 1-已通过, 2-已拒绝")
	private Integer status;

	@Schema(description = "备注")
	private String remark;

	@Schema(description = "创建时间")
	private LocalDateTime createTime;
}
