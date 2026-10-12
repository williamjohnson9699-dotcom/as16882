package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 利润率配置实体类
 */
@Data
@TableName("profit_rate_config")
public class ProfitRateConfig {

	@TableId(type = IdType.AUTO)
	private Long id;

	private Integer profitRate;

	private LocalDate effectiveDate;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
