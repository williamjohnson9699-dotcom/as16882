package com.usdt.mall.vo.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 订单响应VO
 */
@Data
public class OrderRespVO {

	/**
	 * 订单ID
	 */
	private Long id;

	/**
	 * 订单号
	 */
	private String orderNo;

	/**
	 * 用户ID
	 */
	private Long userId;

	/**
	 * 店铺ID
	 */
	private Long shopId;

	/**
	 * 店铺名称
	 */
	private String shopName;

	/**
	 * 地址ID
	 */
	private Long addressId;

	/**
	 * 收货人姓名
	 */
	private String receiverName;

	/**
	 * 收货人电话
	 */
	private String receiverPhone;

	/**
	 * 收货地址
	 */
	private String receiverAddress;

	/**
	 * 订单总金额
	 */
	private BigDecimal totalAmount;

	/**
	 * 订单类型
	 */
	private Integer orderType;

	/**
	 * 代理ID
	 */
	private Long agentId;

	/**
	 * 订单状态
	 */
	private Integer status;

	/**
	 * 是否到货
	 */
	private Boolean isArrived;

	/**
	 * 订单备注
	 */
	private String remark;

	/**
	 * 卖家支付状态
	 */
	private Boolean sellerPaid;

	/**
	 * 平台回馈状态
	 */
	private Boolean platformRebate;

	/**
	 * 利润率
	 */
	private BigDecimal profitRate;

	/**
	 * 成本
	 */
	private BigDecimal cost;

	/**
	 * 利润
	 */
	private BigDecimal profit;

	/**
	 * 卖家支付时间
	 */
	private LocalDateTime sellerPaidTime;

	/**
	 * 平台回馈时间
	 */
	private LocalDateTime platformRebateTime;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	private LocalDateTime updateTime;

	/**
	 * 订单明细列表
	 */
	private List<OrderItemRespVO> items;

	/**
	 * 买家用户名
	 */
	private String buyerUsername;

	/**
	 * 买家昵称
	 */
	private String buyerNickname;

	/**
	 * 卖家用户名
	 */
	private String shopUsername;

	/**
	 * 卖家昵称
	 */
	private String shopNickname;

	/**
	 * 订单信息列表（状态变化、物流更新等）
	 */
	private List<OrderInfoRespVO> orderInfos;
}
