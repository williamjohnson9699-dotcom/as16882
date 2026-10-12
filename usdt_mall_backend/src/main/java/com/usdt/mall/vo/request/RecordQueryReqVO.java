package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 记录查询请求VO
 */
@Data
public class RecordQueryReqVO {

	/**
	 * 类型: null-全部, 1-充值, 2-提现
	 */
	private Integer type;

	/**
	 * 当前页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 10;
}
