package com.usdt.mall.vo.request;

import lombok.Data;

/**
 * 用户查询请求VO
 */
@Data
public class UserQueryReqVO {
	/**
	 * 搜索关键词（ID、用户名、昵称）
	 */
	private String keyword;

	/**
	 * 角色筛选
	 */
	private String role;

	/**
	 * 页码
	 */
	private Integer page = 1;

	/**
	 * 每页数量
	 */
	private Integer pageSize = 10;
}
