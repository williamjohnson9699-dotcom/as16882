package com.usdt.mall.vo.request;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Schema(description = "用户注册请求")
@Data
public class RegisterReqVO {

	@Schema(description = "用户名（邮箱或手机号）", example = "user@example.com")
	@NotBlank(message = "用户名不能为空")
	@Size(min = 3, max = 100, message = "用户名长度必须在3-100个字符之间")
	private String username;

	@Schema(description = "昵称", example = "张三")
	@NotBlank(message = "昵称不能为空")
	@Size(max = 50, message = "昵称长度不能超过50个字符")
	private String nickname;

	@Schema(description = "密码", example = "password123")
	@NotBlank(message = "密码不能为空")
	@Size(min = 6, max = 20, message = "密码长度必须在6-20个字符之间")
	private String password;
}
