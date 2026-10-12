package com.usdt.mall.vo.response;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 订单信息响应VO
 */
@Data
public class OrderInfoRespVO {

	/**
	 * 信息ID
	 */
	private Long id;

	/**
	 * 订单ID
	 */
	private Long orderId;

	/**
	 * 信息类型：STATUS_CHANGE-状态变化, LOGISTICS_UPDATE-物流更新
	 */
	private String infoType;

	/**
	 * 信息内容
	 */
	private String content;

	/**
	 * 操作人ID
	 */
	private Long operatorId;

	/**
	 * 操作人名称
	 */
	private String operatorName;

	/**
	 * 创建时间
	 */
	private LocalDateTime createTime;
}
