package com.usdt.mall.vo.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Schema(description = "用户信息响应")
@Data
public class UserInfoRespVO {

	@Schema(description = "用户ID")
	private Long id;

	@Schema(description = "用户名")
	private String username;

	@Schema(description = "昵称")
	private String nickname;

	@Schema(description = "头像")
	private String avatar;

	@Schema(description = "角色")
	private String role;

	@Schema(description = "邀请码")
	private String inviteCode;

	@Schema(description = "是否已设置支付密码")
	private Boolean hasPaymentPassword;

	@Schema(description = "余额")
	private BigDecimal balance;

	@Schema(description = "创建时间")
	private LocalDateTime createTime;
}
