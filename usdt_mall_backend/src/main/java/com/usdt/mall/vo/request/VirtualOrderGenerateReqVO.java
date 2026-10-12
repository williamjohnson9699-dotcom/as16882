package com.usdt.mall.vo.request;

import lombok.Data;

import java.util.List;

/**
 * 生成虚拟订单和资金的提交请求。六个数量都是每家店各生成这么多。
 */
@Data
public class VirtualOrderGenerateReqVO {

	private List<Long> shopIds;

	private Integer pendingShipment;

	private Integer pendingReceipt;

	private Integer completed;

	private Integer cancelled;

	private Integer rechargeCount;

	private Integer withdrawCount;
}
