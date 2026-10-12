package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * APP版本查询请求VO
 */
@Data
public class AppVersionQueryReqVO {
	/**
	 * 平台（ANDROID/IOS）
	 */
	private String platform;

	/**
	 * 页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 10;
}
