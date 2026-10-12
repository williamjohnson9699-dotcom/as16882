package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单实体类
 */
@Data
@TableName("`order`")
public class Order {

	@TableId(type = IdType.AUTO)
	private Long id;

	private String orderNo;

	private Long userId;

	private Long shopId;

	private Long addressId;

	private BigDecimal totalAmount;

	private Integer orderType;

	private Long agentId;

	private Integer status;

	private Boolean isArrived;

	private Boolean buyerFinalRead;

	private Boolean sellerFinalRead;

	private Boolean serviceFinalRead;

	private Boolean sellerPaid;

	private Boolean platformRebate;

	private BigDecimal profitRate;

	private BigDecimal cost;

	private BigDecimal profit;

	private LocalDateTime sellerPaidTime;

	private LocalDateTime platformRebateTime;

	private String remark;

	private String cancelReason;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
