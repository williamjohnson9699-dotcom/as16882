package com.usdt.mall.vo.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 修改用户角色请求VO
 */
@Data
public class UpdateUserRoleReqVO {
	/**
	 * 用户ID
	 */
	@NotNull(message = "用户ID不能为空")
	private Long userId;

	/**
	 * 新角色
	 */
	@NotBlank(message = "角色不能为空")
	private String role;
}
