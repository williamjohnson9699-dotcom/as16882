package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 订单信息实体类
 */
@Data
@TableName("order_info")
public class OrderInfo {

	@TableId(type = IdType.AUTO)
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
