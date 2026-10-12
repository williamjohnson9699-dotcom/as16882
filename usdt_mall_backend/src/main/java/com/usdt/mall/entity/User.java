package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("user")
public class User {

	@TableId(type = IdType.AUTO)
	private Long id;

	private String username;

	private String nickname;

	private String password;

	private String paymentPassword;

	private String avatar;

	private String role;

	private String inviteCode;

	private BigDecimal balance;

	private Integer status;

	private Integer onlineStatus;

	private LocalDateTime createTime;

	private LocalDateTime updateTime;
}
