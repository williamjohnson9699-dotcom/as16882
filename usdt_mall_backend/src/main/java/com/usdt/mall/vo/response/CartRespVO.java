package com.usdt.mall.vo.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 购物车响应VO
 */
@Data
public class CartRespVO {

	private Long id;
	private Long userId;
	private Long productId;
	private String productName;
	private BigDecimal productPrice;
	private String productImage;
	private Integer quantity;
	private Integer stock;
	private Long shopId;
	private String shopName;
	private String shopLogo;
	private LocalDateTime createTime;
}
