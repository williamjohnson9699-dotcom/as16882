package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 系统统计实体类
 */
@Data
@TableName("system_statistics")
public class SystemStatistics {

	@TableId(type = IdType.AUTO)
	private Long id;

	private LocalDate statDate;

	private Integer orderCount;

	private BigDecimal salesAmount;

	private BigDecimal costAmount;

	private BigDecimal profitAmount;

	private BigDecimal avgProfitRate;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
