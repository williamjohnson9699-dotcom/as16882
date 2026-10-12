package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 充值/提现记录实体类
 */
@Data
@TableName("recharge_withdraw_record")
public class RechargeWithdrawRecord {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 订单号
	 */
	private String orderNo;

	/**
	 * 类型: 1-充值, 2-提现
	 */
	private Integer type;

	/**
	 * 充值方式: USDT, BTC, ETH
	 */
	private String paymentMethod;

	/**
	 * 金额
	 */
	private BigDecimal amount;

	/**
	 * 状态: 0-待审核, 1-已通过, 2-已拒绝
	 */
	private Integer status;

	/**
	 * 凭证图片URL
	 */
	private String proofImage;

	/**
	 * 收款地址
	 */
	private String receivingAddress;

	/**
	 * 审核人ID
	 */
	private Long auditorId;

	/**
	 * 审核时间
	 */
	private LocalDateTime auditTime;

	/**
	 * 备注
	 */
	private String remark;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	private LocalDateTime updateTime;

	/**
	 * 是否已读: 0-未读, 1-已读
	 */
	private Integer isRead;

	/**
	 * 关联订单号（用于买家结算、卖家支付、平台回馈）
	 */
	private String relatedOrderNo;
}
