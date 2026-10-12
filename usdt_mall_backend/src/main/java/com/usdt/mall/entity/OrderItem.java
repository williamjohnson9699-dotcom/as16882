package com.usdt.mall.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单明细实体类
 */
@Data
@TableName("order_item")
public class OrderItem {

	@TableId(type = IdType.AUTO)
	private Long id;

	private Long orderId;

	private Long productId;

	private String productName;

	private String productImage;

	private BigDecimal price;

	private Integer quantity;

	private BigDecimal subtotal;

	@TableField("create_time")
	private LocalDateTime createTime;
}
