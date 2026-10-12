package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * APP版本管理实体类
 */
@Data
@TableName("app_version")
public class AppVersion {

	@TableId(type = IdType.AUTO)
	private Long id;

	private String platform;

	private Integer versionCode;

	private String versionName;

	private String downloadUrl;

	private String updateDesc;

	private Integer isForceUpdate;

	private Integer status;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
