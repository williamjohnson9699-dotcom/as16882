package com.usdt.mall.vo.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 记录信息响应VO
 */
@Data
public class RecordInfoRespVO {

	/**
	 * 记录ID
	 */
	private Long id;

	/**
	 * 订单号
	 */
	private String orderNo;

	/**
	 * 类型: 1-充值, 2-提现
	 */
	private Integer type;

	/**
	 * 充值方式
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
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 用户名
	 */
	private String username;

	/**
	 * 用户昵称
	 */
	private String nickname;

	/**
	 * 充值凭证图片
	 */
	private String proofImage;

	/**
	 * 收款地址
	 */
	private String receivingAddress;

	/**
	 * 关联订单号（用于卖家支付、平台回馈、买家结算）
	 */
	private String relatedOrderNo;

	/**
	 * 是否已读: 0-未读, 1-已读
	 */
	private Integer isRead;
}
