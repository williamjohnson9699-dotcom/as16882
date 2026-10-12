package com.usdt.mall.vo.request;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

@Schema(description = "用户登录请求")
@Data
public class LoginReqVO {

	@Schema(description = "用户名（邮箱或手机号）", example = "user@example.com")
	@NotBlank(message = "用户名不能为空")
	private String username;

	@Schema(description = "密码", example = "password123")
	@NotBlank(message = "密码不能为空")
	private String password;
}
