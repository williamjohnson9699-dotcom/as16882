package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 系统配置实体类
 */
@Data
@TableName("system_config")
public class SystemConfig {

	@TableId(type = IdType.AUTO)
	private Long id;

	private String configKey;

	private String configValue;

	private String configDesc;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
