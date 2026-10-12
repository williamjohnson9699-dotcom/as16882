package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 账户交易记录实体类
 */
@Data
@TableName("account_transaction")
public class AccountTransaction {

	@TableId(type = IdType.AUTO)
	private Long id;

	private Long userId;

	private String transactionNo;

	private Integer transactionType;

	private BigDecimal amount;

	private BigDecimal balanceBefore;

	private BigDecimal balanceAfter;

	private Long relatedOrderId;

	private String remark;

	@TableField("create_time")
	private LocalDateTime createTime;

	@TableField("update_time")
	private LocalDateTime updateTime;
}
