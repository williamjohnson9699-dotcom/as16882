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
 * 店铺统计实体类
 */
@Data
@TableName("shop_statistics")
public class ShopStatistics {

	@TableId(type = IdType.AUTO)
	private Long id;

	/**
	 * 店铺ID
	 */
	private Long shopId;

	/**
	 * 统计日期
	 */
	private LocalDate statDate;

	/**
	 * 订单数量
	 */
	private Integer orderCount;

	/**
	 * 销售额
	 */
	private BigDecimal salesAmount;

	/**
	 * 利润
	 */
	private BigDecimal profitAmount;

	/**
	 * 利润率
	 */
	private BigDecimal profitRate;

	/**
	 * 创建时间
	 */
	@TableField("create_time")
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	@TableField("update_time")
	private LocalDateTime updateTime;
}
